module MdtReader
  class Frame
    class Spectroscopy < ScanAndSpectroscopy
      def initialize(offset, stream)
        super(offset, stream)
        raise ::MdtReader::NotImplementedError, "Only one curve per frame has been allowed" unless get_param('maindata.mode') == 0
      end
      
      def type
        :spectroscopy
      end

      def data
        @data ||= Data.new(self, body_offset + header.vars_size + 8, @stream)
      end
      
      protected
      def properties
        @properties ||= Properties.new(self, body_offset + 30, @stream)
      end
      
      def maindata
        @maindata ||= Maindata.new(self, body_offset + header.vars_size, @stream)
      end
      
      class Properties < InternalBlock
        
      end
      
      class Maindata < InternalBlock
        build_field_method :mode,   0, 2, "v"
        build_field_method :width,  2, 2, "v"
        build_field_method :height, 4, 2, "v"  
        build_field_method :points, 6, 2, "v"
      end
      
      class Data < SpectroscopyDataBase
        
      end
    end
  end
end