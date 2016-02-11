require 'radioactive/database'
require 'radioactive/song'

module Radioactive
  class RelatedSongs
    module SQL
      TABLE = 'RELATED'
      COLUMN_SONG = 'SONG'
      COLUMN_LINK = 'LINK'

      module_function

      def table
        <<-SQL
          CREATE TABLE IF NOT EXISTS #{TABLE} (
            #{COLUMN_SONG} VARCHAR(256),
            #{COLUMN_LINK} VARCHAR(256),
            PRIMARY KEY(#{COLUMN_SONG}, #{COLUMN_LINK})
          )
        SQL
      end

      def insert(song, related_songs)
        values = related_songs.map do |related_song|
          "('#{song}', '#{related_song}')"
        end

        <<-SQL
          INSERT INTO #{TABLE}
          (#{COLUMN_SONG}, #{COLUMN_LINK})
            VALUES #{values.join(',')}
        SQL
      end

      def delete(song)
        <<-SQL
          DELETE
            FROM #{TABLE}
            WHERE #{COLUMN_SONG}='#{song}'
        SQL
      end

      def list(song)
        <<-SQL
          SELECT #{COLUMN_LINK}
            FROM #{TABLE}
            WHERE #{COLUMN_SONG}='#{song}'
        SQL
      end
    end
  end
end

module Radioactive
  class RelatedSongs
    def initialize
      @db = Database.new
      @db.execute(SQL.table) do
        error do
          raise Error, 'Failed to initialize related videos'
        end
      end
    end

    def list(song)
      @db.select(SQL.list(song), []) do |row|
        handle do |result|
          result.push(Song.new(row[SQL::COLUMN_LINK]))
        end

        error do
          raise Error, 'Failed to read related songs'
        end
      end
    end

    def insert(song, related_songs)
      @db.transaction do
        @db.execute(SQL.insert(song, related_songs)) do
          error do
            raise Error, 'Failed to store related songs'
          end
        end
      end
    end

    def delete(song)
      @db.execute(SQL.delete(song)) do
        error do
          raise Error, 'Failed to delete related songs'
        end
      end
    end
  end
end