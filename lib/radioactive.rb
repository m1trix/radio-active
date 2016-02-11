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

library = Radioactive::Library.new
related = Radioactive::RelatedSongs.new
access = Radioactive::Access.new

unless ARGV.empty?
  queue = Radioactive::SongsQueue.new(Radioactive::Cycle.new)
  ARGV.each do |id|
    puts "Pushing video with id '#{id}'"
    queue.push(id)
  end
end

radio = Radioactive::Radio.new
enable  :sessions
set :bind, bindings['ip_address']

before '/index.html' do
  redirect '/login.html' unless session[:user_id]
  pass
end

get '/' do
  redirect '/index.html'
end

get '/index.html' do
  erb :'index.html', locals: {
    related: radio.voting_list.map { |id| library.find(id) },
    video: library.find(radio.now_playing[:video]),
    time: radio.now_playing[:time]
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
    if session[:user_id].nil?
      401
      'Login to to vote'
    end

    radio.votes.vote(session[:user_id], params[:video])
    'Voting was successful!'
  rescue Radioactive::VotingError => e
    status 409
    e.message
  rescue Error => e
    status 500
    'Voting failed! Try again'
  end
end

Thread.new do
  radio.run
end
