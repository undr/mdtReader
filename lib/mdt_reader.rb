require "rubygems"

require 'png'
require "mdt_reader/file"
require "mdt_reader/frame/rewindable"
require "mdt_reader/frame/internal_block"
require "mdt_reader/frame/scan_data"
require "mdt_reader/frame"
require "mdt_reader/frame/scan_and_spectroscopy"
require "mdt_reader/frame/scan"
require "mdt_reader/frame/spectroscopy"
require "mdt_reader/frame/mda"
require "mdt_reader/frame/curves"
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