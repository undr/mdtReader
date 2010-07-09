require 'gruff'
module MdtReader
  class Frame
    class SpectroscopyDataBase < DataBase
      include Rewindable
      def initialize(frame, offset, stream)
        super(frame, offset, stream)
        @normalize = false
      end
      
      def size
        @size ||= @frame['maindata.width'] * unit_size
      end
      
      def save_as_png(filename)
        init unless init?
        g = Gruff::Line.new('800x500') 
        g.theme = {
          :colors => %w(#002C3F),
          :marker_color => 'gray',
          :background_colors => %w(white #DEEAF0) 
        }
        g.x_axis_label = @frame['axis_scale.x_unit']
        g.y_axis_label = @frame['axis_scale.y_unit']
        name = @frame["name"]
        name = " " if !@frame["name"] || @frame["name"].empty?
        g.data(name, @data)
        g.labels = {0 => ' '}
        g.write(filename)
      end
    end
  end
end