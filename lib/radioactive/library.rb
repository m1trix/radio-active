require_relative 'database'
require_relative 'error'
require_relative 'video'

module Radioactive
  class Library
    module SQL
      TABLE = 'LIBRARY'

      module_function

      def table_definition
        <<-SQL
          CREATE TABLE IF NOT EXISTS #{TABLE}
          (
            #{Video::SQL.joined_definitions},
            PRIMARY KEY (#{Video::SQL.column(:id)})
          )
        SQL
      end

      def columns
        Video::SQL.joined_columns(TABLE)
      end

      def full_column(name)
        "#{TABLE}.#{Video::SQL.column(name)}"
      end

      def find(id)
        <<-SQL
          SELECT #{Video::SQL.joined_columns}
            FROM #{TABLE}
            WHERE #{Video::SQL.column(:id)}='#{id}'
        SQL
      end

      def add(video)
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
    end
  end
end

module Radioactive
  class Library
    Database.initialize_table(self)

    def initialize
      @db = Database.new
    end

    def add_all(videos)
      videos.each do |video|
        add(video)
      end
    end

    def add(video)
      @db.execute(SQL.add(video)) do
        error :duplicate_key do
          cancel
        end

        error do
          raise Error, "Failed to insert video for '#{video.id}'"
        end
      end
    end

    def find(id)
      @db.select(SQL.find(id)) do |row|
        handle do
          Video::SQL.from_row(row)
        end

        error do
          raise Error, "Failed to find video '#{id}'"
        end
      end
    end

    def delete(id)
      @db.execute(SQL.delete(id)) do |row|
        error do
          raise Error, "Failed to delete video '#{id}'"
        end
      end
    end

    def update(video)
      @db.transaction do
        delete(video.id)
        add(video)
      end
    end
  end
end
