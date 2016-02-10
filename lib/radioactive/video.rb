require 'radioactive/song'

module Radioactive
  class Video
    attr_reader :id, :song, :length, :thumbnail

    def initialize(song:, id: '', length: 0, thumbnail: '')
      @id = id
      @song = song
      @length = length
      @thumbnail = thumbnail
    end
  end
end