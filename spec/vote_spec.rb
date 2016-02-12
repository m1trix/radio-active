require 'mock/database_mock'
require 'radioactive/vote'
require 'radioactive/cycle'

describe Radioactive::VotingSystem do
  before :each do
    @db = Radioactive::Database.new
    @cycle = Radioactive::Cycle.new
    @votes = Radioactive::VotingSystem.new
  end

  after :each do
    @db.execute <<-SQL
      DELETE FROM #{Radioactive::VotingSystem::SQL::TABLE}
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
      @votes.vote(@cycle, 'test_user', $videos[:fire].id)
      expect([@db, Radioactive::VotingSystem::SQL::TABLE]).to have_rows [
        [@cycle.to_i, 'test_user', $videos[:fire].id]
      ]

      @votes.vote(@cycle, 'test_user2', $videos[:fire].id)
      expect([@db, Radioactive::VotingSystem::SQL::TABLE]).to have_rows [
        [@cycle.to_i, 'test_user', $videos[:fire].id],
        [@cycle.to_i, 'test_user2', $videos[:fire].id]
      ]
    end

    it 'allows only one vote per user per cycle' do
      @votes.vote(@cycle, 'test_user', $videos[:fire].id)

      expect do
        @votes.vote(@cycle, 'test_user', $videos[:fire].id)
      end.to raise_error "User 'test_user' has already voted"

      expect do
        @votes.vote(@cycle, 'test_user', $videos[:hello].id)
      end.to raise_error "User 'test_user' has already voted"

      expect([@db, Radioactive::VotingSystem::SQL::TABLE]).to have_rows [
        [@cycle.to_i, 'test_user', $videos[:fire].id]
      ]
    end
  end

  describe '#winner' do
    it 'selects the one with most votes' do
      @votes.vote(@cycle, 'user1', $videos[:fire].id)
      @votes.vote(@cycle, 'user2', $videos[:fire].id)
      @votes.vote(@cycle, 'user3', $videos[:hello].id)
      expect(@votes.winner(@cycle)).to eq $videos[:fire].id
    end

    it 'selects a random song when there are several winners' do
      @votes.vote(@cycle, 'user1', $videos[:fire].id)
      @votes.vote(@cycle, 'user2', $videos[:fire].id)
      @votes.vote(@cycle, 'user3', $videos[:hello].id)
      @votes.vote(@cycle, 'user4', $videos[:hello].id)
      @votes.vote(@cycle, 'user5', $videos[:letgo].id)
      expect([$videos[:fire].id, $videos[:hello].id]).to include @votes.winner(@cycle)
    end
  end
end
