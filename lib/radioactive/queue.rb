require 'radioactive/exception'
require 'radioactive/database'
require 'radioactive/song'

module Radioactive
  class SongsQueue
    module SQL
      TABLE = 'QUEUE'

      COLUMN_CYCLE = 'CYCLE'
      COLUMN_SONG = 'SONG'

      module_function

      def table
        <<-SQL
          CREATE TABLE IF NOT EXISTS #{TABLE}
          (
            `#{COLUMN_CYCLE}` DATETIME(3) PRIMARY KEY,
            `#{COLUMN_SONG}` VARCHAR(256)
          )
        SQL
      end

      def insert
        <<-SQL
          INSERT INTO #{TABLE} (#{COLUMN_CYCLE}, #{COLUMN_SONG})
            VALUES %{values}
        SQL
      end

      def load
        <<-SQL
          SELECT #{COLUMN_SONG}
            FROM #{TABLE}
            WHERE #{COLUMN_CYCLE} >= '%{cycle}'
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
      assert_song(song)
      sql = SQL.insert % { values: "('#{@cycle.to_s}','#{song.to_s}')" }
      @db.execute(sql) do
        error :duplicate_key do
          raise Error, 'A song was pushed to the queue in this cycle'
        end

        error do
          raise Error, 'Failed to push to the queue'
        end
      end
      @queue.push song
    end

    private

    def load_queue
      @queue = @db.select(SQL.load % { cycle: @cycle } , []) do |row|
        handle do |queue|
          queue.push(Song.new(row[SQL::COLUMN_SONG]))
        end
      end
    end

    def assert_song(song)
      unless song.is_a?(Radioactive::Song)
        raise Error, 'Only songs can be added to the queue'
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