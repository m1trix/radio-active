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
      sql = <<-SQL
        CREATE TABLE IF NOT EXISTS #{TABLE} (
          `#{COLUMN_USER}` VARCHAR(32) PRIMARY KEY,
          `#{COLUMN_PASS}` VARCHAR(128))
      SQL
      @db.execute(sql) do
        error { raise AccessError, 'Failed to initialize registry service' }
      end
    end

    def allow(username, password)
      sql = <<-SQL
        INSERT INTO #{TABLE} (#{COLUMN_USER}, #{COLUMN_PASS})
        VALUES ('#{username}', '#{encrypt(password)}')
      SQL
      @db.execute(sql) do
        error(:duplicate_key) do
          raise AccessError, 'Username already exists'
        end

        error do
          raise AccessError, 'Registration failed'
        end
      end
    end

    def check(username, password)
      sql = <<-SQL
        SELECT #{COLUMN_PASS} FROM #{TABLE}
        WHERE #{COLUMN_USER} LIKE '#{username}'
      SQL

      hash = @db.select(sql) do |row|
        handle { row[0] }
        error { raise AccessError, 'Failed to authenticate user' }
      end

      unless encrypt(password) == hash
        raise AccessError, 'User is not authenticated'
      end
    end

    private

    def encrypt(string)
      Digest::SHA512.hexdigest string
    end
  end
end
