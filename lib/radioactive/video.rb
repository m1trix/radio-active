module Radioactive
  class Video
    module SQL
      COLUMNS = {
        id: 'VARCHAR(32)',
        song: 'VARCHAR(256)',
        length: 'INTEGER',
        thumbnail: 'VARCHAR(128)'
      }

      module_function

      def values(video)
        "('%s', '%s', %d, '%s')" % [
          video.id,
          video.song.gsub(/'/, "''"),
          video.length,
          video.thumbnail
        ]
      end

      def get(row)
        Video.new(
          id: row[column(:id)],
          song: row[column(:song)],
          thumbnail: row[column(:thumbnail)],
          length: row[column(:length)]
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

      def type(name)
        "`#{column(name)}` #{COLUMNS[name]}"
      end

      def types
        COLUMNS.each_key.map do |column|
          type(column)
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

    def initialize(id:, song:, length: 0, thumbnail: '')
      @id = id
      @song = song
      @length = length
      @thumbnail = thumbnail
    end

    def to_s
      @id
    end

    def ==(other)
      other.is_a?(Video) and (@id == other.id)
    end
  end
end