module Radioactive
  class Filter
    def filter(videos)
      videos.select do |video|
        should_keep(video)
      end
    end

    private

    def should_keep(video)
      (not video.nil?) and keep_song?(video.song)
    end

    def keep_song?(song)
      [
        (song !~ /\A(.+?)\s*-\s*(.+)/),
        (song.downcase.include? 'parody'),
        (song.downcase.include? 'cover')
      ].none?
    end
  end
end