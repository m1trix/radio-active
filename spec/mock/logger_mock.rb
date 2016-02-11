require 'radioactive/logger'

module Radioactive
  class Logger
    ENABLED = false

    def info(message)
      puts "#{Time.now} [INFO]: #{message}" if ENABLED
    end

    def error(message)
      puts "#{Time.now} [INFO]: #{message}" if ENABLED
    end
  end
end