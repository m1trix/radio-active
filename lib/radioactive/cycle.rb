module Radioactive
  class Cycle
    def initialize(time = nil)
      @time = (time or Time.new)
    end

    def to_s
      @time.strftime '%Y-%m-%d %H-%M-%S.%L'
    end
  end
end