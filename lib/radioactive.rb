lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include? lib

require 'radioactive/database'
require 'radioactive/youtube'
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
