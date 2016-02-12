require 'mock/database_mock'


describe Radioactive::Database do
  after :each do
    @db.execute <<-SQL
      DROP TABLE IF EXISTS TEST
    SQL
  end

  before :each do
    class Test
      module SQL
        module_function

        def table_definition
          <<-SQL
            CREATE TABLE TEST (
              `NAME` VARCHAR(32) PRIMARY KEY,
              `VALUE` VARCHAR(32)
            ) ENGINE=InnoDb
          SQL
        end
      end
    end

    @db = Radioactive::Database.new
    Radioactive::Database.initialize_table Test
  end

  describe '::bind' do
    it 'binds the DB parameters to the class' do
      Radioactive::Database.bind(database: 'DB', user: 'USER', password: 'PWD')
      expect(Radioactive::Database::DB[:database]).to eq 'DBI:Mysql:DB'
      expect(Radioactive::Database::DB[:user]).to eq 'USER'
      expect(Radioactive::Database::DB[:password]).to eq 'PWD'

      Radioactive::Database.bind_test
    end
  end

  describe '#select' do
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

  describe '#transaction' do
    it 'works as a simple wrapper' do
      @db.transaction do
        @db.execute("INSERT INTO TEST VALUES ('what', 'no')")
      end

      result = @db.select('SELECT * FROM TEST') do |row|
        handle { row[0] }
      end
      expect(result).to eq 'what'
    end

    it 'works with multiple statements' do
      @db.transaction do
        @db.execute("INSERT INTO TEST VALUES ('what', 'no')")
        @db.execute("INSERT INTO TEST VALUES ('you', 'die')")
      end

      expect(
        @db.select('SELECT * FROM TEST', []) do |row|
          handle { |result| result.push(row[1]) }
        end
      ).to eq ['no', 'die']
    end

    it 'rolls back all statements in case of error' do
      expect do
        @db.transaction do
          @db.execute("INSERT INTO TEST VALUES ('do', 'all')")
          @db.execute("INSERT INTO TEST VALUES ('what', 'no')")
          @db.execute("INSERT INTO TST VALUES ('yes', 'you')")
        end
      end.to raise_error Radioactive::DatabaseError

      expect(
        @db.select('SELECT * FROM TEST') do |row|
          handle { row[1] }
        end
      ).to be_nil
    end
  end
end
