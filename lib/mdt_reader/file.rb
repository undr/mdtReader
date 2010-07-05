module MdtReader
  class File
    def initialize(file)
      @mdtstream = ::File.open(file, ::File::RDONLY)
      init
    end
    
    def each_with_index
      @frames.each_with_index do |frame, index|
        yield frame, index
      end
    end
    
    def only_with_index(type)
      @frames.each_with_index do |frame, index|
        yield frame, index if type == frame.type
      end
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
    
    def frames
      @frames
    end
    
    def frame(index)
      f = @frames[index]
      if block_given?
        yield f
      else
        f
      end
    end
    
    def close
      @mdtstream.close
    end
    
    private
    def init
      @mdtstream.seek(12, IO::SEEK_SET)
      @frames = []
      @frames_quantity = @mdtstream.read(2).unpack("v").first + 1
      offset, index = 33, 0
      while(index < frames_quantity) do
        frame = Frame.create(offset, @mdtstream)
        @frames << frame
        offset += frame.length
        index += 1
      end
    end
  end
end