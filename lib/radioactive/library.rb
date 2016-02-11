require 'radioactive/database'
require 'radioactive/exception'
require 'radioactive/video'

module Radioactive
  class Library
    module SQL
      TABLE = 'LIBRARY'

      module_function

      def table
        <<-SQL
          CREATE TABLE IF NOT EXISTS #{TABLE}
          (
            #{Video::SQL.joined_types},
            PRIMARY KEY (#{Video::SQL.column(:song)})
          )
        SQL
      end

      def find_by_id(id)
        <<-SQL
          SELECT #{Video::SQL.joined_columns}
            FROM #{TABLE}
            WHERE #{Video::SQL.column(:id)}='#{id}'
        SQL
      end

      def find_by_song(song)
        <<-SQL
          SELECT #{Video::SQL.joined_columns}
            FROM #{TABLE}
            WHERE #{Video::SQL.column(:song)}='#{song.to_s}'
        SQL
      end

      def insert(video)
        <<-SQL
          INSERT INTO #{TABLE}
          (#{Video::SQL.joined_columns})
            VALUES #{Video::SQL.values(video)}
        SQL
      end

      def insert_many(videos)
        values = videos.map do |video|
          Video::SQL.values(video)
        end

        <<-SQL
          INSERT INTO #{TABLE}
          (#{Video::SQL.joined_columns})
            VALUES #{values.join(',')}
        SQL
      end

      def delete(song)
        <<-SQL
          DELETE FROM #{TABLE}
            WHERE #{Video::SQL.column(:song)}='#{song}'
        SQL
      end

      def clear
        "DELETE FROM #{TABLE}"
      end
    end
  end
end

module Radioactive
  class Library
    def initialize
      @db = Database.new
      initialize_table
    end

    def clear
      @db.execute(SQL.clear) do
        error do
          raise Error, 'Failed to clear Library'
        end
      end
    end

    def add_all(videos)
      videos.each do |video|
        add(video)
      end
    end

    def add(video)
      @db.execute(SQL.insert(video)) do
        error :duplicate_key do
          cancel
        end

        error do
          raise Error, "Failed to insert video '#{video}'"
        end
      end
    end

    def find(song: nil, id: nil)
      sql = song.nil? ? SQL.find_by_id(id) : SQL.find_by_song(song)
      @db.select(sql) do |row|
        handle do
          Video::SQL.get(row)
        end

        error do
          raise Error, "Failed to find video of song '#{song}'"
        end
      end
    end

    private

    def initialize_table
      @db.execute(SQL.table) do
        error do
          raise Error, 'Failed to initialize Library'
        end
      end
    end
  end
end