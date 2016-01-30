lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include? lib

require 'radioactive/auth'
require 'yaml'

#
#   M A I N
#

bindings = YAML.load_file('db_binding.yaml')
Radioactive::Database.bind(
  database: bindings['database'],
  user: bindings['user'],
  password: bindings['password']
)
