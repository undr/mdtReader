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
        raise ::MdtReader::NotImplementedError, "It must be implemented in children classes"
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
        raise ::MdtReader::NotImplementedError, "it must be implemented in children classes"
      end

      protected  
      def unit_size
        2
      end
      
      def init
        @data = unpack
        @init = true
        normalize if @normalize
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

module MdtReader
  class Frame
    class DataBase
      require 'inline'
      inline do |builder|

        builder.c <<-EOC
VALUE 
normalize() {
  long min, max, maxMinusMin, value;
  VALUE data = rb_iv_get(self, "@data");
  int size = RARRAY(data)->len;
  int i;
  max = NUM2LONG(RARRAY(data)->ptr[0]);
  min = NUM2LONG(RARRAY(data)->ptr[0]);
  
  for (i = 0; i < size; i++) {
    value = NUM2LONG(RARRAY(data)->ptr[i]);
    if (value > max) {
      max = value;
    } else if (value < min) {
      min = value;
    }
  }
  maxMinusMin = max - min;
  
  if(maxMinusMin == 0) {
    maxMinusMin = 1;
  }

  for(i = 0; i < size; i++) {
    value = NUM2LONG(RARRAY(data)->ptr[i]);
    RARRAY(data)->ptr[i] = LONG2NUM(((value - min) * 255) / maxMinusMin);
  }
  return data;
}
EOC
      end
    rescue => e
      pp e
      def normalize
        max, min = @data.max, @data.min
        max_minus_min = max - min
        max_minus_min = 1 if max_minus_min == 0
        @data.collect! do |value|
          (((value - min) * 255) / max_minus_min).floor
        end
      end
    end
  end
end