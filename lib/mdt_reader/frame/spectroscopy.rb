module MdtReader
  class Frame
    class Spectroscopy < ScanAndSpectroscopy
      def type
        :spectroscopy
      end

      def data

      end
      
      protected
      def get_param(name)
        param = super(name)
        return param if param
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
        build_field_method :mode,   0, 2, "v"
        build_field_method :width,  2, 2, "v"
        build_field_method :height, 4, 2, "v"  
        build_field_method :points, 6, 2, "v"
      end
    end
  end
end