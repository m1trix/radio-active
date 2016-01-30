require 'radioactive/access.rb'

describe Radioactive::Access do
  before :each do
    @db = Radioactive::Database.new
    @access = Radioactive::Access.new
  end

  after :each do
    @db.execute <<-SQL
      DROP TABLE IF EXISTS #{Radioactive::Access::TABLE}
    SQL
  end

  it 'creates tables if missing' do
    expect do
      @db.execute('CREATE TABLE #{Radioactive::Access::TABLE}')
    end.to raise_error DBI::Error
  end

  describe '#allow' do
    it 'can allow user access' do
      @access.allow('test1', 'pass')
      @access.allow('test2', 'pass')

      sql = <<-SQL
        SELECT #{Radioactive::Access::COLUMN_USER}
        FROM #{Radioactive::Access::TABLE}
      SQL

      expect(
        @db.select(sql, []) do |row|
          handle { result.push row[0] }
        end
      ).to eq %w(test1 test2)
    end

    it 'cannot allow user twice' do
      @access.allow('test', 'pass')
      expect do
        @access.allow('test', 'another_pass')
      end.to raise_error Radioactive::AccessError
    end
  end

  describe '#check' do
    it 'can verify user access' do
      expect do
        @access.check('test', 'pass')
      end.to raise_error Radioactive::AccessError

      @access.allow('test', 'pass')
      @access.check('test', 'pass')

      expect do
        @access.check('test', 'another_pass')
      end.to raise_error Radioactive::AccessError
    end
  end
end