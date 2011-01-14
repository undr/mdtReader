require "rubygems"

require "mdt_reader/file"
require "mdt_reader/guid"
require "mdt_reader/frame/rewindable"
require "mdt_reader/frame/internal_block"
require "mdt_reader/frame/data_base"
require "mdt_reader/frame/scan_data_base"
require "mdt_reader/frame/spectroscopy_data_base"
require "mdt_reader/frame"
require "mdt_reader/frame/scan_and_spectroscopy"
require "mdt_reader/frame/scan"
require "mdt_reader/frame/spectroscopy"
require "mdt_reader/frame/mda"
require "mdt_reader/frame/curves"
require "mdt_reader/palette"
require "mdt_reader/histogramm"


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
  
  def little_endian?
    [255].pack("S").unpack("v").first == 255
  end
  class NotImplementedError < ::NotImplementedError;end
end

unless MdtReader.little_endian?
  raise StandardError, "Only systems with little-endian byte order have been supported"
end