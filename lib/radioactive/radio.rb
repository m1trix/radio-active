require_relative 'cycle'
require_relative 'error'
require_relative 'library'
require_relative 'logger'
require_relative 'playlist'
require_relative 'relations'
require_relative 'vote'

module Radioactive
  class Radio
    class Player < Struct.new(:video, :elapsed_time, :related)
    end
  end
end

module Radioactive
  class Radio
    QUEUE_SIZE = 3

    def initialize
      @cycle = Cycle.new
      @votes = VotingSystem.new
      @relations = Relations.new
      @library = Library.new
      @playlist = Playlist.new
      prepare_cycle
    end

    def player
      Player.new(@video, elapsed_time, @related)
    end

    def vote(username, video_id)
      index = @related.index do |video|
        video.id == video_id
      end

      unless index
        raise VotingError, 'The video id is not in the list'
      end

      @votes.vote(@cycle, username, video_id)
    end

    def run
      Thread.new do
        while true
          playlist
        end
      end
    end

    private

    def elapsed_time
      (Time.now.utc - @cycle.time).to_i
    end

    def next_cycle
      video = YouTube.proxy.find(winner.id)
      @library.update(video)

      @relations.delete(@video)
      @relations.insert(video, YouTube.proxy.related(video))
      @playlist.push(video)
      @cycle = @cycle.next
      @cycle.set
      prepare_cycle
    end

    def winner
      winner = @votes.winner(@cycle)
      return @related.sample if winner.nil?

      @library.find(winner)
    end

    def prepare_cycle
      @video = @playlist.list(@cycle, 1)[0]
      @related = @playlist.list(@cycle, QUEUE_SIZE).reduce([]) do |r, v|
        r.concat(@relations.list(v))
      end

      @related.uniq! do |video|
        video.id
      end
    end

    def playlist
      begin
        puts ">>> #{elapsed_time} : #{@video.length} <<<"
        if (elapsed_time >= @video.length)
          puts "Switching cycles"
          next_cycle
        end
      rescue Exception => e
        Logger.new.error(e.message)
        Logger.new.error(e.backtrace.join("\n"))
      end
      sleep 1
    end
  end
end
