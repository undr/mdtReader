module MdtReader
  class Frame
    module Rewindable
      def rewind_to(pos=0)
        @stream.seek(@offset + pos, IO::SEEK_SET)
        @stream
      end
    end
  end
end