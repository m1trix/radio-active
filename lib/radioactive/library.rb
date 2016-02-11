require 'radioactive/database'
require 'radioactive/exception'
require 'radioactive/video'
require 'radioactive/youtube'

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
            PRIMARY KEY (#{Video::SQL.column(:id)})
          )
        SQL
      end

      def find(id)
        <<-SQL
          SELECT #{Video::SQL.joined_columns}
            FROM #{TABLE}
            WHERE #{Video::SQL.column(:id)}='#{id}'
        SQL
      end

      def insert(video)
        <<-SQL
          INSERT INTO #{TABLE}
          (#{Video::SQL.joined_columns})
            VALUES #{Video::SQL.values(video)}
        SQL
      end

      def delete(id)
        <<-SQL
          DELETE FROM #{TABLE}
            WHERE #{Video::SQL.column(:id)}='#{id}'
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
          raise Error, "Failed to insert video for '#{video.id}'"
        end
      end
    end

    def find(id)
      video = find_in_db(id)

      if video.nil? and id
        video = find_in_youtube(id)
        add(video) if video
      end

      video
    end

    private

    def find_in_youtube(id)
      YouTube.proxy.find(id)
    end

    def find_in_db(id)
      @db.select(SQL.find(id)) do |row|
        handle do
          Video::SQL.get(row)
        end

        error do
          raise Error, "Failed to find video '#{id}'"
        end
      end
    end

    def initialize_table
      @db.execute(SQL.table) do
        error do
          raise Error, 'Failed to initialize Library'
        end
      end
    end
  end
end