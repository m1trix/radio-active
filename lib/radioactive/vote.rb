require 'radioactive/exception'
require 'radioactive/database'
require 'radioactive/video'

module Radioactive
  class VotingError < Error
  end
end

module Radioactive
  class VotingSystem
    module SQL
      TABLE = 'VOTES'
      COLUMN_CYCLE = 'CYCLE'
      COLUMN_USER = 'USERNAME'
      COLUMN_SONG = Video::SQL.column(:id)

      module_function

      def table
        <<-SQL
          CREATE TABLE IF NOT EXISTS #{TABLE}
          (
            #{COLUMN_CYCLE} BIGINT,
            #{COLUMN_USER} VARCHAR(32),
            #{Video::SQL::type(:id)},
            PRIMARY KEY (#{COLUMN_CYCLE}, #{COLUMN_USER})
          )
        SQL
      end

      def vote(cycle, user, song)
        <<-SQL
          INSERT INTO #{TABLE}
          (#{COLUMN_CYCLE}, #{COLUMN_USER}, #{COLUMN_SONG})
            VALUES (#{cycle}, '#{user}', '#{song}')
        SQL
      end

      def load(cycle)
        <<-SQL
          SELECT #{COLUMN_SONG}
            FROM #{TABLE}
            WHERE #{COLUMN_CYCLE}=#{cycle}
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
      @db.execute(SQL.table) do
        error do
          raise Error, 'Failed to initialize voting system'
        end
      end
      load_votes
    end

    def vote(user, song)
      @db.execute(SQL.vote(@cycle, user, song)) do
        error :duplicate_key do
          raise VotingError, "User '#{user}' has already voted"
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
      @votes = @db.select(SQL.load(@cycle), {}) do |row|
        handle do |votes|
          song = row[SQL::COLUMN_SONG]
          votes[song] = votes.fetch(song, 0) + 1
          votes
        end

        error do
          raise Error, 'Failed to load persisted votes'
        end
      end
    end
  end
end