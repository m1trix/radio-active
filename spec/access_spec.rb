require 'mock/database_mock'
require 'radioactive/access'

describe Radioactive::Access do
  before :each do
    @db = Radioactive::Database.new
    @access = Radioactive::Access.new
  end

  after :each do
    @db.execute <<-SQL
      DELETE FROM #{Radioactive::Access::SQL::TABLE}
    SQL
  end

  it 'creates tables if missing' do
    expect do
      @db.execute('CREATE TABLE #{Radioactive::Access::SQL::TABLE}')
    end.to raise_error Radioactive::DatabaseError
  end

  describe '#register' do
    it 'can allow user access' do
      @access.register('test1', 'pass')
      @access.register('test2', 'pass')

      sql = <<-SQL
        SELECT #{Radioactive::Access::SQL::COLUMN_USER}
        FROM #{Radioactive::Access::SQL::TABLE}
      SQL

      expect(
        @db.select(sql, []) do |row|
          handle { result.push row[0] }
        end
      ).to eq %w(test1 test2)
    end

    it 'cannot register user twice' do
      @access.register('test', 'pass')
      expect do
        @access.register('test', 'another_pass')
      end.to raise_error Radioactive::AccessError
    end
  end

  describe '#check' do
    it 'can verify user access' do
      expect do
        @access.check('test', 'pass')
      end.to raise_error Radioactive::AccessError

      @access.register('test', 'pass')
      @access.check('test', 'pass')

      expect do
        @access.check('test', 'another_pass')
      end.to raise_error Radioactive::AccessError
    end
  end
end