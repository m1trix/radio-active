module Radioactive
  class Logger
    CONSTANTS = {}

    def self.bind(file:)
      CONSTANTS[:file] = file
    end

    def info(message)
      file do |file|
        file.write("#{Time.now} [INFO]: #{message}\n")
      end
    end

    def error(message)
      file do |file|
        file.write("#{Time.now} [ERROR]: #{message}\n")
      end
    end

    private

    def file(&block)
      File.open(CONSTANTS[:file], 'a', &block)
    end
  end
end