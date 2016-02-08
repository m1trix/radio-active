require 'radioactive/exception'
require 'radioactive/database'
require 'radioactive/song'

module Radioactive
  class SongsQueue
    TABLE = 'QUEUE'
    ENGINE = 'ENGINE=InnoDB'
    NUMBER = 'NUMBER'

    TABLE_SQL = <<-SQL
      CREATE TABLE IF NOT EXISTS #{TABLE} (
        `#{NUMBER}` INTEGER PRIMARY KEY,
        #{Song.column_definitions.join(',')}
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
          queue.push(Song.from_sql(row))
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
        @db.execute("INSERT INTO #{TABLE} #{columns} VALUES #{values(queue)}")
      end
    end

    def columns
      "(#{NUMBER},#{Song.columns.join(',')})"
    end

    def values(queue)
      result = queue.each_with_index.map do |song, i|
        "(#{i},#{song.sql_values.join(',')})"
      end
      result.join(',')
    end

    def initialize_table
      @db.execute(TABLE_SQL) do
        error do
          raise RadioactiveError, 'Failed to initialize playlist'
        end
      end
    end
  end
end