require 'dbi'
require_relative 'logger'
require_relative 'error'

module Radioactive
  class DatabaseError < Error
    attr_reader :code

    def initialize(error)
      super(error)
      @code = -1

      if error.is_a?(DBI::DatabaseError)
        @code = (error.err or -1)
      end
    end
  end
end

module Radioactive
  class Database
    DB = {
      driver: 'DBI:Mysql',
      bound: false
    }

    def self.bind(database:, user:, password:)
      DB[:database] = "#{DB[:driver]}:#{database}"
      DB[:user] = user
      DB[:password] = password
      DB[:bound] = true
    end

    def self.initialize_table(classy)
      new.execute(classy::SQL.table_definition) do
        error :table_already_exists do
          cancel # Use the existing table
        end

        error do
          raise DatabaseError, "Failed to initialize table for '#{classy}'"
        end
      end
    end

    def initialize
      unless DB[:bound]
        raise Error, 'Class Database must be bound before it can be used'
      end
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
        @connection = DBI.connect(DB[:database], DB[:user], DB[:password])
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

      def cancel
        @ongoing = :cancel
        @handle = :none
      end

      def on_error(error)
        @handle = :error
        @error = error
        Logger.new.error(@error.message)

        instance_eval(&@block) if @block
        raise error unless @ongoing == :cancel
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
