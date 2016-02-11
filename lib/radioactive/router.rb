require 'sinatra/base'
require 'radioactive/library'
require 'radioactive/radio'

module Radioactive
  class Router < Sinatra::Base
    public

    def initialize
      @radio = Radio.new
      @library = Library.new
      @context = {}
      create_player
    end

    private

    def create_player
      get '/index.html' do
        @context[:video] = @library.find(song: @radio.now_playing)
        erb :'index.html'
      end 
    end
  end
end
