require "test/unit"
require 'simplerdb/query_language'
require 'simplerdb/db'

# Tests the query evaluator
class QueryEvaluatorTest < Test::Unit::TestCase
  include SimplerDB
  
  def setup
    @db = DB.instance
    @db.create_domain("test")
  end
  
  def teardown
    @db.reset
  end
  
  def test_single_predicate
    bulk_insert('i1' => [["a1", "v1"], ["a2", "v2"], ["a3", "bcd"]],
                'i2' => [["a1", "vv1"]])
    
    assert_items 'i1', @db.query("test", "['a1' = 'v1']")
    assert_items 'i1', @db.query("test", "['a1' != 'v2']")
    assert_items 'i1', @db.query("test", "['a1' >= 'v1']")
    assert_items 'i1', @db.query("test", "['a1' <= 'v1']")
    assert_items 'i1', @db.query("test", "['a3' starts-with 'bc']")
    assert_items 'i1', @db.query("test", "['a3' > 'cde']")
    assert_items 'i1', @db.query("test", "['a3' < 'abc']")
    assert_items ['i1', 'i2'], @db.query("test", "['a1' = 'v1' or 'a1' = 'vv1']")
    assert_items ['i1', 'i2'], @db.query("test", "['a1' <= 'v1']")
    
    assert_empty @db.query("test", "['a2' != 'v2']")
    assert_empty @db.query("test", "['a2' > 'v2']")
    assert_empty @db.query("test", "['a2' = 'v1']")
    assert_empty @db.query("testxxxxx", "['a2' = 'v2']")
    assert_empty @db.query("test", "['a2' = 'v1']")
  end
  
  def test_ops
    
  end
  
  def bulk_insert(items)
    items.each do |name, attrs|
      params = []
      for attr in attrs
        params << AttributeParam.new(attr[0], attr[1])
      end
      
      @db.put_attributes("test", name, params)
    end
  end
  
  def assert_empty(results)
    assert results[0].empty?
  end
  
  def assert_items(items, results)
    results = results[0]
    for item in items
      found = false
      for result in results
        if result.name == item
          found = true
          break
        end
      end
      
      assert found, "Missing item #{item}"
    end
  end
  
end