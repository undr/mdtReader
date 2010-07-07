module MdtReader
  class Frame
    class ScanAndSpectroscopy < Frame
      def properties
        raise NotImplementedError, "it must be implemented in children classes"
      end
      
      def maindata
       raise NotImplementedError, "it must be implemented in children classes"
      end
      
      def axis_scale
        @axis_scale ||= AxisScale.new(self, body_offset, @stream)
      end

      protected
      class AxisScale < InternalBlock
        build_field_method :x_offset, 0,  4, "e"
        build_field_method :x_step,   4,  4, "e"
        build_field_method :x_unit,   8,  2, "v"
        build_field_method :y_offset, 10, 4, "e"
        build_field_method :y_step,   14, 4, "e"
        build_field_method :y_unit,   18, 2, "v"
        build_field_method :z_offset, 20, 4, "e"
        build_field_method :z_step,   24, 4, "e"
        build_field_method :z_unit,   28, 2, "v"
      end
      
      def get_param(name)
        object_name, method = name.split(".")
        return nil unless self.class.method_defined?(object_name.downcase.to_sym)
        object = send(object_name.downcase.to_sym) 
        return nil unless !object || object.class.method_defined?(method.downcase.to_sym)
        object.send(method.downcase.to_sym)
      end
    end
  end
end