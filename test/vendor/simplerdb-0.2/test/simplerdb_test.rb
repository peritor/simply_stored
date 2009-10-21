require "test/unit"
require 'simplerdb/db'

class SimplerDBTest < Test::Unit::TestCase
  include SimplerDB
  
  def setup
    @db = DB.instance
  end
  
  def teardown
    @db.reset
  end
  
  def test_create_list_domains
    %w| a b c c c |.each { |d| @db.create_domain(d) }
    assert @db.list_domains[0].size == 3
    
    domains,token = @db.list_domains(1)
    assert domains.size == 1
    assert token == 1
    
    domains,token = @db.list_domains(1, 1)
    assert domains.size == 1
    assert token == 2
    
    domains,token = @db.list_domains(10,2)
    assert domains.size == 1
    assert token.nil?
  end
  
  def test_delete_domain
     %w| a b c |.each { |d| @db.create_domain(d) }
     @db.delete_domain('b')
     domains,token = @db.list_domains
     assert domains.size == 2
     assert domains[0] == 'a' && domains[1] == 'c'
     
     @db.delete_domain('xxxxx')
     assert domains.size == 2
     assert domains[0] == 'a' && domains[1] == 'c'
  end
  
  def test_put_get_attributes
    @db.create_domain("test")
    
    attrs = [AttributeParam.new("a1", "v1"), AttributeParam.new("a1", "v2"), AttributeParam.new("a2", "v1")]
    @db.put_attributes("test", "item1", attrs)
    assert @db.get_attributes("test", "item1").size == 3
    assert @db.get_attributes("test", "item1", "a2").size == 1
    assert @db.get_attributes("test", "item1", "a1").size == 2
    
    attrs = [AttributeParam.new("a1", "v3")]
    @db.put_attributes("test", "item1", attrs)
    assert @db.get_attributes("test", "item1", "a1").size == 3
    
    assert @db.get_attributes("test", "itemXXXXX", "a2").size == 0
    
    # Replacement
    attrs = [AttributeParam.new("a1", "v1"), AttributeParam.new("a1", "v2"), AttributeParam.new("a1", "v3")]
    @db.put_attributes("test", "item_repl", attrs)
    assert @db.get_attributes("test", "item_repl", "a1").size == 3
    attrs = [AttributeParam.new("a1", "v4", true)]
    @db.put_attributes("test", "item_repl", attrs)
    assert @db.get_attributes("test", "item_repl", "a1").size == 1
    @db.get_attributes("test", "item_repl", "a1")[0].value == "v4"
  end
  
  def test_delete_attributes
    @db.create_domain("test")
    
    attrs = [AttributeParam.new("a1", "v1"), AttributeParam.new("a1", "v2"), AttributeParam.new("a2", "v1")]
    @db.put_attributes("test", "item1", attrs)
    @db.delete_attributes("test", "item1", [AttributeParam.new("a1", "v1")])
    assert @db.get_attributes("test", "item1").size == 2
    @db.delete_attributes("test", "item1", [AttributeParam.new("a1", "v1")])
    assert @db.get_attributes("test", "item1").size == 2
  end
  
end