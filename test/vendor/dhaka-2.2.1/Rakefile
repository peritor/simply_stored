require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/testtask'
require 'rubygems'

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_files.include('README', 'lib/**/*.rb')
  rdoc.rdoc_files.exclude("dhaka/lib/lexer/regex_parser.rb")
  rdoc.main = "README"
  rdoc.rdoc_dir = '../doc'
end

spec = Gem::Specification.new do |s|
  s.name = "dhaka"
  s.author = "Mushfeq Khan"
  s.email = "mushfeq dot khan at gmail dot com"
  s.version = ENV['VERSION'] || "0.0.0"
  s.platform = Gem::Platform::RUBY
  s.summary = "An LALR1 parser generator written in Ruby"
  s.files = Dir.glob("{lib,test}/**/*").select {|file| file.include?('.rb') || file.include?('.txt')} + ['Rakefile']
  s.require_path = 'lib'
  s.autorequire = 'dhaka'
  s.has_rdoc = true
end

Rake::GemPackageTask.new(spec) do |pkg|
	pkg.package_dir = "../gems"
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*test.rb']
  t.verbose = true
end

task :generate_regex_parser do
  require 'lib/dhaka'
  File.open('lib/dhaka/lexer/regex_parser.rb', 'w') do |file| 
    file << Dhaka::Parser.new(Dhaka::LexerSupport::RegexGrammar).compile_to_ruby_source_as('Dhaka::LexerSupport::RegexParser')
  end
end

task :gem => [:test, :generate_regex_parser]

task :default => :test

task :test => [:generate_chittagong_parser, :generate_chittagong_lexer]

task :generate_chittagong_parser do
  require 'lib/dhaka'
  require 'test/chittagong/chittagong_grammar'
  require 'test/fake_logger'
  File.open('test/chittagong/chittagong_parser.rb', 'w') do |file| 
    file << Dhaka::Parser.new(ChittagongGrammar, FakeLogger.new).compile_to_ruby_source_as(:ChittagongParser)
  end
end

task :generate_chittagong_lexer do
  require 'lib/dhaka'
  require 'test/chittagong/chittagong_lexer_specification'
  File.open('test/chittagong/chittagong_lexer.rb', 'w') do |file| 
    file << Dhaka::Lexer.new(ChittagongLexerSpecification).compile_to_ruby_source_as(:ChittagongLexer)
  end
end
