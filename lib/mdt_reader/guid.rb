module MdtReader
  class Guid
    def initialize(bytes)
      raise ArgumentError, "Invalid GUID raw bytes, length must be 16 bytes" unless bytes.length == 16
      @bytes = bytes
    end
    
    def hexdigest
      @bytes.unpack("h*").first
    end

    def to_s
      @bytes.unpack("h8 h4 h4 h4 h12").join "-"
    end

    def inspect
      to_s
    end

    def raw
      @bytes
    end

    def self.from_s(s)
      raise ArgumentError, "Invalid GUID hexstring" unless s =~ /\A[0-9a-f]{8}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{12}\z/i
      Guid.new([s.gsub(/[^0-9a-f]+/i, '')].pack("h*"))
    end

    def ==(other)
      @bytes == other.raw
    end
  end
end