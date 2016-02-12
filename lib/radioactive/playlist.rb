require_relative 'error'
require_relative 'database'
require_relative 'library'
require_relative 'video'

module Radioactive
  class Playlist
    module SQL
      TABLE = 'PLAYLIST'

      COLUMN_CYCLE = 'CYCLE'
      COLUMN_ID = Video::SQL.column(:id)

      module_function

      def table_definition
        <<-SQL
          CREATE TABLE #{TABLE}
          (
            `#{COLUMN_CYCLE}` BIGINT PRIMARY KEY,
            #{Video::SQL.type(:id)}
          )
        SQL
      end

      def push(position, video_id)
        <<-SQL
          INSERT INTO #{TABLE} (#{COLUMN_CYCLE}, #{COLUMN_ID})
            VALUES (#{position}, '#{video_id}')
        SQL
      end

      def last_cycle
        "SELECT MAX(#{COLUMN_CYCLE}) as SIZE FROM #{TABLE}"
      end

      def list(cycle, count)
        <<-SQL
          SELECT #{Library::SQL.columns}
            FROM #{TABLE}
            INNER JOIN #{Library::SQL::TABLE}
              ON #{TABLE}.#{COLUMN_ID}=#{Library::SQL.full_column :id}
            WHERE #{COLUMN_CYCLE} >= #{cycle.to_i}
            ORDER BY #{COLUMN_CYCLE} ASC
            LIMIT #{count}
        SQL
      end
    end
  end
end

module Radioactive
  class Playlist
    Database.initialize_table(self)

    def initialize
      @library = Library.new
      @db = Database.new
    end

    def list(cycle, count)
      select(SQL.list(cycle, count), []) do |row, all|
        all.push(Video::SQL.from_row(row))
      end
    end

    def push(video)
      @library.add(video)
      @db.execute(SQL.push(last_cycle + 1, video.id)) do
        error :duplicate_key do
          raise Error, 'Cannot push a video over an existing cycle'
        end

        error do
          raise Error, 'Failed to push to the playlist'
        end
      end
    end

    protected

    def last_cycle
      @db.select(SQL.last_cycle) do |row|
        handle do
          row['SIZE']
        end

        error do
          raise Error, 'Failed to read playlist size'
        end
      end or -1
    end

    def select(sql, result = nil, &block)
      @db.select(sql, result) do |row|
        handle do |result|
          block[row, result]
        end

        error do
          raise Error, "Failed to load playlist"
        end
      end
    end
  end
end
