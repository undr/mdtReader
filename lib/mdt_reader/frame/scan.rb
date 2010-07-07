module MdtReader
  class Frame
    class Scan < ScanAndSpectroscopy  
      def type
        :scan
      end

      def data
        @data ||= Data.new(self, body_offset + header.vars_size + 8, @stream)
      end

      protected
      def get_param(name)
        param = super(name)
        return param if param
        return data.width if name == "image.width"
        return data.height if name == "image.height"
        nil
      end
      
      def properties
        @properties ||= Properties.new(self, body_offset + 30, @stream)
      end
      
      def maindata
        @maindata ||= Maindata.new(self, body_offset + header.vars_size, @stream)
      end
      
      class Properties < InternalBlock
        
      end
      
      class Maindata < InternalBlock
        build_field_method :width, 2, 2, "v"
        build_field_method :height, 2, 2, "v"        
      end
      
      class Data
        include Rewindable
        
        def initialize(frame, offset, stream)
          @offset, @frame, @stream = offset, frame, stream
        end
        
        def raw
          size = @frame['maindata.width'] * @frame['maindata.height'] * 2
          rewind_to.read(size)
        end

        def [](index)
          init unless init?
          @data[index]
        end

        def to_a
          init unless init?
          @data
        end

        def to_png(palette=nil)
          palette ||= Palette.new(PNG::Color.new(255, 255, 0), PNG::Color.new(128, 0, 111), PNG::Color.new(0, 255, 28))
          width, height = @frame['maindata.width'], @frame['maindata.height']
          canvas = PNG::Canvas.new(width, height)
          y, index = 0, 0
          while(y < height) do
            x = 0
            while(x < width) do
              #p self[index]
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
          x_step, y_step = @frame['axis_scale.x_step'], @frame['axis_scale.y_step']
          ratio = x_step / y_step
          if x_step < y_step
            @frame['maindata.width'] * ratio
          else
            @frame['maindata.width']
          end
        end

        def calculate_height
          x_step, y_step = @frame['axis_scale.x_step'], @frame['axis_scale.y_step']
          ratio = x_step / y_step
          if x_step > y_step
            @frame['maindata.height'] * ratio
          else
            @frame['maindata.height']
          end
        end      

        def init
          @data = raw.unpack("v*").collect do |value|
            value -= 0x1_0000 if (value & 0x8000).nonzero?
            value
          end
          max, min = @data.max, @data.min
          max_minus_min = max - min
          @init = true
          @data.collect! do |value|
            (((value - min) * 256) / max_minus_min).round
          end
        end

        def init?
          @init ||= false
        end
      end
    end
  end
end