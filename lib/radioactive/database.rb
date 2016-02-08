require 'radioactive/exception'
require 'dbi'

module Radioactive
  class DatabaseError < RadioactiveError
    attr_reader :code

    def initialize(error)
      super(error)
      @code = -1

      if error.is_a?(DBI::DatabaseError)
        @code = error.err
      end
    end
  end
end

module Radioactive
  class Database
    DB = {}

    def self.bind(database:, user:, password:)
      DB[:driver] = "DBI:Mysql:#{database}"
      DB[:user] = user
      DB[:password] = password
    end

    def transaction
      connect do |connection|
        begin
          connection['AutoCommit'] = false
          connection.transaction do
            yield
          end
          connection.commit
        rescue
          connection.rollback
          raise
        end
      end
    end

    def select(sql, result = nil, &block)
      handle(block, result) do |handler|
        connect do |connection|
          connection.select_all(sql) do |row|
            handler.on_success(row)
          end
        end
      end
    end

    def execute(sql, &block)
      handle(block) do
        connect do |connection|
          connection.do(sql)
        end
      end
    end

    protected

    def connect(&block)
      if @connection
        yield @connection
        return
      end
      create_connection(&block)
    end

    def create_connection
      begin
        @connection = DBI.connect(DB[:driver], DB[:user], DB[:password])
        yield @connection
      rescue DBI::Error => e
        raise DatabaseError.new(e)
      ensure
        @connection.disconnect if @connection
        @connection = nil
      end
    end

    def handle(block, result = nil)
      begin
        handler = Handler.new(block, result)
        yield handler
        handler.result
      rescue DatabaseError => e
        handler.on_error(e)
      end
    end
  end
end

module Radioactive
  class Database
    ERRORS = {
      duplicate_key: 1062,
      table_already_exists: 1050,
      table_doesnt_exist: 1146
    }
  end
end

module Radioactive
  class Database
    SUCCESS = [:condition]

    class Handler
      attr_reader :result

      def initialize(block, result)
        @ongoing = :none
        @handle = :none
        @block = block
        @result = result
      end

      def error(code = :all)
        if (@handle == :error) and error_code?(code || :all)
          yield
        end
      end

      def on(expression, &block)
        if (@handle == :success) and expression
          apply(&block)
        end
      end

      def handle(&block)
        apply(&block) if @handle == :success
      end

      def on_error(error)
        @handle = :error
        @error = error

        instance_eval(&@block) if @block
        raise error
      end

      def on_success(row)
        @handle = :success
        instance_exec(row, &@block) if @block
      end

      protected

      def error_code?(code)
        (code == :all) or (ERRORS[code] == @error.code)
      end

      def apply
        if block_given?
          @result = (yield @result)
        end
      end
    end
  end
end
