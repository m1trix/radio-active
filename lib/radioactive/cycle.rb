require 'radioactive/database'
require 'radioactive/exception'
require 'radioactive/logger'
require 'time'

module Radioactive
  class Cycle
    attr_reader :time

    def initialize(cycle = nil, time = nil)
      @db = Database.new
      initialize_table

      @cycle = (cycle or load_cycle or 0)
      @time = (time or load_time or Time.now.utc)
    end
    
    def next
      Cycle.new(@cycle + 1, Time.now.utc)
    end

    def to_s
      @cycle.to_s
    end

    def to_i
      @cycle
    end

    def set
      begin
        @db.transaction do
          @db.execute(SQL.clear)
          @db.execute(SQL.insert(@cycle, @time.strftime('%Y-%m-%d %H-%M-%S')))
        end
      rescue DatabaseError => e
        Logger.new.error(e.message)
        raise Error, 'Failed to set cycle'
      end
    end

    private

    def initialize_table
      @db.execute(SQL.table) do
        error do
          raise Error, 'Failed to initialize cycles'
        end
      end
    end

    def load_cycle
      load(SQL::COLUMN_CYCLE)
    end

    def load_time
      datetime = load(SQL::COLUMN_TIME)
      datetime.to_time if datetime
    end

    def load(column)
      @db.select(SQL.read) do |row|
        handle do
          row[column]
        end

        error do
          raise Error, 'Failed to read cycle'
        end
      end
    end
  end
end

module Radioactive
  class Cycle
    module SQL
      TABLE = 'CYCLE'
      COLUMN_CYCLE = 'CYCLE'
      COLUMN_TIME = 'TIME'
      ENGINE = 'ENGINE=InnoDb'

      module_function

      def table
        <<-SQL
          CREATE TABLE IF NOT EXISTS #{TABLE} (
            `#{COLUMN_CYCLE}` BIGINT PRIMARY KEY,
            `#{COLUMN_TIME}` DATETIME
          ) #{ENGINE}
        SQL
      end

      def insert(cycle, datetime)
        <<-SQL
          INSERT INTO #{TABLE} (#{COLUMN_CYCLE}, #{COLUMN_TIME})
            VALUES (#{cycle}, '#{datetime}')
        SQL
      end

      def clear
        <<-SQL
          DELETE FROM #{TABLE}
        SQL
      end

      def read
        <<-SQL
          SELECT #{COLUMN_CYCLE}, #{COLUMN_TIME} FROM #{TABLE}
        SQL
      end
    end
  end
end