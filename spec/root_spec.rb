lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include? lib

spec = File.expand_path('..', __FILE__)
puts spec
$LOAD_PATH.unshift(spec) unless $LOAD_PATH.include? spec

require_relative 'custom_matchers'
require 'radioactive/video'
require_relative 'mock/database_mock'

@db = Radioactive::Database.new
tables = @db.select("SHOW TABLES", []) do |row|
  handle do |tables|
    tables.push row[0]
  end
end

tables.each do |table|
  @db.execute("DROP TABLE #{table}")
end

$videos = {
  fuel: Radioactive::Video.new(id: '1111', song: 'Metallica - Fuel', length: 213),
  fire: Radioactive::Video.new(id: '2222', song: 'Ed Sheeran - I See Fire', length: 10),
  hills: Radioactive::Video.new(id: '3333', song: 'Iron Maiden - Run to the Hills', length: 6),
  letgo: Radioactive::Video.new(id: '4444', song: 'Idina Menzel - Let It Go', length: 101),
  wall: Radioactive::Video.new(id: '5555', song: 'Pink Floyd - Another Brick in the Wall, pt.2', length: 19123),
  hello: Radioactive::Video.new(id: '6666', song: 'Adele - Hello', length: 11)
}
