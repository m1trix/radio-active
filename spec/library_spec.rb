require 'radioactive/library'
require 'mock/database_mock'

describe Radioactive::Library do
  before :each do
    @db = Radioactive::Database.new
    @library = Radioactive::Library.new

    @songs = {
      fire: Radioactive::Song.new('Ed Sheeran - I See Fire')
    }

    @videos = {
      fire: Radioactive::Video.new(
        song: @songs[:fire],
        id: '1234',
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

    it 'cannot add the same video twice' do
      @library.add(@videos[:fire])
      expect do
        @library.add(@videos[:fire])
      end.to raise_error "Video '#{@videos[:fire].id}' is already added"
    end
  end

  describe '#find' do
    it 'can find a video by a song' do
      @library.add(@videos[:fire])
      expect(
        @library.find(song: @songs[:fire])
      ).to eq @videos[:fire]
    end

    it 'can find a video by id' do
      @library.add(@videos[:fire])
      expect(
        @library.find(id: @videos[:fire].id)
      ).to eq @videos[:fire]
    end

    it 'returns nil if nothing is found' do
      expect(
        @library.find(id: @videos[:fire].id)
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