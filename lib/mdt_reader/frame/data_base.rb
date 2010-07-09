module MdtReader
  class Frame
    class DataBase
      include Rewindable
      def initialize(frame, offset, stream)
        @offset, @frame, @stream = offset, frame, stream
        @normalize = true
      end
      
      def [](index)
        init unless init?
        @data[index]
      end
      
      def size
        raise NotImplementedError, "It must be implemented in children classes"
      end
      
      def to_a
        init unless init?
        @data
      end
      
      def raw
        rewind_to.read(size)
      end
      
      def to_png(palette=nil)
        
      end

      def save_as_png(filename)
        raise NotImplementedError, "it must be implemented in children classes"
      end

      protected  
      def unit_size
        2
      end
      
      def init
        @data = unpack
        max, min = @data.max, @data.min
        max_minus_min = max - min
        @init = true
        @data.collect! do |value|
          (((value - min) * 256) / max_minus_min).floor
        end if @normalize
      end
      
      def unpack
        raw.unpack("v*").collect do |value|
          value -= 0x1_0000 if (value & 0x8000).nonzero?
          value
        end
      end

      def init?
        @init ||= false
      end
    end
  end
end