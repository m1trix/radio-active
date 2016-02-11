require 'radioactive/cycle'
require 'radioactive/database'
require 'radioactive/exception'
require 'radioactive/queue'
require 'radioactive/related'
require 'radioactive/vote'

module Radioactive
  class Radio
    module SQL
      TABLE = 'RADIO'
      ENGINE = 'ENGINE=InnoDb'
      COLUMN_CYCLE = 'CYCLE'
      COLUMN_VOTING = 'VOTING'

      module_function

      def table
        <<-SQL
          CREATE TABLE IF NOT EXISTS #{TABLE} (
            #{COLUMN_CYCLE} DATETIME(3),
            #{COLUMN_VOTING} TINYINT
          ) #{ENGINE}
        SQL
      end

      def load
        <<-SQL
          SELECT #{COLUMN_CYCLE},#{COLUMN_VOTING}
            FROM #{TABLE}
        SQL
      end

      def delete
        "DELETE FROM #{TABLE}"
      end

      def insert(cycle)
        <<-SQL
          INSERT INTO #{TABLE} (#{COLUMN_CYCLE}, #{COLUMN_VOTING})
          VALUES ('#{cycle}', false)
        SQL
      end

      def update(voting)
        <<-SQL
          UPDATE #{TABLE}
            SET #{COLUMN_VOTING}=voting
        SQL
      end
    end
  end
end

module Radioactive
  class Radio
    attr_reader :votes

    def initialize
      @db = Database.new
      initialize_table
      load

      @queue = SongsQueue.new(@cycle)
      @votes = VotingSystem.new(@cycle)
      @related = RelatedSongs.new
    end

    def now_playing
      @queue.top
    end

    def voting_list
      @queue.all.reduce([]) do |list, song|
        list.concat(@related.list(song))
      end
    end

    def next_song
      @queue.push(@votes.winner)
      next_cycle

      @queue = Queue.new(@cycle)
      @votes = VotingSystem.new(@cycle)
    end

    private

    def next_cycle
      begin
        next_cycle = Cycle.new
        @db.transaction do
          @db.execute(SQL.delete)
          @db.execute(SQL.insert(next_cycle))
        end
        @cycle = next_cycle
      rescue DatabaseError => e
        raise Error, 'Failed to progress cycle'
      end
    end

    def load
      @cycle = @db.select(SQL.load) do |row|
        handle do
          Cycle.new(row[SQL::COLUMN_CYCLE])
        end

        error do
          raise Error, 'Failed to load radio state'
        end
      end
      next_cycle unless @cycle
    end

    def initialize_table
      @db.execute(SQL.table) do
        error do
          raise Error, 'Failed to initialize'
        end
      end
    end
  end
end