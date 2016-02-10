module Radioactive
  class Song
    attr_reader :artist, :title

    def initialize(string = '', artist: '', title: '')
      @artist = parse(string, :artist) || artist
      @title = parse(string, :title) || title
      validate
    end

    def to_sql_values
      ["'#{@title}'", "'#{@artist}'"]
    end

    def to_s
      "#{@artist} - #{@title}"
    end

    def hash
      to_s.hash
    end

    def eql?(other)
      [
        other.is_a?(Song),
        (@artist == other.artist),
        (@title == other.title)
      ].all?
    end

    def ==(other)
      eql? other
    end

    protected

    def parse(string, group)
      match = string.match(/\A(?<artist>.+?)\s*-\s*(?<title>.+)\z/)
      match[group].strip if match
    end

    def validate
      if @artist.nil? or @artist.empty?
        raise Error, 'Song artist cannot be empty'
      end

      if @title.nil? or @title.empty?
        raise Error, 'Song title cannot be empty'
      end
    end
  end
end
