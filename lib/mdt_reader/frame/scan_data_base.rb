require 'png'
module MdtReader
  class Frame
    class ScanDataBase < DataBase
      def size
        @size ||= @frame['maindata.width'] * @frame['maindata.height'] * unit_size
      end

      def to_png(palette=nil)
        palette ||= Palette.new(PNG::Color.new(255, 255, 0), PNG::Color.new(128, 0, 111), PNG::Color.new(0, 255, 28))
        width, height = @frame['maindata.width'], @frame['maindata.height']
        canvas = PNG::Canvas.new(width, height)
        index = 0
        0.upto(height - 1) do |y|
          0.upto(width - 1) do |x|
            color = palette[self[index]]
            canvas.[]=(x, y, color)
            index += 1
          end
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
    end
  end
end