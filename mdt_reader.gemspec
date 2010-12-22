# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "mdt_reader/version"

Gem::Specification.new do |s|
  s.name        = "mdt_reader"
  s.version     = MdtReader::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Andrey Lepeshkin"]
  s.email       = ["lilipoper@gmail.com"]
  s.summary     = "Reader MDT files."
  s.description = "Reader MDT files."

  s.required_rubygems_version = ">= 1.3.6"
  s.add_dependency('png', '>= 1.2.0')
  s.add_dependency('RubyInline', '>= 3.8.6')
  s.add_dependency('libxml-ruby', '>= 1.1.4')
  s.add_dependency('gruff', '>= 0.3.6')
  
  s.add_development_dependency(%q<rspec>, ["= 1.3.0"])
  s.add_development_dependency(%q<mocha>, ["= 0.9.8"])

  s.files        = Dir.glob("lib/**/*")
  s.require_path = 'lib'
end