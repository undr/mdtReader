module MdtReader
  class Frame
    class InternalBlock
      include Rewindable
      
      class << self
        def build_field_method(name, offset, size, type)
          class_eval <<-METHOD
            def #{name}
              @#{name} ||= rewind_to(#{offset}).read(#{size}).unpack('#{type}').first
            end
          METHOD
        end
      end
      
      def initialize(frame, offset, stream)
        @offset, @frame, @stream = offset, frame, stream
      end
    end
  end
end