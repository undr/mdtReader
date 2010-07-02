module MdtReader
  module_function
  
  def open(file)
    f = MdtReader::File.new(file)
    if block_given?
      yield f
      f.close
    else
      f
    end
  end
end