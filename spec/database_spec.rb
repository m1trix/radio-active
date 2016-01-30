require 'radioactive/database'
require 'mock/constants_mock'

describe Radioactive::Database do
  describe '::bind' do
    it 'binds the DB parameters to the class' do
      Radioactive::Database.bind(database: 'DB', user: 'USER', password: 'PWD')
      expect(Radioactive::Database::DB[:driver]).to eq 'DBI:Mysql:DB'
      expect(Radioactive::Database::DB[:user]).to eq 'USER'
      expect(Radioactive::Database::DB[:password]).to eq 'PWD'
    end
  end

  describe '#select' do
    before :each do
      Radioactive::Database.bind(
        database: Radioactive::Constants::DB_DRIVER,
        user: Radioactive::Constants::DB_USER,
        password: Radioactive::Constants::DB_USER_PASSWORD)
      @db = Radioactive::Database.new

      @db.execute <<-SQL
        CREATE TABLE TEST (
          `NAME` VARCHAR(32) PRIMARY KEY,
          `VALUE` VARCHAR(32)
        )
      SQL
    end

    after :each do
      @db.execute <<-SQL
        DROP TABLE IF EXISTS TEST
      SQL
    end

    it 'can read and write data' do
      @db.execute "INSERT INTO TEST VALUES('reason', 'test')"

      expect(
        @db.select("SELECT VALUE FROM TEST WHERE NAME LIKE 'reason'") do |row|
          handle do
            row[0]
          end
        end
      ).to eq 'test'
    end

    it 'can work with complex select statements' do
      @db.execute <<-SQL
        INSERT INTO TEST VALUES
        ('meaning', 'test'),
        ('reason', 'improvement');
      SQL

      expect(
        @db.select('SELECT VALUE FROM TEST', []) do |row|
          handle { result.push row[0] }
        end
      ).to eq %w(test improvement)
    end

    it 'can handle specific errors' do
      sql = <<-SQL
        CREATE TABLE TEST (
          `NAME` VARCHAR(32) PRIMARY KEY,
          `VALUE` VARCHAR(32)
        )
      SQL

      expect do
        @db.execute(sql) do
          error(:table_already_exists) do
            raise 'The table is already there!'
          end
        end
      end.to raise_error('The table is already there!')
    end

    it 'can handle all errors' do
      expect do
        @db.select('SELECT * FROM UNKNOWN') do
          error(:table_already_exists) do
            raise 'This is not the expected error'
          end

          error do
            raise 'All is rescued'
          end
        end
      end.to raise_error 'All is rescued'

      expect do
        @db.select('SELECT * FROM UNKNOWN') do
          error(:table_doesnt_exist) do
            raise 'This goes first'
          end

          error do
            raise 'All is rescued'
          end
        end
      end.to raise_error 'This goes first'

      expect do
        @db.select('SELECT * FROM UNKNOWN') do
          error do
            raise 'The order matters'
          end

          error(:table_doesnt_exist) do
            raise 'This goes first'
          end
        end
      end.to raise_error 'The order matters'
    end

    it 'can have conditional logic' do
      @db.execute <<-SQL
        INSERT INTO TEST VALUES
        ('meaning', 'test'),
        ('reason', 'improvement');
      SQL

      result = []
      expect do
        # This will not happen in case of error
        result = @db.select('SELECT VALUE FROM TEST', []) do |row|
          on(row[0] == 'improvement') do
            raise 'stop'
          end

          handle { |r| r.push(row[0]) }
        end
      end.to raise_error 'stop'
      expect(result).to eq []

      expect(
        @db.select('SELECT VALUE FROM TEST', '') do |row|
          on(row[0] == 'test') { |r| "#{r}6" }
          on(row[0] == 'improvement') { |r| "#{r}/49" }
        end
      ).to eq('6/49')
    end
  end
end
