require 'mock/database_mock'
require 'mock/cycle_mock'
require 'radioactive/playlist'

describe Radioactive::Playlist do
  before :each do
    @db = Radioactive::Database.new
    @cycle = Radioactive::Cycle.new
    @playlist = Radioactive::Playlist.new
  end

  after :each do
    @db.execute "DELETE FROM #{Radioactive::Playlist::SQL::TABLE}"
    @db.execute "DELETE FROM #{Radioactive::Library::SQL::TABLE}"
  end

  it 'creates all required tables' do
    expect(@db).to have_table Radioactive::Playlist::SQL::TABLE
  end

  describe '#push' do
    it 'pushes a new song at the end of the playlist' do
      expect([@db, Radioactive::Playlist::SQL::TABLE]).to have_rows []

      @playlist.push($videos[:hello])
      expect([@db, Radioactive::Playlist::SQL::TABLE]).to have_rows [
        [0, $videos[:hello].id]
      ]

      @playlist.push($videos[:fire])
      expect([@db, Radioactive::Playlist::SQL::TABLE]).to(
        have_rows [0, $videos[:hello].id], [1, $videos[:fire].id]
      )
    end

    it 'does not change in case of an error' do
      begin
        @db.execute "DROP TABLE #{Radioactive::Playlist::SQL::TABLE}"

        expect do
          @playlist.push $videos[:fire]
        end.to raise_error 'Failed to read playlist size'
      ensure
        Radioactive::Database.initialize_table(Radioactive::Playlist)
      end

      expect(@playlist.list(@cycle, 1)).to eq []
    end
  end

  describe '#list' do
    it 'only loads songs newer than the target cycle' do
      @playlist.push($videos[:fire])
      @playlist.push($videos[:fuel])

      expect(@playlist.list(@cycle, 2)).to include $videos[:fire], $videos[:fuel]
      expect(@playlist.list(@cycle.next, 2)).to include $videos[:fuel]

      @playlist.push($videos[:wall])

      expect(@playlist.list(@cycle, 2)).to include $videos[:fire], $videos[:fuel]
      expect(@playlist.list(@cycle.next, 2)).to include $videos[:fuel], $videos[:wall]
    end
  end
end