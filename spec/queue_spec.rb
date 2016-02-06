require 'radioactive/queue'
require 'radioactive/song'
require 'mock/database_mock'

describe Radioactive::SongsQueue do
  before :all do
    @songs = {
      fire: Radioactive::Song.new('Ed Sheeran', 'I See Fire', 'url'),
      hello: Radioactive::Song.new('Adele', 'Hello', 'url'),
      writings: Radioactive::Song.new('Sam Smith', 'Writings on the Wall', 'url')
    }
  end

  before :each do
    @db = Radioactive::Database.new
    @queue = Radioactive::SongsQueue.new
  end

  after :each do
    @db.execute <<-SQL
      DROP TABLE IF EXISTS #{Radioactive::SongsQueue::TABLE}
    SQL
  end

  describe '#initialize' do
    it 'creates all missing tables' do
      expect(
        @db.select("SHOW TABLES LIKE '#{Radioactive::SongsQueue::TABLE}'", []) do |row|
          handle do |tables|
            tables.push(row[0])
          end
        end
      ).to eq [Radioactive::SongsQueue::TABLE]
    end

    it 'loads the queue from the database' do
      @queue.push(@songs[:hello])
      @queue = Radioactive::SongsQueue.new
      expect(@queue.queue).to eq [@songs[:hello]]
    end
  end

  describe '#push' do
    it 'pushes a new song at the end of the queue' do
      expect(@queue.queue).to eq []

      @queue.push(@songs[:hello])
      expect(@queue.queue). to eq [@songs[:hello]]

      @queue.push(@songs[:fire])
      expect(@queue.queue). to eq [@songs[:hello], @songs[:fire]]

      expect(
        @db.select("SELECT * FROM #{Radioactive::SongsQueue::TABLE}", []) do |row|
          handle do |queue|
            queue.push(row[1])
          end
        end
      ).to eq [@songs[:hello].artist, @songs[:fire].artist]
    end
  end

  describe '#replace' do
    it 'pops the first song and pushes a new one' do
      @queue.push(@songs[:hello])
      expect(@queue.queue).to eq [@songs[:hello]]

      @queue.replace(@songs[:fire])
      expect(@queue.queue).to eq [@songs[:fire]]

      @queue.push(@songs[:writings])
      expect(@queue.queue).to eq [@songs[:fire], @songs[:writings]]

      @queue.replace(@songs[:hello])
      expect(@queue.queue).to eq [@songs[:writings], @songs[:hello]]
    end

    it 'does not work on an empty queue' do
      expect do
        @queue.replace(@songs[:hello])
      end.to raise_error 'The queue is empty'
    end
  end

  it 'does not change in case of an error' do
    @queue.push @songs[:hello]
    @db.execute "DROP TABLE #{Radioactive::SongsQueue::TABLE}"

    expect do
      @queue.replace @songs[:fire]
    end.to raise_error 'Operation failed'
    expect(@queue.queue).to eq [@songs[:hello]]

    expect do
      @queue.push @songs[:fire]
    end.to raise_error 'Operation failed'
    expect(@queue.queue).to eq [@songs[:hello]]
  end

  it 'cannot hold elements that are not songs' do
    expect do
      @queue.push :keyword
    end.to raise_error 'Only songs can be added to the queue'
    @queue.push @songs[:hello]

    expect do
      @queue.replace []
    end.to raise_error 'Only songs can be added to the queue'

    expect(@queue.queue).to eq [@songs[:hello]]
  end
end