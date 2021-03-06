module MdtReader
  class Frame
    include Frame::Rewindable
    TYPES = {0 => :scan, 1 => :spectroscopy, 201 =>:curves, 106 => :mda}.freeze
    
    def self.create(offset, stream)
      stream.seek(offset + 4, IO::SEEK_SET)
      typeindex = stream.read(2).unpack("v").first
      type ||= get_type_class(typeindex)
      klass = const_get("#{type.to_s.capitalize}")
      klass.new(offset, stream)
    end
    
    def initialize(offset, stream)
      @stream = stream
      @offset = offset
    end
    
    def size
      @size ||= header.size
    end
    
    def created_at
      Time.gm(header.year, header.month, header.day, header.hour, header.minute, header.second)
    end
    
    def [](name)
      get_param(name)
    end
    
    protected
    def self.get_type_class(index)
      return TYPES[index] if TYPES[index]
      raise ::MdtReader::NotImplementedError, "Undefined type index: #{index}"
    end
    
    def rewind_to_body_pos(pos=0)
      @stream.seek(body_offset + pos, IO::SEEK_SET)
      @stream
    end
    
    def header
      @header ||= Header.new(self, @offset, @stream)
    end
    
    def body_offset
      @offset + 22
    end
    
    def get_param(name)
      raise StandardError
    end

    class Header < InternalBlock
      build_field_method :size,      0,  4, "l"
      build_field_method :type,      4,  2, "s"
      build_field_method :h_ver0,    6,  1, "c"
      build_field_method :year,      8,  2, "S"
      build_field_method :month,     10, 2, "S"
      build_field_method :day,       12, 2, "S"
      build_field_method :hour,      14, 2, "S"
      build_field_method :minute,    16, 2, "S"
      build_field_method :second,    18, 2, "S"
      build_field_method :vars_size, 20, 2, "S"
    end
  end
end