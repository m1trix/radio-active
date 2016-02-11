require 'radioactive/exception'
require 'radioactive/database'
require 'digest'

module Radioactive
  class AccessError < Error
  end

  class Access
    TABLE = 'USERS'
    COLUMN_USER = 'USERNAME'
    COLUMN_PASS = 'PASSWORD'

    def initialize
      @db = Database.new
      @db.execute(SQL.table) do
        error do
          raise AccessError, 'Failed to initialize registry service'
        end
      end
    end

    def register(username, password)
      assert_username(username)
      assert_password(password)
      @db.execute(SQL.register(username, encrypt(password))) do
        error(:duplicate_key) do
          raise AccessError, 'Username already exists'
        end

        error do
          raise AccessError, 'Registration failed'
        end
      end
    end

    def check(username, password)
      hash = @db.select(SQL.check(username)) do |row|
        handle do
          row[SQL::COLUMN_PASS]
        end

        error do
          raise AccessError, 'Failed to authenticate user'
        end
      end

      unless encrypt(password) == hash
        raise AccessError, 'User is not authenticated'
      end
    end

    private

    def assert_username(username)
      if username.size < 4
        raise AccessError, 'Username must be at least 4 symbols long'
      end

      unless username =~ /[\w\d\_-]+/
        raise AccessError, 'Username contains invalid characters'
      end
    end

    def assert_password(password)
      if password.size < 4
        raise AccessError, 'Password must be at least 4 symbols long'
      end
    end

    def encrypt(string)
      return '' if string.nil?
      Digest::SHA512.hexdigest string
    end
  end
end

module Radioactive
  class Access
    module SQL
      TABLE = 'ACCESS'
      COLUMN_USER = 'USERNAME'
      COLUMN_PASS = 'PASSWORD'

      module_function

      def table
        <<-SQL
          CREATE TABLE IF NOT EXISTS #{TABLE} (
            `#{COLUMN_USER}` VARCHAR(32) PRIMARY KEY,
            `#{COLUMN_PASS}` VARCHAR(128)
          )
        SQL
      end

      def register(user, hash)
        <<-SQL
          INSERT INTO #{TABLE} (#{COLUMN_USER}, #{COLUMN_PASS})
          VALUES ('#{user}', '#{hash}')
        SQL
      end

      def check(user)
        <<-SQL
          SELECT #{COLUMN_PASS}
            FROM #{TABLE}
            WHERE #{COLUMN_USER}='#{user}'
        SQL
      end
    end
  end
end
