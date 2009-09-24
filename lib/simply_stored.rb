require 'couch_potato'

$:.unshift(File.expand_path(File.dirname(__FILE__) + "/lib"))
require File.expand_path(File.dirname(__FILE__) + '/simply_stored/instance_methods')
require File.expand_path(File.dirname(__FILE__) + '/simply_stored/storage')
require File.expand_path(File.dirname(__FILE__) + '/simply_stored/class_methods_base')
require File.expand_path(File.dirname(__FILE__) + '/simply_stored/couch')

module SimplyStored
  class Error < RuntimeError; end
  class RecordNotFound < RuntimeError; end
end