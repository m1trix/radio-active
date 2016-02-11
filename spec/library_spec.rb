require 'radioactive/library'
require 'mock/database_mock'

describe Radioactive::Library do
  before :each do
    @db = Radioactive::Database.new
    @library = Radioactive::Library.new

    @videos = {
      fire: Radioactive::Video.new(
        id: '1234',
        song: 'Ed Sheeran - I See Fire',
        thumbnail: 'www.web.site.com',
        length: 10
      )
    }
  end

  after :each do
    @db.execute <<-SQL
      DROP TABLE IF EXISTS #{Radioactive::Library::SQL::TABLE}
    SQL
  end

  it 'creates all tables if missing' do
    sql = <<-SQL
      SHOW TABLES LIKE '#{Radioactive::Library::SQL::TABLE}'
    SQL

    expect(
      @db.select(sql) do |row|
        handle do
          row[0]
        end
      end
    ).to eq Radioactive::Library::SQL::TABLE
  end

  describe '#add' do
    it 'adds additional videos' do
      @library.add(@videos[:fire])

      sql = "SELECT * FROM #{Radioactive::Library::SQL::TABLE}"
      expect(
        @db.select(sql, 0) do |row|
          handle do |count|
            count + 1
          end
        end
      ).to eq 1
    end
  end

  describe '#find' do
    it 'can find a video by id' do
      @library.add(@videos[:fire])
      expect(
        @library.find(@videos[:fire].id)
      ).to eq @videos[:fire]
    end

    it 'loads it from youtube if not present' do
      allow(@library).to receive(:find_in_youtube) do
        @videos[:fire]
      end
      expect(
        @library.find(@videos[:fire].id)
      ).to eq @videos[:fire]
    end

    it 'returns nil if nothing is found' do
      allow(@library).to receive(:find_in_youtube) do
        nil
      end
      expect(
        @library.find(@videos[:fire].id)
      ).to eq nil
    end
  end

  describe '#clear' do
    it 'deletes all records' do
      @library.add(@videos[:fire])
      @library.clear

      sql = "SELECT * FROM #{Radioactive::Library::SQL::TABLE}"
      expect(
        @db.select(sql, 0) do |row|
          handle do |count|
            count + 1
          end
        end
      ).to eq 0
    end
  end
end