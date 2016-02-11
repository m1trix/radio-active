lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include? lib

require 'radioactive/access'
require 'radioactive/cycle'
require 'radioactive/database'
require 'radioactive/library'
require 'radioactive/logger'
require 'radioactive/queue'
require 'radioactive/radio'
require 'radioactive/related'
require 'radioactive/session'
require 'radioactive/youtube'
require 'sinatra'
require 'yaml'

#
#   M A I N
#

bindings = YAML.load_file('bindings.yaml')
Radioactive::Database.bind(
  database: bindings['database'],
  user: bindings['user'],
  password: bindings['password']
)

Radioactive::YouTube.bind(
  key: bindings['api_key']
)

Radioactive::Logger.bind(
  file: bindings['log_file']
)

radio = Radioactive::Radio.new
library = Radioactive::Library.new
related = Radioactive::RelatedSongs.new
access = Radioactive::Access.new

unless ARGV.empty?
  library.clear
  ARGV.each do |id|
    puts "Reading video with id '#{id}'"
    video = Radioactive::YouTube.proxy.find(id)
    library.add(video)
    cycle = Radioactive::Cycle.new
    Radioactive::SongsQueue.new(cycle).push(video.song)

    related_videos = Radioactive::YouTube.proxy.related(video)
    puts "Found #{related_videos.size} related videos"

    library.add_all(related_videos)
    related.insert(video.song, related_videos.map(&:song))
  end
end

radio = Radioactive::Radio.new
enable  :sessions

before '/index.html' do
  redirect '/login.html' unless session[:user_id]
  pass
end

get '/' do
  redirect '/index.html'
end

get '/index.html' do
  erb :'index.html', locals: {
    video: library.find(song: radio.now_playing).id,
    related: radio.voting_list.map do |song|
      library.find(song: song)
    end
  }
end

post '/login' do
  begin
    access.check(params[:username], params[:password])
    session[:user_id] = params[:username]
    redirect '/index.html'
  rescue Radioactive::AccessError => e
    erb :'fail.html', locals: {
      title: 'Login',
      message: e.message,
      redirect: '/login.html'
    }
  end
end

post '/logout' do
  session[:user_id] = nil
  redirect '/login.html'
end

post '/register' do
  begin
    access.register(params[:username], params[:password])
    redirect '/login.html'
  rescue Radioactive::AccessError => e
    erb :'fail.html', locals: {
      title: 'Registration',
      message: e.message,
      redirect: '/register.html'
    }
  end
end

post '/vote/:video' do
  begin
    redirect '/login.html' if session[:user_id].nil?

    song = library.find(id: params[:video]).song
    radio.votes.vote(session[:user_id], song)
    'Voting was successful!'
  rescue Radioactive::VotingError => e
    status 409
    e.message
  rescue Error => e
    status 500
    'Voting failed! Try again'
  end
end