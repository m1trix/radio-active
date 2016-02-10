require 'radioactive/vote'
require 'radioactive/cycle'
require 'radioactive/song'
require 'mock/database_mock'

describe Radioactive::VotingSystem do
  before :each do
    @db = Radioactive::Database.new
    @cycle = Radioactive::Cycle.new
    @votes = Radioactive::VotingSystem.new(@cycle)

    @songs = {
      fire: Radioactive::Song.new('Ed Sheeran - I See Fire'),
      hello: Radioactive::Song.new('Adele - Hello'),
      writings: Radioactive::Song.new('Sam Smith - Writings on the Wall'),
    }
  end

  after :each do
    @db.execute <<-SQL
      DROP TABLE IF EXISTS #{Radioactive::VotingSystem::SQL::TABLE}
    SQL
  end

  describe '#initialize' do
    it 'creates all neccassery tables when initialized' do
      sql = <<-SQL
        SHOW TABLES LIKE '#{Radioactive::VotingSystem::SQL::TABLE}'
      SQL

      expect(
        @db.select(sql, []) do |row|
          handle do |tables|
            tables.push row[0]
          end
        end
      ).to eq [Radioactive::VotingSystem::SQL::TABLE]
    end
  end

  describe '#vote' do
    it 'adds a new vote to a song' do
      @votes.vote('test_user', @songs[:fire])
      expect(@votes.votes(@songs[:fire])).to eq 1

      @votes.vote('test_user2', @songs[:fire])
      expect(@votes.votes(@songs[:fire])).to eq 2

      expect(@votes.votes(@songs[:hello])).to eq 0
    end

    it 'allows only one vote per user per cycle' do
      @votes.vote('test_user', @songs[:fire])

      expect do
        @votes.vote('test_user', @songs[:fire])
      end.to raise_error "User 'test_user' has already voted"

      expect do
        @votes.vote('test_user', @songs[:hello])
      end.to raise_error "User 'test_user' has already voted"

      expect(@votes.votes(@songs[:fire])).to eq 1
    end
  end

  it 'loads the votes of the current cycle only' do
    this_cycle = Radioactive::Cycle.new
    Radioactive::VotingSystem.new(this_cycle).vote('test_user', @songs[:fire])
    sleep(1)
    next_cycle = Radioactive::Cycle.new
    Radioactive::VotingSystem.new(next_cycle).vote('test_user', @songs[:hello])

    expect(
      [
        Radioactive::VotingSystem.new(this_cycle).votes(@songs[:fire]),
        Radioactive::VotingSystem.new(this_cycle).votes(@songs[:hello])
      ]
    ).to eq [1, 0]

    expect(
      [
        Radioactive::VotingSystem.new(next_cycle).votes(@songs[:fire]),
        Radioactive::VotingSystem.new(next_cycle).votes(@songs[:hello])
      ]
    ).to eq [0, 1]
  end

  describe '#winner' do
    it 'selects the one with most votes' do
      @votes.vote('user1', @songs[:fire])
      @votes.vote('user2', @songs[:fire])
      @votes.vote('user3', @songs[:hello])
      expect(@votes.winner).to eq @songs[:fire]
    end

    it 'selects a random song when there are several winners' do
      @votes.vote('user1', @songs[:fire])
      @votes.vote('user2', @songs[:fire])
      @votes.vote('user3', @songs[:hello])
      @votes.vote('user4', @songs[:hello])
      @votes.vote('user5', @songs[:writings])
      expect([@songs[:fire], @songs[:hello]]).to include @votes.winner
    end
  end
end
