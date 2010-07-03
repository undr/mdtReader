module MdtReader
  class Frame
    TYPES = {0 => :scan, 1 => :spectroscopy, 201 =>:curves, 106 => :mda}.freeze
    HEADER = {:lenght => {:offset => 0, :bytes => 4, :type => "V"},
              :type => {:offset => 4, :bytes => 2, :type => "v"},
              :year => {:offset => 8, :bytes => 2, :type => "v"},
              :month => {:offset => 10, :bytes => 2, :type => "v"},
              :day => {:offset => 12, :bytes => 2, :type => "v"},
              :hour => {:offset => 14, :bytes => 2, :type => "v"},
              :minute => {:offset => 16, :bytes => 2, :type => "v"},
              :second => {:offset => 18, :bytes => 2, :type => "v"},
              :vars_size => {:offset => 20, :bytes => 2, :type => "v"}
              }.freeze
    def self.create(offset, stream)
      stream.seek(offset + HEADER[:type][:offset], IO::SEEK_SET)
      type ||= TYPES[stream.read(HEADER[:type][:bytes]).unpack(HEADER[:type][:type]).first]
      klass = const_get("#{type.to_s.capitalize}")
      klass.new(offset, stream)
    end 
    
    def initialize(offset, stream)
      @stream = stream
      @offset = offset
    end
    
    def length
      @length ||= get_header_value(:length)
    end
    
    def created_at
      Time.gm(get_header_value(:year), get_header_value(:month), get_header_value(:day), get_header_value(:hour), get_header_value(:minute), get_header_value(:second))
    end
    
    def [](name)
      get_param(name)
    end
    
    private
    def rewind_to(pos=0)
      @stream.seek(@offset+pos, IO::SEEK_SET)
      @stream
    end
    
    def rewind_to_boby_pos(pos=0)
      @stream.seek(body_offset+pos, IO::SEEK_SET)
      @stream
    end
    
    def get_header_value(name)
      rewind_to(HEADER[name][:offset]).read(HEADER[name][:bytes]).unpack(HEADER[name][:type]).first
    end
    
    def body_offset
      @offset + 22
    end
  end
  
  class ScanAndSpectroscopy < Frame
    AXISSCALE = {'axisScale.xOffset' => {:offset => 0,  :bytes => 4, :type => "e"},
                  'axisScale.yOffset' => {:offset => 10, :bytes => 4, :type => "e"},
                  'axisScale.zOffset' => {:offset => 20, :bytes => 4, :type => "e"},
                  'axisScale.xStep'   => {:offset => 4,  :bytes => 4, :type => "e"},
                  'axisScale.yStep'   => {:offset => 14, :bytes => 4, :type => "e"},
                  'axisScale.zStep'   => {:offset => 24, :bytes => 4, :type => "e"},
                  'axisScale.xUnit'   => {:offset => 8,  :bytes => 2, :type => "v"},
                  'axisScale.yUnit'   => {:offset => 18, :bytes => 2, :type => "v"},
                  'axisScale.zUnit'   => {:offset => 28, :bytes => 2, :type => "v"}
                  }.freeze

    def property_exists?(name)
      PROPERTIES.include?(name) || MAINDATA.include?(name) || AXISSCALE.include?(name)
    end
    
    private
    def get_param(name)
      return rewind_to_boby_pos(AXISSCALE[name][:offset]).read(AXISSCALE[name][:bytes]).unpack(AXISSCALE[name][:type]).first if AXISSCALE.include?(name)
      vars_offset = body_offset + 30
      return rewind_to_boby_pos(vars_offset + PROPERTIES[name][:offset]).read(PROPERTIES[name][:bytes]).unpack(PROPERTIES[name][:type]).first if PROPERTIES.include?(name)
      main_data_header_offset = body_offset + get_header_value(:vars_size)
      return rewind_to(main_data_header_offset + MAINDATA[name][:offset]).read(MAINDATA[name][:bytes]).unpack(MAINDATA[name][:type]).first if MAINDATA.include?(name)
      nil
    end
    
  end
  
  class Scan < ScanAndSpectroscopy
    PROPERTIES = {}.freeze
    MAINDATA = {'mainData.width'  => {:offset => 2, :bytes => 2, :type => "v"},
                'mainData.height' => {:offset => 4, :bytes => 2, :type => "v"}
                }.freeze
    def type
      :scan
    end
    
    def raw_data
      main_data_offset = body_offset + get_header_value(:vars_size) + 8
      rewind_to(main_data_offset).read(image_width*image_height*2)
    end
    
    private
    def get_param(name)
      param = super.get_param(name)
      return param if param
      return image_width if name == "image.width"
      return image_height if name == "image.height"
      nil
    end
    
    def image_width
      @image_width ||= calculate_image_width
    end
    
    def image_height
      @image_height ||= calculate_image_height
    end
    
    def calculate_image_width
      x_step, y_step = get_param('axisScale.xStep'), get_param('axisScale.yStep')
      ratio = x_step / y_step
      if x_step < y_step
        get_param('mainData.width') * ratio
      else
        get_param('mainData.width')
      end
    end
    
    def calculate_image_height
      x_step, y_step = get_param('axisScale.xStep'), get_param('axisScale.yStep')
      ratio = x_step / y_step
      if x_step > y_step
        get_param('mainData.height') * ratio
      else
        get_param('mainData.height')
      end
    end
  end
  
  class Spectroscopy < ScanAndSpectroscopy
    
    PROPERTIES = {}.freeze
    MAINDATA = {'mainData.width'  => {:offset => 2, :bytes => 2, :type => "v"},
                'mainData.height' => {:offset => 4, :bytes => 2, :type => "v"}
                }.freeze
                
    def type
      :spectroscopy
    end
  end
  
  class Curves < Frame
    
    def type
      :curves
    end  
    
    private
    def get_param(name)
      
    end
  end
  
  class Mda < Frame
    
    def type
      :mda
    end
    
    private
    def get_param(name)
      
    end
  end
end