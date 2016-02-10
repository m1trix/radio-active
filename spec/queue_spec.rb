require 'radioactive/queue'
require 'radioactive/song'
require 'radioactive/cycle'
require 'mock/database_mock'

describe Radioactive::SongsQueue do
  before :all do
    @songs = {
      fire: Radioactive::Song.new('Ed Sheeran - I See Fire'),
      hello: Radioactive::Song.new('Adele - Hello'),
      writings: Radioactive::Song.new('Sam Smith - Writings on the Wall')
    }
  end

  before :each do
    @db = Radioactive::Database.new
    @cycle = Radioactive::Cycle.new
    @queue = Radioactive::SongsQueue.new(@cycle)
  end

  after :each do
    @db.execute <<-SQL
      DROP TABLE IF EXISTS #{Radioactive::SongsQueue::SQL::TABLE}
    SQL
  end

  describe '#initialize' do
    it 'creates all missing tables' do
      expect(
        @db.select("SHOW TABLES LIKE '#{Radioactive::SongsQueue::SQL::TABLE}'", []) do |row|
          handle do |tables|
            tables.push(row[0])
          end
        end
      ).to eq [Radioactive::SongsQueue::SQL::TABLE]
    end

    it 'loads the queue from the database' do
      @queue.push(@songs[:hello])
      @queue = Radioactive::SongsQueue.new(@cycle)
      expect(@queue.all).to eq [@songs[:hello]]
    end
  end

  describe '#push' do
    it 'pushes a new song at the end of the queue' do
      expect(@queue.all).to eq []

      @queue.push(@songs[:hello])
      expect(@queue.all). to eq [@songs[:hello]]

      expect(
        @db.select("SELECT * FROM #{Radioactive::SongsQueue::SQL::TABLE}", []) do |row|
          handle do |queue|
            queue.push(Radioactive::Song.new(row['SONG']))
          end
        end
      ).to eq [@songs[:hello]]
    end

    it 'cannot add elements that are not songs' do
      expect do
        @queue.push :keyword
      end.to raise_error 'Only songs can be added to the queue'
      expect(@queue.all).to eq []
    end

    it 'does not change in case of an error' do
      @db.execute "DROP TABLE #{Radioactive::SongsQueue::SQL::TABLE}"

      expect do
        @queue.push @songs[:fire]
      end.to raise_error 'Failed to push to the queue'

      expect(@queue.all).to eq []
    end

    it 'cannot push twice in the same cycle' do
      @queue.push @songs[:writings]
      expect do
        @queue.push @songs[:fire]
      end.to raise_error 'A song was pushed to the queue in this cycle'
      expect(@queue.top).to eq @songs[:writings]
    end

    it 'only loads songs newer than the current cycle' do
      first_cycle = Radioactive::Cycle.new
      Radioactive::SongsQueue.new(first_cycle).push @songs[:fire]

      next_cycle = Radioactive::Cycle.new
      Radioactive::SongsQueue.new(next_cycle).push @songs[:writings]

      expect(Radioactive::SongsQueue.new(first_cycle).all).to(
        eq [@songs[:fire], @songs[:writings]])

      expect(Radioactive::SongsQueue.new(next_cycle).all).to(
        eq [@songs[:writings]])
    end
  end
end