module MdtReader
  class Frame
    TYPES = {0 => :scan, 1 => :spectroscopy, 201 =>:curves, 106 => :mda}.freeze
    def initialize(offset, stream)
      @stream = stream
      @offset = offset
    end
    
    def length
      @length ||= rewind_to(0).read(4).unpack("l")
    end
    
    def type
      @type ||= TYPES[rewind_to(4).read(2).unpack("i")]
    end
    
    private
    def rewind_to(pos=0)
      @stream.seek(@offset+pos, IO::SEEK_SET)
      @stream
    end

  end
end