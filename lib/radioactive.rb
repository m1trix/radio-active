require 'yaml'
bindings = YAML.load_file('bindings.yaml')

require_relative 'radioactive/database'
Radioactive::Database.bind(
  database: bindings['database'],
  user: bindings['user'],
  password: bindings['password']
)

require_relative 'radioactive/logger'
Radioactive::Logger.bind(file: bindings['log_file'])

require_relative 'radioactive/access'
require_relative 'radioactive/cycle'
require_relative 'radioactive/library'
require_relative 'radioactive/playlist'
require_relative 'radioactive/radio'
require_relative 'radioactive/relations'
require_relative 'radioactive/youtube'

Radioactive::YouTube.bind(key: bindings['api_key'])

# Initiates the playlist with the given video IDs
unless ARGV.empty?
  playlist = Radioactive::Playlist.new
  relations = Radioactive::Relations.new
  youtube = Radioactive::YouTube.proxy

  ARGV.each do |id|
    puts "Pushing video with id '#{id}'"
    video = youtube.find(id)
    playlist.push(video)
    relations.insert(video, youtube.related(video))
  end
end
