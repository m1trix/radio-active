require 'radioactive/exception'
require 'radioactive/database'
require 'radioactive/song'

module Radioactive
  class SongsQueue
    TABLE = 'QUEUE'
    ENGINE = 'ENGINE=InnoDB'

    C_NUMBER = 'NUMBER'
    C_ARTIST = 'ARTIST'
    C_TITLE = 'TITLE'
    C_URL = 'URL'

    TABLE_SQL = <<-SQL
      CREATE TABLE IF NOT EXISTS #{TABLE} (
        `#{C_NUMBER}` INTEGER PRIMARY KEY,
        `#{C_ARTIST}` VARCHAR(128),
        `#{C_TITLE}` VARCHAR(128),
        `#{C_URL}` VARCHAR(128)
      ) #{ENGINE}
    SQL

    attr_reader :queue

    def initialize
      @db = Database.new
      initialize_table
      @queue = load_queue
    end

    def push(song)
      set_queue @queue.dup.push(validate_song(song))
    end

    def replace(song)
      if @queue.empty?
        raise RadioactiveError, 'The queue is empty'
      end
      set_queue @queue.drop(1).push(validate_song(song))
    end

    private

    def load_queue
      @db.select("SELECT * FROM #{TABLE}", []) do |row|
        handle do |queue|
          queue.push(Song.new(row[C_ARTIST], row[C_TITLE], row[C_URL]))
        end
      end
    end

    def validate_song(song)
      unless song.is_a? Radioactive::Song
        raise RadioactiveError, 'Only songs can be added to the queue'
      end
      song
    end

    def set_queue(queue)
      begin
        persist(queue)
        @queue = queue
      rescue DatabaseError => e
        raise RadioactiveError, 'Operation failed'
      end
    end

    def persist(queue)
      @db.transaction do
        @db.execute("DELETE FROM #{TABLE}")
        @db.execute <<-SQL
          INSERT INTO #{TABLE} #{columns}
          VALUES #{values(queue)}
        SQL
      end
    end

    def columns
      "(#{C_NUMBER}, #{C_ARTIST}, #{C_TITLE}, #{C_URL})"
    end

    def values(queue)
      result = queue.each_with_index.map do |song, i|
        "(#{i}, '#{song.artist}', '#{song.title}', '#{song.url}')"
      end
      result.join(',')
    end

    def initialize_table
      @db.execute(TABLE_SQL) do
        on_error do
          raise RadioactiveError, 'Failed to initialize playlist'
        end
      end
    end
  end
end