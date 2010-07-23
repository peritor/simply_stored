require 'rake'
require 'rake/testtask'
require File.dirname(__FILE__) + '/lib/simply_stored/rake'

task "default" => "test"

desc "Unit tests"
Rake::TestTask.new(:test) do |t|
  t.libs << 'test/'
  t.pattern = 'test/{couchdb,.}/*_test.rb'
  t.verbose = true
end

def name
  'simply_stored'
end

def source_version
  line = File.read("lib/#{name.gsub(/-/, "/")}.rb")[/^\s*VERSION\s*=\s*.*/]
  line.match(/.*VERSION\s*=\s*['"](.*)['"]/)[1]
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "simply_stored"
    s.summary = %Q{Convenience layer for CouchDB and SimpleDB}
    s.email = "info@peritor.com"
    s.homepage = "http://github.com/peritor/simply_stored"
    s.description = "Convenience layer for CouchDB and SimpleDB. Requires CouchPotato and RightAWS library respectively."
    s.authors = ["Mathias Meyer, Jonathan Weiss"]
    s.files = FileList["[A-Z]*.*", "{lib}/**/*"]
    s.add_dependency('rest-client', '>= 1.4.2')
    s.add_dependency('couch_potato', '>= 0.2.15')
    s.add_dependency('activesupport')
    s.add_dependency('mattmatt-validatable')
    s.version = source_version
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
