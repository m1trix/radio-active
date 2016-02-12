require 'sinatra'
enable  :sessions

require_relative 'lib/radioactive'
$radio = Radioactive::Radio.new
$access = Radioactive::Access.new

require_relative 'routes/root'
require_relative 'routes/index'
require_relative 'routes/index_filter'
require_relative 'routes/vote'

require_relative 'routes/login'
require_relative 'routes/logout'
require_relative 'routes/register'

$radio.run # Starts the background tasks
