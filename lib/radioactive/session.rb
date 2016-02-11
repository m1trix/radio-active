require 'radioactive/database'
require 'radioactive/access'

module Radioactive
  class Session
    module SQL
      TABLE = 'SESSION'
      COLUMN_USER = 'USERNAME'
      COLUMN_SESSION = 'SESSION'
      COLUMN_UNTIL = 'UNTIL'

      module_function

      def table
        <<-SQL
          CREATE TABLE IF NOT EXISTS #{TABLE}
          (
            #{COLUMN_USER} VARCHAR(32),
            #{COLUMN_SESSION} VARCHAR(128),
            #{COLUMN_UNTIL} DATETIME,
            PRIMARY KEY (#{COLUMN_USER}, #{COLUMN_SESSION})
          )
        SQL
      end

      def login(username, session, date)
        <<-SQL
          INSERT INTO #{TABLE}
          (#{COLUMN_USER}, #{COLUMN_SESSION}, #{COLUMN_UNTIL})
          VALUES ('#{username}', '#{session}', '#{date}')
        SQL
      end

      def verify(username, session)
        <<-SQL
          SELECT #{COLUMN_UNTIL}
            FROM #{TABLE}
            WHERE #{COLUMN_USER}='#{username}'
              AND #{COLUMN_SESSION}='#{session}'
              AND #{COLUMN_UNTIL}>=NOW()
        SQL
      end

      def clean
        <<-SQL
          DELETE
            FROM #{TABLE}
            WHERE #{COLUMN_UNTIL}<NOW()
        SQL
      end
    end
  end
end

module Radioactive
  class Session
    def initialize
      @db = Database.new
      @access = Access.new

      @db.execute(SQL.table) do
        error do
          raise AccessError, 'Failed to initialize sessions'
        end
      end

      @db.clean(SQL.clean) do
        error do
          cancel # Fault tolerant
        end
      end
    end

    def login_with_password(username, password)
      @access.check(username, password)
      session = generate_session(username)
      date = Time.now() + (60 * 60 * 24 * 30)
      @db.execute(SQL.login(username, session, date)) do
        error do
          raise Error, 'Login failed'
        end
      end
    end

    def login_with_serssion(username, session)
      date = @db.select(SQL.verify(username, session)) do |row|
        handle do
          row[SQL::COLUMN_UNTIL]
        end

        error do
          raise Error, 'Login failed'
        end
      end

      if date.nil?
        raise AccessError, 'Login failed'
      end
    end

    private

    def generate_session(username)
      Digest::SHA512.hexdigest("#{Time.now} ~~ #{username}")
    end
  end
end
