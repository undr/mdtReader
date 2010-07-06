module MdtReader
  module Rewindable
    def rewind_to(pos=0)
      @stream.seek(@offset + pos, IO::SEEK_SET)
      @stream
    end
  end
  
  class InternalBlock
    include Rewindable
    def initialize(frame, offset, stream)
      @offset, @frame, @stream = offset, frame, stream
    end
  end
  
  class Frame
    include Rewindable
    TYPES = {0 => :scan, 1 => :spectroscopy, 201 =>:curves, 106 => :mda}.freeze
    HEADER = {:length => {:offset => 0, :bytes => 4, :type => "V"},
              :type => {:offset => 4, :bytes => 2, :type => "v"},
              :year => {:offset => 8, :bytes => 2, :type => "v"},
              :month => {:offset => 10, :bytes => 2, :type => "v"},
              :day => {:offset => 12, :bytes => 2, :type => "v"},
              :hour => {:offset => 14, :bytes => 2, :type => "v"},
              :minute => {:offset => 16, :bytes => 2, :type => "v"},
              :second => {:offset => 18, :bytes => 2, :type => "v"},
              :vars_size => {:offset => 20, :bytes => 2, :type => "v"}
              }.freeze
    
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
    
    protected
    def rewind_to_body_pos(pos=0)
      @stream.seek(body_offset+pos, IO::SEEK_SET)
      @stream
    end
    
    def get_header_value(name)
      rewind_to(HEADER[name][:offset]).read(HEADER[name][:bytes]).unpack(HEADER[name][:type]).first if HEADER[name]
    end
    
    def body_offset
      @offset + 22
    end
    
    def get_param(name)
      raise StandardError
    end
  end
  
  class ScanAndSpectroscopy < Frame
    class << self
      attr_accessor :properties, :maindata
    end
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
      self.class.properties.include?(name) || self.class.maindata.include?(name) || AXISSCALE.include?(name)
    end

    protected
    def vars_size
      @vars_size ||= get_header_value(:vars_size)
    end
    
    def get_param(name)
      return rewind_to_body_pos(AXISSCALE[name][:offset]).read(AXISSCALE[name][:bytes]).unpack(AXISSCALE[name][:type]).first if AXISSCALE.include?(name)
      offset = body_offset + 30
      return rewind_to_body_pos(offset + self.class.properties[name][:offset]).read(self.class.properties[name][:bytes]).unpack(self.class.properties[name][:type]).first if self.class.properties.include?(name)
      offset = vars_size
      return rewind_to_body_pos(offset + self.class.maindata[name][:offset]).read(self.class.maindata[name][:bytes]).unpack(self.class.maindata[name][:type]).first if self.class.maindata.include?(name)
      nil
    end
  end
  
  class Scan < ScanAndSpectroscopy
    self.properties = {}
    self.maindata =  {'mainData.width'  => {:offset => 2, :bytes => 2, :type => "v"},
                      'mainData.height' => {:offset => 4, :bytes => 2, :type => "v"}
                      }.freeze
    def type
      :scan
    end
    
    def data
      @data ||= Data.new(self, vars_size + 8, @stream)
    end
    
    protected
    def get_param(name)
      param = super(name)
      return param if param
      return data.width if name == "image.width"
      return data.height if name == "image.height"
      nil
    end
    
    class Data < InternalBlock
      def raw
        size = @scan['mainData.width'] * @scan['mainData.height'] * 2
        rewind_to.read(size)
      end
      
      def [](index)
        data_init unless data_init?
        @data[index]
      end
      
      def to_a
        data_init unless data_init?
        @data
      end
      
      def to_png(palette=nil)
        palette ||= Palette.new(PNG::Color.new(255, 255, 0), PNG::Color.new(128, 0, 111), PNG::Color.new(0, 255, 28))
        width, height = @frame['mainData.width'], @frame['mainData.height']
        canvas = PNG::Canvas.new(width, height)
        y, index = 0, 0
        while(y < height) do
          x = 0
          while(x < width) do
            color = palette[self[index]]
            canvas.[]=(x, y, color)
            index += 1
            x += 1
          end
          y += 1
        end
        PNG.new canvas
      end
      
      def save_as_png(filename)
        to_png.save(filename)
      end
      
      def width
        @width ||= calculate_width
      end
              
      def height
        @height ||= calculate_height
      end
            
      protected  
      def calculate_width
        x_step, y_step = @frame['axisScale.xStep'], @frame['axisScale.yStep']
        ratio = x_step / y_step
        if x_step < y_step
          @frame['mainData.width'] * ratio
        else
          @frame['mainData.width']
        end
      end
              
      def calculate_height
        x_step, y_step = @frame['axisScale.xStep'], @frame['axisScale.yStep']
        ratio = x_step / y_step
        if x_step > y_step
          @frame['mainData.height'] * ratio
        else
          @frame['mainData.height']
        end
      end      
      
      def init
        @data = raw.unpack("v*").collect do |value|
          value -= 0x1_0000 if (value & 0x8000).nonzero?
          value
        end
        max, min = result.max, result.min
        max_minus_min = max - min
        @init = true
        @data.collect do |value|
          (((value - min) * 256) / max_minus_min).round
        end
      end
      
      def init?
        @init ||= false
      end
    end
  end
  
  class Spectroscopy < ScanAndSpectroscopy
    self.properties = {}
    self.maindata =  {'mainData.width'  => {:offset => 2, :bytes => 2, :type => "v"},
                      'mainData.height' => {:offset => 4, :bytes => 2, :type => "v"},
                      'mainData.mode'   => {:offset => 0, :bytes => 2, :type => "v"},
                      'mainData.points' => {:offset => 6, :bytes => 2, :type => "v"}
                      }.freeze

    def type
      :spectroscopy
    end
    
    def raw_data
      
    end
    
    def data
      
    end
  end
  
  class Curves < Frame
    
    def type
      :curves
    end  
    
    protected
    def get_param(name)
      
    end
  end
  
  class Mda < Frame
    
    def type
      :mda
    end
    
    protected
    def get_param(name)
      
    end
  end
  
  class Frame
    def self.create(offset, stream)
      stream.seek(offset + HEADER[:type][:offset], IO::SEEK_SET)
      type ||= TYPES[stream.read(HEADER[:type][:bytes]).unpack(HEADER[:type][:type]).first]
      klass = MdtReader.const_get("#{type.to_s.capitalize}")
      klass.new(offset, stream)
    end
  end
end