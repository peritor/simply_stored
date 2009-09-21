require 'rake'
require 'rake/testtask'

desc "Unit tests"
Rake::TestTask.new(:test) do |t|
  t.libs << 'test/'
  t.pattern = "test/*_test.rb"
  t.verbose = true
end
