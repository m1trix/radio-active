require 'dbi'

module Radioactive
  class Database
    DB = {}

    def self.bind(database:, user:, password:)
      DB[:driver] = "DBI:Mysql:#{database}"
      DB[:user] = user
      DB[:password] = password
    end

    def select(sql, result = nil, &block)
      handle(block) do |handler|
        DBI.connect(DB[:driver], DB[:user], DB[:password]) do |connection|
          connection.select_all(sql) do |row|
            result = handler.on_success(row, result)
          end
        end
        result
      end
    end

    def execute(sql, &block)
      handle(block) do
        DBI.connect(DB[:driver], DB[:user], DB[:password]) do |connection|
          connection.do(sql)
        end
      end
    end

    protected

    def handle(block)
      begin
        handler = Handler.new
        handler.bind(block)
        yield handler
      rescue DBI::Error => e
        handler.on_error(e)
      end
    end
  end
end

module Radioactive
  class Database
    ERRORS = {
      duplicate_key: 1061,
      table_already_exists: 1050,
      table_doesnt_exist: 1146
    }
  end
end

module Radioactive
  class Database
    SUCCESS = [:condition]

    class Handler
      def initialize
        @ongoing = :none
        @cath = :none
      end

      def error(code = :all)
        if @catch == :error
          @ongoing = (code or :all)
        end
      end

      def always
        @ongoing = :always if @catch == :success
      end

      def condition(predicate)
        if (@catch == :success) and predicate
          @ongoing = :condition
        end
      end

      def raises(exception = nil, message)
        return unless @ongoing
        if (@ongoing == :all) or (@ongoing == :condition) or expected_error
          raise(exception, message) if exception
          raise message
        end
      end

      def result(&block)
        unless @ongoing == :none
          @result = @result.instance_eval(&block)
          @ongoing = :none
        end
      end

      def bind(block)
        @block = block
      end

      def on_error(error)
        @catch = :error
        @error = error
        instance_eval(&@block) if @block
        raise error
      end

      def on_success(row, result)
        @catch = :success
        @result = result
        instance_exec(row, &@block) if @block
        @result
      end

      protected

      def expected_error
        return false unless @error.is_a? DBI::DatabaseError
        ERRORS[@ongoing] == @error.err
      end
    end
  end
end
