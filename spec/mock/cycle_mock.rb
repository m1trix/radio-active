require 'radioactive/cycle'

module Radioactive
  class Cycle
    def initialize(cycle = 0, time = Time.now())
      @cycle = cycle
      @time = time
    end

    def set
      # Does nothing
    end
  end
end