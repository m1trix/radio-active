require_relative 'error'
require_relative 'database'
require_relative 'video'

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
      COLUMN_ID = Video::SQL.column(:id)

      module_function

      def table_definition
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

      def vote(cycle, user, video_id)
        <<-SQL
          INSERT INTO #{TABLE}
          (#{COLUMN_CYCLE}, #{COLUMN_USER}, #{COLUMN_ID})
            VALUES (#{cycle.to_i}, '#{user}', '#{video_id}')
        SQL
      end

      def load(cycle)
        <<-SQL
          SELECT #{COLUMN_ID}
            FROM #{TABLE}
            WHERE #{COLUMN_CYCLE}=#{cycle.to_i}
        SQL
      end
    end
  end
end

module Radioactive
  class VotingSystem
    Database.initialize_table(self)

    def initialize
      @db = Database.new
    end

    def vote(cycle, user, video_id)
      @db.execute(SQL.vote(cycle, user, video_id)) do
        error :duplicate_key do
          raise VotingError, "User '#{user}' has already voted"
        end

        error do
          raise Error, 'Voting failed'
        end
      end
    end

    def winner(cycle)
      sorted = load_votes(cycle).each_pair.sort_by do |_, votes|
        votes
      end

      candidates = sorted.select do |_, votes|
        votes == sorted.last[1]
      end

      select_winner(candidates)
    end

    private

    def select_winner(candidates)
      return nil if candidates.empty?
      candidates.sample.first
    end

    def load_votes(cycle)
      @votes = @db.select(SQL.load(cycle), {}) do |row|
        handle do |votes|
          video_id = row[SQL::COLUMN_ID]
          votes[video_id] = votes.fetch(video_id, 0) + 1
          votes
        end

        error do
          raise Error, 'Failed to load persisted votes'
        end
      end
    end
  end
end