require 'mock/database_mock'
require 'radioactive/relations'

describe Radioactive::Relations do
  before :each do
    @db = Radioactive::Database.new
    @relations = Radioactive::Relations.new
    @library = Radioactive::Library.new
  end

  after :each do
    @db.execute <<-SQL
      DELETE FROM #{Radioactive::Relations::SQL::TABLE}
    SQL
  end

  it 'creates all neccessary tables when loaded' do
    expect(@db).to have_table Radioactive::Relations::SQL::TABLE
  end

  describe '#insert' do
    it 'adds all videos to the library' do
      @relations.insert($videos[:fire], [$videos[:fuel], $videos[:hills]])
      @relations.insert($videos[:fire], [$videos[:letgo]])
      @relations.insert($videos[:wall], [$videos[:hello]])

      expect(@library.find($videos[:fire].id)).to eq $videos[:fire]
      expect(@library.find($videos[:hills].id)).to eq $videos[:hills]
      expect(@library.find($videos[:fuel].id)).to eq $videos[:fuel]
      expect(@library.find($videos[:letgo].id)).to eq $videos[:letgo]
      expect(@library.find($videos[:wall].id)).to eq $videos[:wall]
      expect(@library.find($videos[:hello].id)).to eq $videos[:hello]

      expect([@db, Radioactive::Relations::SQL::TABLE]).to have_rows [
        [$videos[:fire].id, $videos[:hills].id],
        [$videos[:fire].id, $videos[:fuel].id],
        [$videos[:wall].id, $videos[:hello].id],
        [$videos[:fire].id, $videos[:letgo].id]
      ]
    end

    it 'cannot have the same relation twice' do
      @relations.insert($videos[:fire], [$videos[:fuel], $videos[:hills]])
      @relations.insert($videos[:wall], [$videos[:hello]])

      expect do
        @relations.insert($videos[:fire], [$videos[:letgo], $videos[:hills]])
      end.to raise_error Radioactive::Error

      expect([@db, Radioactive::Relations::SQL::TABLE]).to have_rows [
        [$videos[:fire].id, $videos[:hills].id],
        [$videos[:fire].id, $videos[:fuel].id],
        [$videos[:wall].id, $videos[:hello].id]
      ]
    end
  end

  describe '#list' do
    it 'returns all related videos to a target video' do
      @relations.insert($videos[:fire], [$videos[:fuel], $videos[:hills]])
      expect(@relations.list($videos[:fire])).to include $videos[:fuel], $videos[:hills]

      @relations.insert($videos[:fire], [$videos[:letgo]])
      expect(@relations.list($videos[:fire])).to include $videos[:fuel], $videos[:hills], $videos[:letgo]
    end
  end

  describe '#delete' do
    it 'deletes all related videos to a target video' do
      @relations.insert($videos[:fire], [$videos[:fuel], $videos[:hills]])
      @relations.insert($videos[:fire], [$videos[:letgo]])

      @relations.delete($videos[:fire])
      expect(@relations.list($videos[:fire])).to be_empty
    end
  end
end
