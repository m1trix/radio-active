require 'radioactive/youtube'
require 'net/http'

describe Radioactive::YouTube do
  def build_response(code, body)
    Struct.new(:code, :body).new(code, body)
  end

  def mock_http_call(net, &block)
    allow(net).to receive(:get_response, &block)
  end

  describe '::bind' do
    it 'binds the Google API key' do
      Radioactive::YouTube.bind(key: 'apikey')
      expect(Radioactive::YouTube::CONSTANTS[:key]).to(
        eq 'apikey')
      expect(Radioactive::YouTube::CONSTANTS[:api]).to(
        eq 'https://www.googleapis.com/youtube/v3') 
    end
  end

  describe Radioactive::YouTube::Network do
    before :each do
      @net = Radioactive::YouTube::Network.new
    end

    describe '#call' do
      it 'throws exception unless success' do
        mock_http_call @net do
          build_response(404, '')
        end

        expect do
          @net.call(description: 'test', relative_url: 'doesnt/matter')
        end.to raise_error "Request for 'test' failed with status 404"
      end

      it 'returns the body of the response' do
        mock_http_call @net do
          build_response(200, 'that body')
        end

        expect(@net.call(relative_url: 'doesnt/matter')).to eq 'that body'
      end

      it 'can receive query parameters' do
        mock_http_call @net do |uri|
          build_response(200, uri.to_s)
        end

        api = Radioactive::YouTube::CONSTANTS[:api]
        expect(@net.call(
          relative_url: 'doesnt/matter',
          parameters: ['param1', 'param2=true'])
        ).to eq "#{api}/doesnt/matter?param1&param2=true&key=apikey"
      end
    end
  end

  describe Radioactive::YouTube::Proxy do
    before :each do
      @proxy = Radioactive::YouTube::Proxy.new
      mock_http_call @proxy do
        build_response(200, '')
      end
    end

    describe '#related' do
      it 'it parses the response json and returns an array of videos' do
        mock_http_call @proxy do
          content = File.read('spec/resources/related.json')
          build_response(200, content)
        end

        expect(@proxy.related('1234')).to eq [
          Radioactive::Video.new(id: 'hLQl3WQQoQ0', song: 'Adele - Someone Like You', length: 0),
          Radioactive::Video.new(id: 'rYEDA3JcQqw', song: 'Adele - Rolling in the Deep', length: 0),
          Radioactive::Video.new(id: 'DeumyOzKqgI', song: 'Adele - Skyfall (Lyric Video)', length: 0),
          Radioactive::Video.new(id: 'QcIy9NiNbmo', song: 'Taylor Swift - Bad Blood ft. Kendrick Lamar', length: 0)
        ]
      end
    end
  end
end
