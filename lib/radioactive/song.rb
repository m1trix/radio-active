module Radioactive
  class Song
    module DatabaseTable
      COLUMNS = {
        id: 'VARCHAR(128)',
        duration: 'INTEGER',
        artist: 'VARCHAR(128)',
        title: 'VARCHAR(128)',
        thumbnail: 'VARCHAR(128)',
      }

      def column_definitions
        COLUMNS.each.map do |name, type|
          "`#{name.to_s.upcase}` #{type}"
        end
      end

      def columns
        COLUMNS.each_key.map do |name|
          name.to_s.upcase
        end
      end

      def from_sql(result)
        values = {}
        COLUMNS.each_key do |name|
          values[name] = result[name.to_s.upcase]
        end
        Song.new(**values)
      end
    end
  end
end

module Radioactive
  class Song
    module DatabaseSql
      def sql_values
        [
          "'#{self.id}'", 
          self.duration, 
          "'#{self.artist}'", 
          "'#{self.title}'",
          "'#{self.thumbnail}'" 
        ]
      end
    end
  end
end

module Radioactive
  class Song
    extend DatabaseTable
    include DatabaseSql

    attr_reader :id, :duration, :artist, :title, :thumbnail

    def initialize(artist:, title:, id: '', duration: 0, thumbnail: '')
      @thumbnail = thumbnail
      @duration = duration
      @artist = artist
      @title = title
      @id = id
    end

    def ==(other)
      [
        other.is_a?(Song),
        @title == other.title,
        @artist == other.artist
      ].all?
    end
  end
end
