require 'radioactive/exception'
require 'radioactive/database'
require 'radioactive/song'

module Radioactive
  class VotingSystem
    module SQL
      TABLE = 'VOTES'
      COLUMN_CYCLE = 'CYCLE'
      COLUMN_USER = 'USERNAME'
      COLUMN_SONG = 'SONG'

      module_function

      def table
        <<-SQL
          CREATE TABLE IF NOT EXISTS #{TABLE}
          (
            #{COLUMN_CYCLE} DATETIME,
            #{COLUMN_USER} VARCHAR(32),
            #{COLUMN_SONG} VARCHAR(256),
            PRIMARY KEY (#{COLUMN_CYCLE}, #{COLUMN_USER})
          )
        SQL
      end

      def vote
        <<-SQL
          INSERT INTO #{TABLE}
          (#{COLUMN_CYCLE}, #{COLUMN_USER}, #{COLUMN_SONG})
            VALUES ('%{cycle}', '%{user}', '%{song}')
        SQL
      end

      def load
        <<-SQL
          SELECT #{COLUMN_SONG}
            FROM #{TABLE}
            WHERE #{COLUMN_CYCLE}='%{cycle}'
        SQL
      end
    end
  end
end

module Radioactive
  class VotingSystem
    def initialize(cycle)
      @votes = {}
      @cycle = cycle

      @db = Database.new
      initialize_tables
      load_votes
    end

    def vote(user, song)
      sql = SQL.vote % {
        cycle: @cycle, user: user, song: song.to_s
      }

      @db.execute(sql) do
        error :duplicate_key do
          raise Error, "User '#{user}' has already voted"
        end

        error do
          raise Error, 'Voting failed'
        end
      end
      @votes[song] = votes(song) + 1
    end

    def votes(song)
      @votes.fetch(song, 0)
    end

    def winner
      sorted = @votes.each_pair.sort_by do |song, votes|
        votes
      end

      candidates = sorted.select do |_, votes|
        votes == sorted.last[1]
      end

      candidates.sample.first
    end

    private

    def load_votes
      @votes = @db.select(SQL.load % { cycle: @cycle }, {}) do |row|
        handle do |votes|
          song = Song.new(row[SQL::COLUMN_SONG])
          votes[song] = votes.fetch(song, 0) + 1
          votes
        end

        error do
          raise Error, 'Failed to load persisted votes'
        end
      end
    end

    def initialize_tables
      @db.execute(SQL.table) do
        error do
          raise Error, 'Failed to initialize voting system'
        end
      end
    end
  end
end