require "rubygems"

require 'png'
require "mdt_reader/file"
require "mdt_reader/frame"
require "mdt_reader/palette"
require "ruby-debug"

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