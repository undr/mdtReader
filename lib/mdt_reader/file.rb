module MdtReader
  class File
    def initialize(file)
      @mdtstream = ::File.open(file, ::File::RDONLY)
      init
    end
    
    def each_with_index
      @frames.each_with_index do |frame, index|
        begin
          yield frame, index
        rescue ::MdtReader::NotImplementedError => e
        end
      end
    end
    
    def only_with_index(type)
      type = [type] unless type.is_a?(Array)
      @frames.each_with_index do |frame, index|
        begin
          yield frame, index if type.include?(frame.type)
        rescue ::MdtReader::NotImplementedError => e
          pp e
        end
      end
    end
    
    def each
      @frames.each do |frame|
        begin
          yield frame
        rescue ::MdtReader::NotImplementedError => e
        end
      end
    end
    
    def only(type)
      type = [type] unless type.is_a?(Array)
      @frames.each do |frame|
        begin
          yield frame if type.include?(frame.type)
        rescue ::MdtReader::NotImplementedError => e
        end
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
        begin
          frame = Frame.create(offset, @mdtstream)
          @frames << frame
        rescue ::MdtReader::NotImplementedError => e
        end
        @mdtstream.seek(offset, IO::SEEK_SET)
        size = @mdtstream.read(4).unpack("l").first
        offset += size
        index += 1
      end
    end
  end
end