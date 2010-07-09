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
      
      class Data < ScanDataBase

      end
    end
  end
end