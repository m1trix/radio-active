require 'json'
require 'net/http'
require_relative 'error'
require_relative 'logger'
require_relative 'video'

module Radioactive
  class YouTubeError < Error
  end
end

module Radioactive
  class YouTube
    module Convert
      module_function

      def json_to_video(json)
        length = parse_length(json)
        song = parse_song(json)
        return nil unless song

        Video.new(
          length: length,
          id: parse_id(json),
          song: song
        )
      end

      def parse_id(json)
        json['id']['videoId'] || json['id']
      end

      def parse_song(json)
        json['snippet']['title']
      end

      def parse_length(json)
        return 0 unless json['contentDetails']
        convert_time(json['contentDetails']['duration'])
      end

      def convert_time(string)
        hours, minutes, seconds = 0, 0, 0
        if match = string.match(/.*(\d+)H.*\z/)
          hours = match.captures[0].to_i
        end

        if match = string.match(/.*(\d+)M.*\z/)
          minutes = match.captures[0].to_i
        end

        if match = string.match(/.*(\d+)S.*\z/)
          seconds = match.captures[0].to_i
        end

        hours * 60 * 60 + minutes * 60 + seconds
      end
    end
  end
end

module Radioactive
  class YouTube
    CONSTANTS = {
      api: 'https://www.googleapis.com/youtube/v3'
    }

    def self.bind(key:)
      CONSTANTS[:key] = key
    end

    def self.proxy
      Proxy.new
    end
  end
end

module Radioactive
  class YouTube
    class Network
      def call(relative_url:, description: '', parameters: [])
        relative_url = build_url(relative_url, parameters)
        uri = URI.parse("#{CONSTANTS[:api]}/#{relative_url}")
        response = get_response(uri)

        assert_no_error(response, description)
        response.body
      end

      protected

      def get_response(uri)
        Net::HTTP.get_response(uri)
      end

      def build_url(url, parameters)
        query = parameters.push("key=#{CONSTANTS[:key]}").join('&')
        query.empty? ? url : "#{url}?#{query}"
      end

      def assert_no_error(request, description)
        code = request.code
        unless (200...300).include? code.to_i
          message = "Request for '#{description}' failed with status #{code}"
          raise YouTubeError, message
        end
      end
    end
  end
end

module Radioactive
  class YouTube
    class Proxy < Network
      def related(video_id)
        related = call(
          description: 'related videos',
          relative_url: 'search',
          parameters: [
            'part=snippet',
            "relatedToVideoId=#{video_id}",
            'type=video',
            'maxResults=10'
          ])
        filter_related(convert(JSON.parse(related)))
      end

      def find(video_id)
        video = call(
          description: "find \"#{video_id}\"",
          relative_url: 'videos',
          parameters: [
            'part=snippet,contentDetails',
            "id=#{video_id}"
          ])
        convert(JSON.parse(video))[0]
      end

      def convert(json, type: :video)
        json['items'].map do |item|
          Convert.json_to_video(item)
        end
      end

      def filter_related(songs)
        songs.select { |song| not song.nil? }
      end
    end
  end
end