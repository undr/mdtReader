module MdtReader
  class Frame
    class Mda < Frame
      CALIBRATION_PARAMS = {'axis_scale.x_offset' => {:index => 0, :method => :offset},
                            'axis_scale.y_offset' => {:index => 1, :method => :offset},
                            'axis_scale.z_offset' => {:index => 2, :method => :offset},
                            'axis_scale.x_step'   => {:index => 0, :method => :step},
                            'axis_scale.y_step'   => {:index => 1, :method => :step},
                            'axis_scale.z_step'   => {:index => 2, :method => :step},
                            'axis_scale.x_unit'   => {:index => 0, :method => :unit},
                            'axis_scale.y_unit'   => {:index => 1, :method => :unit},
                            'axis_scale.z_unit'   => {:index => 2, :method => :unit},
                            'maindata.width'      => {:index => 0, :method => :axis_size},
                            'maindata.height'     => {:index => 1, :method => :axis_size}
                }.freeze
      def type
        mda_header.type
      end
    
      def data
        offset = 0
        klass = MdtReader.const_get("#{type.to_s.capitalize}Data")
        klass.new(self, offset, stream)
      end
    
      protected
      def get_param(name)
        return get_calibration_param(name) if CALIBRATION_PARAMS.include?(name)
        return ex_mda_header.get_param(name) if ex_mda_header.param_exists?(name)
        return data.width if name == "image.width" && type == :scan
        return data.height if name == "image.height" && type == :scan
        nil
      end
    
      def get_calibration_param(name)
        return nil unless CALIBRATION_PARAMS.include?(name)
        calibration = calibrations[CALIBRATION_PARAMS[name][:index]]
        return calibration.send(CALIBRATION_PARAMS[name][:method]) if calibration
        nil
      end
    
      def ex_mda_header
        @ex_mda_header ||= ExMdaHeader.new(self, body_offset, @stream)
      end
    
      def mda_header
        @mda_header ||= MdaHeader.new(self, body_offset + ex_header.size, @stream)
      end
    
      def calibrations
        @calibrations ||= build_calibrations
      end
    
      def build_calibrations
        cals = type == :scan ? [:x, :y, :z] : [:x, :y]
        offset = body_offset + ex_mda_header.size + 8 + mda_header.size
        cals.collect do |c|
          c = Calibration.new(self, offset, @stream)
          offset += c.size
          c
        end
      end

      class ExMdaHeader < InternalBlock  
        build_field_method :structure_size, 0,  4, "e"
        build_field_method :size,           4,  4, "e"
        build_field_method :name_size,      44, 4, "e"
        build_field_method :comment_size,   48, 4, "e"
        build_field_method :data_offset,    68, 4, "e"
        build_field_method :data_size,      72, 4, "e"

        MDTHEADER_VALUES = {:name => :name, :comment => :comment, :GUID => :guid, :mesGUID => :mes_guid}.freeze
      
        def param_exists?(name)
          MDTHEADER_VALUES.include?(name)
        end

        def get_param(name)
          if MDTHEADER_VALUES.include?(name)
            send(MDTHEADER_VALUES[name])
          end
        end
      
        def guid
          @guid ||= Guid.new(rewind_to(8).read(16).unpack(""))
        end

        def mes_guid
          @mes_guid ||= Guid.new(rewind_to(24).read(16).unpack(""))
        end
      
        def name
          size = name_size
          @name ||= rewind_to(structure_size).read(size)
        end
      
        def comment
          size = comment_size
          pos = name_size + structure_size
          @comment ||= rewind_to(pos).read(size)
        end
      end
    
      class MdaHeader < InternalBlock
        build_field_method :total_size,           0,  4, "e"
        build_field_method :size,                 4,  4, "e"
        build_field_method :measurands_data,      8,  8, "" # Исправить
        build_field_method :measurands_data_size, 16, 4, "e"
        build_field_method :dimensions_count,     20, 4, "e"
        build_field_method :measurands_count,     24, 4, "e"

        def type
          if dimensions_count == 1 && measurands_count == 1
            :spectroscopy
          elsif dimensions_count == 2 && measurands_count == 1
            :scan
          else
            :unknown
          end
        end
      end
    
      class Calibration < InternalBlock
        build_field_method :name,      24, 4, "e"
        build_field_method :unit_name, 24, 4, "e"
        build_field_method :offset,    24, 4, "e"
        build_field_method :step,      24, 4, "e"
        build_field_method :min_index, 24, 4, "e"
        build_field_method :max_index, 24, 4, "e"
        build_field_method :data_type, 24, 4, "e"

        def axis_size
          @axis_size ||= (max_index - min_index)
        end
      end
      
      class Data < ScanData
        protected
        def raw_size
          
        end
        
        def unpack
          
        end
      end
    end
  end
end