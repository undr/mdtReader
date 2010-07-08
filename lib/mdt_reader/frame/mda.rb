module MdtReader
  class Frame
    class Mda < Frame
      CALIBRATION_PARAMS = {'axis_scale.x_offset' => {:index => 0, :method => :offset},
                            'axis_scale.y_offset' => {:index => 1, :method => :offset},
                            'axis_scale.z_offset' => {:index => 2, :method => :offset},
                            'axis_scale.x_step'   => {:index => 0, :method => :step},
                            'axis_scale.y_step'   => {:index => 1, :method => :step},
                            'axis_scale.z_step'   => {:index => 2, :method => :step},
                            'axis_scale.x_unit'   => {:index => 0, :method => :unit_name},
                            'axis_scale.y_unit'   => {:index => 1, :method => :unit_name},
                            'axis_scale.z_unit'   => {:index => 2, :method => :unit_name},
                            'maindata.width'      => {:index => 0, :method => :axis_size},
                            'maindata.height'     => {:index => 1, :method => :axis_size}
                }.freeze
      DATATYPES = {-1 => {:size => 1, :type => "c"},
                   1  => {:size => 1, :type => "C"},
                   -2 => {:size => 2, :type => "s"},
                   2  => {:size => 2, :type => "S"},
                   -4 => {:size => 4, :type => "l"},
                   4  => {:size => 4, :type => "L"},
                   -8 => {:size => 8, :type => "Q"},
                   8  => {:size => 8, :type => "q"},
                   }.freeze          
      
      def type
        mda_header.type
      end
    
      def data
        #klass = MdtReader.const_get("#{type.to_s.capitalize}Data")
        #klass.new(self, body_offset + data_offset, @stream, DATATYPES[measurand.data_type])
        Data.new(self, body_offset + data_offset, @stream, DATATYPES[measurand.data_type])
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
        p body_offset + ex_mda_header.size
        @mda_header ||= MdaHeader.new(self, body_offset + ex_mda_header.size, @stream)
      end
    
      def calibrations
        @calibrations ||= build_calibrations
      end
      
      def measurand
         type == :scan ? calibrations[2] : calibrations[1]
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
        build_field_method :structure_size,   0,  4, "l" #int
        build_field_method :all_headers_size, 4,  4, "l" #int
        build_field_method :name_size,        44, 4, "l" #int
        build_field_method :comment_size,     48, 4, "l" #int
        build_field_method :spec_size,        52, 4, "l" #int
        build_field_method :view_info_size,   56, 4, "l" #int
        build_field_method :source_info_size, 60, 4, "l" #int
        build_field_method :var_size,         64, 4, "l" #int
        build_field_method :data_offset,      68, 4, "l" #int
        build_field_method :data_size,        72, 4, "l" #int

        MDTHEADER_VALUES = {:name => :name, :comment => :comment, :GUID => :guid, :mesGUID => :mes_guid}.freeze
      
        def param_exists?(name)
          MDTHEADER_VALUES.include?(name)
        end
        
        def size
          structure_size + name_size + comment_size + spec_size + view_info_size + source_info_size + var_size
        end
        
        def get_param(name)
          if MDTHEADER_VALUES.include?(name)
            send(MDTHEADER_VALUES[name])
          end
        end
      
        def guid
          @guid ||= Guid.new(rewind_to(8).read(16).unpack("LSSC*"))
        end

        def mes_guid
          @mes_guid ||= Guid.new(rewind_to(24).read(16).unpack("LSSC*"))
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
        build_field_method :total_size,           0,  4, "L"
        build_field_method :size,                 4,  4, "L"
        build_field_method :measurands_data,      8,  8, "q"
        build_field_method :measurands_data_size, 16, 4, "l"
        build_field_method :dimensions_count,     20, 4, "l"
        build_field_method :measurands_count,     24, 4, "l"
        
        def type
          p "dimensions_count = #{dimensions_count}"
          p "measurands_count = #{measurands_count}"
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
        build_field_method :structure_size, 4,  4, "l"
        build_field_method :name_size,      8,  4, "l"
        build_field_method :comment_size,   12, 4, "l"
        build_field_method :unit_name_size, 16, 4, "l"
        build_field_method :offset,         44, 8, "d"
        build_field_method :step,           52, 8, "d" 
        build_field_method :min_index,      60, 8, "q"
        build_field_method :max_index,      68, 8, "q"
        build_field_method :data_type,      76, 4, "l"

        def axis_size
          @axis_size ||= (max_index - min_index)
        end
        
        def name
          @name ||= rewind_to(structure_size).read(name_size)
        end
        
        def unit_name
          @unit_name ||= rewind_to(structure_size + name_size + comment_size).read(unit_name_size)
        end
      end
      
      class Data < ScanData
        def initialize(frame, offset, stream, datatype=nil)
          super(frame, offset, stream)
          @datatype = {:size => 2, :type => "s"}
          @datatype = datatype if datatype
        end
        
        protected
        def raw_size
          @datatype[:size]
        end
        
        def unpack
          raw.unpack("#{@datatype[:type]}*")
        end
      end
    end
  end
end