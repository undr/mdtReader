module MdtReader
  class Palette
    def initialize(*args)
      @colors = args
      sectors = args.length - 1
      @last_sector = sectors - 1
      @sector_length = 256 / sectors
    end
    
    def [](index)
      sector = index >= 256 ? @last_sector : (index / @sector_length).floor
      offset = index - (sector * @sector_length)
      r = self.class.calculate(@colors[sector].r, @colors[sector + 1].r, offset, @sector_length)
      g = self.class.calculate(@colors[sector].g, @colors[sector + 1].g, offset, @sector_length)
      b = self.class.calculate(@colors[sector].b, @colors[sector + 1].b, offset, @sector_length)
      PNG::Color.new(r, g, b)
    end
    
    def to_png(options)
      canvas = PNG::Canvas.new(256, 15)
      y = 0
      while(y < 15) do
        x = 0
        while(x < 256) do
          color = self[x]
          canvas.[]=(x, y, color)
          x += 1
        end
        y += 1
     end
  		PNG.new(canvas).save(options[:filename])
    end
    
    def self.calculate(start_color, end_color, index, length=256)
      start_color + (end_color - start_color) * (index.to_f / length);
    end
  end
end