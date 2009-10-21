unless defined? Dhaka
  require File.dirname(__FILE__) + '/../lib/dhaka'
end

require File.dirname(__FILE__) + '/fake_logger'

require 'test/unit'

begin
  require 'mocha'
rescue LoadError
  puts "
  The tests depend on Mocha. Please install it if you wish to run them:
    sudo gem install mocha
  This gem is not required for using the library."
  exit
end
