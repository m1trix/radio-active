require 'radioactive/cycle'
require 'radioactive/exception'
require 'radioactive/library'
require 'radioactive/logger'
require 'radioactive/queue'
require 'radioactive/related'
require 'radioactive/vote'

module Radioactive
  class Radio
    def initialize
      @services = create_services(Cycle.new)
    end

    def run
      loop do
        begin
          song = now_playing
          puts ">>> #{song[:time]} : #{song[:length]} <<<"
          next_song if (song[:time] >= song[:length])
        rescue Exception => e
          Logger.new.error(e.message)
        end
        sleep 1
      end
    end

    def now_playing
      {
        cycle: @services[:cycle].to_i,
        video: @services[:queue].top,
        time: (Time.now.utc - @services[:cycle].time).to_i,
        length: Library.new.find(@services[:queue].top).length
      }
    end

    def votes
      @services[:votes]
    end

    def voting_list
      @services[:queue].all.reduce([]) do |list, song|
        list.concat(@services[:related].list(song))
      end
    end

    def next_song
      @services[:queue].push(select_winner)
      next_cycle
    end

    private

    def select_winner
      @services[:votes].winner or voting_list.sample
    end

    def create_services(cycle)
      {
        cycle: cycle,
        queue: SongsQueue.new(cycle),
        votes: VotingSystem.new(cycle),
        related: RelatedSongs.new
      }
    end

    def next_cycle
      services = create_services(@services[:cycle].next)
      services[:cycle].set
      @services = services
    end
  end
end