lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include? lib

spec = File.expand_path('..', __FILE__)
puts spec
$LOAD_PATH.unshift(spec) unless $LOAD_PATH.include? spec
