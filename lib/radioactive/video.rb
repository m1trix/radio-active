require_relative 'database'

module Radioactive
  class Video
    attr_reader :id, :song, :length

    def initialize(id:, song:, length:)
      @id = id
      @song = song
      @length = length
    end

    def to_s
      @id
    end

    def ==(other)
      other.is_a?(Video) and (@id == other.id)
    end

    def thumbnail
      "https://i.ytimg.com/vi/#{id}/default.jpg"
    end
  end
end

module Radioactive
  class Video
    module SQL
      COLUMNS = {
        id: 'VARCHAR(32)',
        song: 'VARCHAR(256)',
        length: 'INTEGER'
      }

      module_function

      def values(video)
        "('%s', '%s', %d)" % [
          video.id,
          video.song.gsub(/'/, "''"),
          video.length,
        ]
      end

      def from_row(row)
        Video.new(
          id: row[column(:id)],
          song: row[column(:song)],
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

      def joined_columns(table = nil)
        return columns.join(',') if table.nil?
        columns.map { |column| "#{table}.#{column}" }.join(',')
      end

      def type(name)
        "`#{column(name)}` #{COLUMNS[name]}"
      end

      def definitions
        COLUMNS.each_key.map do |column|
          type(column)
        end
      end

      def joined_definitions
        definitions.join(',')
      end
    end
  end
end