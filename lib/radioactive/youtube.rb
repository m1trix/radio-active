require 'radioactive/exception'
require 'radioactive/song'
require 'net/http'
require 'json'

module Radioactive
  class YouTubeError < RadioactiveError
  end
end

module Radioactive
  class YouTube
    module Convert
      REGEX = /\A(?<artist>.+) - (?<title>.+)\z/

      module_function

      def json_to_song(json)
        Song.new(**{
          id: json['id']['videoId'],
          duration: 0,
          artist: get_from_title('artist', json['snippet']['title']),
          title: get_from_title('title', json['snippet']['title']),
          thumbnail: json['snippet']['thumbnails']['default']
        })
      end

      def get_from_title(group, string)
        match = string.match(REGEX)
        match[group] if match
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
      def call(url:, description: '', parameters: [])
        url = build_url(url, parameters)
        uri = URI.parse("#{CONSTANTS[:api]}/#{url}")
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
        unless (200...300).include? code
          message = "Request for '#{description}' failed with code #{code}"
          raise YouTubeError, message
        end
      end
    end
  end
end

module Radioactive
  class YouTube
    class Proxy < Network
      def related(song)
        related = call(
          description: 'related videos',
          url: 'search',
          parameters: [
            'part=snippet',
            "relatedToVideoId=#{song.id}",
            'type=video',
            'maxResults=10'
          ])
        convert(JSON.parse(related))
      end

      def convert(songs_json)
        songs_json['items'].map do |json|
          Convert.json_to_song(json)
        end
      end
    end
  end
end