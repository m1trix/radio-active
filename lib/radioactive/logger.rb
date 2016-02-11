module Radioactive
  class Logger
    CONSTANTS = {}

    def self.bind(file:)
      CONSTANTS[:file] = file
    end

    def info(message)
      file do |file|
        file.write("#{Time.now} [INFO]: #{message}")
      end
    end

    def error(message)
      file do |file|
        file.write("#{Time.now} [ERROR]: #{message}")
      end
    end

    private

    def file(&block)
      File.open(CONSTANTS[:file], 'w+', &block)
    end
  end
end