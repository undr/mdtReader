module MdtReader
  class Guid
    def initialize(bytes)
      raise ArgumentError, "Invalid GUID raw bytes, length must be 16 bytes" unless bytes.length == 11
      @bytes = bytes
    end
    
    def hexdigest
      @bytes.collect {|num| num.to_s(16) }.join
    end

    def to_s
      hexdigest
    end

    def inspect
      to_s
    end

    def raw
      @bytes
    end

    def ==(other)
      @bytes == other.raw
    end
  end
end