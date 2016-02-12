require 'mock/database_mock'
require 'radioactive/library'

describe Radioactive::Library do
  before :each do
    @db = Radioactive::Database.new
    @library = Radioactive::Library.new
  end

  after :each do
    @db.execute <<-SQL
      DELETE FROM #{Radioactive::Library::SQL::TABLE}
    SQL
  end

  it 'creates all tables if missing' do
    sql = <<-SQL
      SHOW TABLES LIKE '#{Radioactive::Library::SQL::TABLE}'
    SQL

    expect(
      @db.select(sql) do |row|
        handle { row[0] }
      end
    ).to eq Radioactive::Library::SQL::TABLE
  end

  describe '#add' do
    it 'adds additional videos' do
      @library.add($videos[:fire])
      expect([@db, Radioactive::Library::SQL::TABLE]).to have_rows [
        [$videos[:fire].id, $videos[:fire].song, $videos[:fire].length]
      ]

      @library.add($videos[:hello])
      expect([@db, Radioactive::Library::SQL::TABLE]).to have_rows [
        [$videos[:fire].id, $videos[:fire].song, $videos[:fire].length],
        [$videos[:hello].id, $videos[:hello].song, $videos[:hello].length]
      ]
    end

    it 'is fault tolerant in case of a duplicate key' do
      @library.add($videos[:fire])
      @library.add($videos[:fire])

      expect([@db, Radioactive::Library::SQL::TABLE]).to have_rows [
        [$videos[:fire].id, $videos[:fire].song, $videos[:fire].length]
      ]
    end
  end

  describe '#add_all' do
    it 'adds an array of videos one after the other' do
      @library.add_all([$videos[:fire], $videos[:hello]])

      expect([@db, Radioactive::Library::SQL::TABLE]).to have_rows [
        [$videos[:fire].id, $videos[:fire].song, $videos[:fire].length],
        [$videos[:hello].id, $videos[:hello].song, $videos[:hello].length]
      ]
    end

    it 'is fault tolerant in case of a duplicate key' do
      @library.add_all([$videos[:fire], $videos[:hello], $videos[:fire]])

      expect([@db, Radioactive::Library::SQL::TABLE]).to have_rows [
        [$videos[:fire].id, $videos[:fire].song, $videos[:fire].length],
        [$videos[:hello].id, $videos[:hello].song, $videos[:hello].length]
      ]
    end
  end

  describe '#find' do
    it 'can find a video by id' do
      @library.add($videos[:fire])
      expect(@library.find($videos[:fire].id)).to eq $videos[:fire]
    end

    it 'returns nil if nothing is found' do
      @library.add($videos[:fire])
      expect(@library.find($videos[:hello].id)).to be_nil
    end
  end

  describe '#delete' do
    it 'deletes a video by an id' do
      @library.add_all([$videos[:fire], $videos[:hello]])
      @library.delete($videos[:fire].id)
      expect(@library.find($videos[:fire].id)).to be_nil
      expect(@library.find($videos[:hello].id)).to eq $videos[:hello]
    end

    it 'is fault tolerant in case of missing video' do
      @library.delete($videos[:fire].id)
      expect(@library.find($videos[:fire].id)).to be_nil
    end
  end
end