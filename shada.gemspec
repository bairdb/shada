require 'rubygems'
require 'rubygems/package_task'

Gem::Specification.new do |s|
  s.name = 'shada'
  s.version = '0.0.1'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README', 'LICENSE']
  s.summary = 'Web Framework'
  s.description = ''    
  s.author = 'Lackner//Buckingham LLC'
  s.email = ''
  # s.executables = ['your_executable_here']
  s.files = %w(LICENSE README Rakefile) + Dir.glob("{bin,lib,spec}/**/*")
  s.require_path = "lib"
  s.bindir = "bin"
end