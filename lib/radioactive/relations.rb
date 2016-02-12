require_relative 'database'
require_relative 'library'
require_relative 'youtube'

module Radioactive
  class Relations
    module SQL
      TABLE = 'RELATIONS'
      ENGINE = 'ENGINE=InnoDb'
      COLUMN_ID = 'ID'
      COLUMN_RELATED_ID = 'RELATED_ID'

      module_function

      def table_definition
        <<-SQL
          CREATE TABLE IF NOT EXISTS #{TABLE} (
            #{COLUMN_ID} VARCHAR(128),
            #{COLUMN_RELATED_ID} VARCHAR(128),
            PRIMARY KEY(#{COLUMN_ID}, #{COLUMN_RELATED_ID})
          ) #{ENGINE}
        SQL
      end

      def insert(video_id, related_videos)
        values = related_videos.map do |related_video|
          "('#{video_id}', '#{related_video.id}')"
        end

        <<-SQL
          INSERT INTO #{TABLE} (#{COLUMN_ID}, #{COLUMN_RELATED_ID})
            VALUES #{values.join(',')}
        SQL
      end

      def delete(video_id)
        <<-SQL
          DELETE
            FROM #{TABLE}
            WHERE #{COLUMN_ID}='#{video_id}'
        SQL
      end

      def list(video_id)
        <<-SQL
          SELECT #{Library::SQL.columns}
            FROM #{TABLE}
            INNER JOIN #{Library::SQL::TABLE}
              ON #{TABLE}.#{COLUMN_RELATED_ID}=#{Library::SQL.full_column :id}
            WHERE #{TABLE}.#{COLUMN_ID} = '#{video_id}'
        SQL
      end
    end
  end
end

module Radioactive
  class Relations
    Database.initialize_table(self)

    def initialize
      @db = Database.new
      @library = Library.new
    end

    def list(video)
      @db.select(SQL.list(video.id), []) do |row|
        handle do |list|
          list.push(Video::SQL.from_row(row))
        end

        error do
          raise Error, "Failed to load related videos for video #{video}"
        end
      end
    end

    def insert(video, related_videos)
      @library.add(video)
      @library.add_all(related_videos)
      @db.transaction do
        execute_insert(video, related_videos)
      end
    end

    def delete(video)
      @db.execute(SQL.delete(video.id)) do
        error do
          raise Error, 'Failed to delete related videos'
        end
      end
    end

    private

    def execute_insert(video, related_videos)
      @db.execute(SQL.insert(video, related_videos)) do
        error do
          raise Error, 'Failed to store related videos'
        end
      end
    end
  end
end