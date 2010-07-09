module MdtReader
  class Frame
    class ScanAndSpectroscopy < Frame
      UNITS = {-10 => "1/cm",
               -5  => "m",
               -4  => "cm",       # Metric
               -3  => "mm",
               -2  => "um",
               -1  => "nm",
                0  => "Angstrom",
                2  => "nA",       # Voltage
                3  => "-",        # Dimensionless
                4  => "kHz",      # Frequency
                5  => "deg",      # Angle
                6  => "%",
                7  => "C",
                8  => "V",        # Voltage
                9  => "sec",      # Time
                10 => "ms",
                11 => "us",
                12 => "ns",
                13 => "Counts",   # Numbers
                14 => "Pixels",
                20 => "A",        # Current
                21 => "mA",
                22 => "uA",
                23 => "nA",
                24 => "pA",
                25 => "V",        # Voltage
                26 => "mV",
                27 => "uV",
                28 => "nV",
                29 => "pV",
                30 => "N",        # Force
                31 => "mN",
                32 => "uN",
                33 => "nN",
                34 => "pN"}
      def properties
        raise NotImplementedError, "it must be implemented in children classes"
      end
      
      def maindata
       raise NotImplementedError, "it must be implemented in children classes"
      end
      
      def axis_scale
        @axis_scale ||= AxisScale.new(self, body_offset, @stream)
      end
      
      def ex_header
        @ex_header ||= begin
          if header.h_ver0 > 6
            ExHeader.new(self, body_offset + header.vars_size + 8 + data.size, @stream)
          else
            Nothing.new
          end
        end
      end

      protected
      def get_param(name)  
        object_name, method = name.split(".")
        if self.class.method_defined?(object_name.downcase.to_sym)
          object = send(object_name.downcase.to_sym) 
          return nil unless !object || object.class.method_defined?(method.downcase.to_sym)
          return object.send(method.downcase.to_sym)
        end
        return ex_header.get_param(name) if ex_header.param_exists?(name)
        nil
      end
      class AxisScale < InternalBlock
        build_field_method :x_offset,       0,  4, "e"
        build_field_method :x_step,         4,  4, "e"
        build_field_method :x_unit_index,   8,  2, "v"
        build_field_method :y_offset,       10, 4, "e"
        build_field_method :y_step,         14, 4, "e"
        build_field_method :y_unit_index,   18, 2, "v"
        build_field_method :z_offset,       20, 4, "e"
        build_field_method :z_step,         24, 4, "e"
        build_field_method :z_unit_index,   28, 2, "v"
        
        def x_unit
          ::MdtReader::Frame::ScanAndSpectroscopy::UNITS[x_unit_index]
        end
        
        def y_unit
          ::MdtReader::Frame::ScanAndSpectroscopy::UNITS[y_unit_index]
        end
        
        def z_unit
          ::MdtReader::Frame::ScanAndSpectroscopy::UNITS[z_unit_index]
        end
      end
      class ExHeader < InternalBlock

        MDTHEADER_VALUES = {'name' => :name, 'comment' => :comment, 'GUID' => :guid, 'mesGUID' => :mes_guid}.freeze
        
        def param_exists?(name)
          MDTHEADER_VALUES.include?(name)
        end
        
        def get_param(name)
          if MDTHEADER_VALUES.include?(name)
            return send(MDTHEADER_VALUES[name])
          end
        end
        
        def name_size
          @name_size ||= rewind_to.read(4).unpack("l").first
        end
        
        def comment_size
          @comment_size ||= begin
            offset = name_size + 4
            rewind_to(offset).read(4).unpack("l").first
          end
        end
        
        def spec_size
          @spec_size ||= begin
            offset = name_size + comment_size + 8
            rewind_to(offset).read(4).unpack("l").first
          end
        end
        
        def view_info_size
          @view_info_size ||= begin
            offset = name_size + comment_size + spec_size + 12
            rewind_to(offset).read(4).unpack("l").first
          end
        end
        
        def source_info_size
          @source_info_size ||= begin
            offset = name_size + comment_size + spec_size + view_info_size + 16
            rewind_to(offset).read(4).unpack("l").first
          end
        end

        def guid
          @guid ||= begin
            guid_offset = name_size + comment_size + spec_size + view_info_size + source_info_size + 24
            Guid.new(rewind_to(guid_offset).read(16).unpack("LSSC*"))
          end
        end

        def mes_guid
          @mes_guid ||= begin
            guid_offset = name_size + comment_size + spec_size + view_info_size + source_info_size + 40
            Guid.new(rewind_to(guid_offset).read(16).unpack("LSSC*"))
          end
        end
      
        def name
          @name ||= begin
            size = name_size 
            rewind_to(4).read(size)
          end
        end
      
        def comment
          @comment ||= begin
            size = comment_size
            pos = name_size + 8
            Iconv.conv("", "utf-16", rewind_to(pos).read(size))
          end
        end
      end
      
      class Nothing
        def method_misssing(method, args)
          nil
        end
      end
    end
  end
end