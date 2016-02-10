require 'radioactive/exception'
require 'radioactive/video'
require 'net/http'
require 'json'

module Radioactive
  class YouTubeError < Error
  end
end

module Radioactive
  class YouTube
    module Convert
      module_function

      def json_to_video(json)
        Video.new(**{
          length: 0,
          id: json['id']['videoId'],
          song: Song.new(json['snippet']['title']),
          thumbnail: json['snippet']['thumbnails']['default']
        })
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
      def related(video)
        related = call(
          description: 'related videos',
          relative_url: 'search',
          parameters: [
            'part=snippet',
            "relatedToVideoId=#{video.id}",
            'type=video',
            'maxResults=10'
          ])
        convert(JSON.parse(related))
      end

      def convert(songs_json)
        songs_json['items'].map do |json|
          Convert.json_to_video(json)
        end
      end
    end
  end
end