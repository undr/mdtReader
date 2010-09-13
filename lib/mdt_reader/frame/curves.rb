module MdtReader
  class Frame
    class Curves < ScanAndSpectroscopy

      def type
        :curves
      end  

      def method_misssing(method, args)
        raise ::MdtReader::NotImplementedError, "Type :curves is not allowed"
      end
      
    end
  end
end