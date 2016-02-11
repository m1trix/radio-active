require 'radioactive/queue'
require 'mock/cycle_mock'
require 'mock/database_mock'

describe Radioactive::SongsQueue do
  before :all do
    @songs = {
      fire: '1111',
      hello: '2222',
      writings: '3333'
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
            queue.push(row[Radioactive::SongsQueue::SQL::COLUMN_SONG])
          end
        end
      ).to eq [@songs[:hello]]
    end

    it 'does not change in case of an error' do
      @db.execute "DROP TABLE #{Radioactive::SongsQueue::SQL::TABLE}"

      expect do
        @queue.push @songs[:fire]
      end.to raise_error 'Failed to push to the queue'

      expect(@queue.all).to eq []
    end

    it 'only loads songs newer than the current cycle' do
      Radioactive::SongsQueue.new(@cycle).push @songs[:fire]

      next_cycle = @cycle.next
      Radioactive::SongsQueue.new(next_cycle).push @songs[:writings]

      expect(Radioactive::SongsQueue.new(@cycle).all).to(
        eq [@songs[:fire], @songs[:writings]])

      expect(Radioactive::SongsQueue.new(next_cycle).all).to(
        eq [@songs[:writings]])
    end
  end
end