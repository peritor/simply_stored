require 'rake'
require 'rake/testtask'
require 'rubygems'
require 'hoe'
require './lib/simplerdb.rb'

  
task :default => [:test]

class Hoe
  def extra_deps
    @extra_deps.reject! do |x|
      Array(x).first == 'hoe'
    end
    @extra_deps
  end
end

Hoe.new('simplerdb', SimplerDB::VERSION) do |p|
  p.rubyforge_name = 'simplerdb'
  p.author = 'Gary Elliott'
  p.email = 'gary@tourb.us'
  p.summary = "Test your SimpleDB application offline"
  p.description = p.summary
  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.remote_rdoc_dir = '' # Release to root
  p.version = SimplerDB::VERSION
  p.extra_deps << ['dhaka', '>= 2.2.1']
  p.extra_deps << ['builder', '>= 2.0']
end


Rake::TestTask.new do |t|
  t.libs << "lib"
  t.test_files = FileList['test/*test.rb']
  t.verbose = true
end