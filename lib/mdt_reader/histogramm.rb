require "pp"
module MdtReader
  class Histogramm
    MAX = 256
    def initialize(frame)
      @frame = frame
      @max = MAX
    end
    
    def histogramm
      @histogramm ||= data[:histogramm]
    end
    
    def standard_deviation
      @standard_deviation ||= data[:standard_deviation]
    end
    
    def correlation
      @correlation ||= data[:correlation]
    end
    
    def data
      @data ||= build
    end
    
    private
    def build
      size = @frame['maindata.height'] * @frame['maindata.width']
      hist = calculate(size)
      c = 1.to_f/@max
      hist = normalize(hist, size)
      {:histogramm => hist, :correlation => c, :standard_deviation => Math.sqrt(c * sum(hist, c))}
    end
    
    def normalize(d , elements_count)
      d.map{|i| i.to_f/elements_count }
    end
    
    def sum(d, correlation)
      d.reduce(0) do |sum, item|
        sum + ((item - correlation)**2)
      end
    end
  end
end

module MdtReader
  class Histogramm
    require 'inline'
    inline do |builder|
      builder.c <<-EOC
VALUE 
calculate(VALUE elements_count) {
  long elementsCountLong = NUM2LONG(elements_count);
  long max = NUM2LONG(rb_iv_get(self, "@max"));
  VALUE frame = rb_iv_get(self, "@frame");
  ID dataFunc = rb_intern("data");
  ID to_aFunc = rb_intern("to_a");
  VALUE data = rb_funcall(frame, dataFunc, 0);
  VALUE dataAray = rb_funcall(data, to_aFunc, 0);
  VALUE hist = rb_ary_new3(max);
  int i;
  VALUE nullValue = LONG2NUM(0);
  for(i = 0; i < max; i++) {
    RARRAY(hist)->ptr[i] = nullValue;
  }
  long hIndex;
  for(i = 0; i < elementsCountLong; i++) {
    VALUE value = RARRAY(dataAray)->ptr[i];
    hIndex = NUM2LONG(value);
    VALUE histValue = RARRAY(hist)->ptr[hIndex];
    RARRAY(hist)->ptr[hIndex] = LONG2NUM(NUM2LONG(histValue) + 1);
  }
  return hist;
}
EOC
    end
  rescue => e
    pp e
    def calculate(elements_count)
      image = @frame.data.to_a
      hist = Array.new(@max){0}
      0.upto(elements_count - 1) do |index|
        value = image[index]
        hist[value] += 1
      end
      hist
    end
  end
end
