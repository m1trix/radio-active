require 'radioactive/exception'
require 'radioactive/database'
require 'radioactive/video'

module Radioactive
  class SongsQueue
    module SQL
      TABLE = 'QUEUE'

      COLUMN_CYCLE = 'CYCLE'
      COLUMN_SONG = Video::SQL.column(:id)

      module_function

      def table
        <<-SQL
          CREATE TABLE IF NOT EXISTS #{TABLE}
          (
            `#{COLUMN_CYCLE}` BIGINT PRIMARY KEY,
            #{Video::SQL.type(:id)}
          )
        SQL
      end

      def insert(cycle, song)
        <<-SQL
          INSERT INTO #{TABLE} (#{COLUMN_CYCLE}, #{COLUMN_SONG})
            VALUES (#{cycle}, '#{song}')
        SQL
      end

      def load(cycle)
        <<-SQL
          SELECT #{COLUMN_SONG}
            FROM #{TABLE}
            WHERE #{COLUMN_CYCLE} >= #{cycle}
            ORDER BY #{COLUMN_CYCLE} ASC
        SQL
      end
    end
  end
end

module Radioactive
  class SongsQueue
    def initialize(cycle)
      @queue = []
      @cycle = cycle

      @db = Database.new
      initialize_table
      load_queue
    end

    def all
      @queue.dup
    end

    def top
      @queue.first
    end

    def push(song)
      @db.execute(SQL.insert(@cycle.to_i + @queue.size, song)) do
        error :duplicate_key do
          raise Error, 'A song was pushed to the queue in this cycle'
        end

        error do
          raise Error, 'Failed to push to the queue'
        end
      end
      @queue.push(song)
    end

    private

    def load_queue
      @queue = @db.select(SQL.load(@cycle), []) do |row|
        handle do |queue|
          queue.push(row[SQL::COLUMN_SONG])
        end
      end
    end

    def initialize_table
      @db.execute(SQL.table) do
        error do
          raise Error, 'Failed to initialize playlist'
        end
      end
    end
  end
end