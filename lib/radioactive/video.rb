require 'radioactive/song'

module Radioactive
  class Video
    module SQL
      COLUMNS = {
        song: 'VARCHAR(256)',
        id: 'VARCHAR(32)',
        length: 'INTEGER',
        thumbnail: 'VARCHAR(128)'
      }

      module_function

      def values(video)
        "('%s', '%s', %d, '%s')" % [
          video.song,
          video.id,
          video.length,
          video.thumbnail
        ]
      end

      def get(row)
        Video.new(
          song: Song.new(row[column :song]),
          id: row[column :id],
          thumbnail: row[column :thumbnail],
          length: row[column :length]
        )
      end

      def column(name)
        name.to_s.upcase
      end

      def columns
        COLUMNS.each_key.map do |column|
          column(column)
        end
      end

      def joined_columns
        columns.join(',')
      end

      def types
        COLUMNS.map do |column, type|
          "`#{column(column)}` #{type}"
        end
      end

      def joined_types
        types.join(',')
      end
    end
  end
end

module Radioactive
  class Video
    attr_reader :id, :song, :length, :thumbnail

    def initialize(song:, id: '', length: 0, thumbnail: '')
      @id = id
      @song = song
      @length = length
      @thumbnail = thumbnail
    end

    def to_s
      @id
    end

    def ==(other)
      other.is_a?(Video) and (@song == other.song)
    end
  end
end