module MdtReader
  class File
    def initialize(file)
      @mdtstream = ::File.open(file, File::RDONLY)
      init
    end
    
    def each
      @frames.each do |frame|
        yield frame
      end
    end
    
    def only(type)
      @frames.each do |frame|
        yield frame if type == frame.type
      end
    end
    
    def frames_quantity
      @frames_quantity
    end
    
    def frame(index)
      @frames[index]
    end
    
    def close
      @mdtstream.close
    end
    
    private
    def init
      @mdtstream.seek(12, IO::SEEK_SET)
      @frames = []
      @frames_quantity = @mdtstream.read(2).unpack("i")
      offset = 33
      while(index < frames_quantity) do
        frame = Frame.new(offset, @mdtstream)
        @frames << frame
        offset += frame.length
      end
    end
  end
end