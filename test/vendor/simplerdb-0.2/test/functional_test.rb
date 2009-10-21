require "test/unit"
require 'rubygems'
require 'right_aws'
require 'simplerdb/server'

# Test the live, running service over HTTP
class FunctionalTest < Test::Unit::TestCase
  
  def setup
    @server = SimplerDB::Server.new(8087)
    @thread = Thread.new { @server.start }
    @sdb = RightAws::SdbInterface.new('access','secret',
                                     {:server => 'localhost', :port => 8087, :protocol => 'http'})

  end
  
  def teardown
    @server.shutdown
    @thread.join
  end
  
  def test_domains
    # Create/list domains
    @sdb.create_domain("d1")
    @sdb.create_domain("d2")
    result = @sdb.list_domains
    assert result[:domains].index("d1")
    assert result[:domains].index("d2")
    
    # List domains with paging
    domains = []
    count = 0
    @sdb.list_domains(1) do |result|
      domains += result[:domains]
      count += 1
      true
    end
    
    assert count == 2
    assert domains.index("d1")
    assert domains.index("d2")
  end
  
  def test_items
    # Create some bands with albums + genre
    @sdb.create_domain("bands")
    
    attrs = {:albums => ['Being There', 'Summer Teeth'], :genre => "rock"}
    @sdb.put_attributes("bands", "Wilco", attrs)
    
    attrs = {:albums => ['OK Computer', 'Kid A'], :genre => "alternative"}
    @sdb.put_attributes("bands", "Radiohead", attrs)
    
    attrs = {:albums => ['The Soft Bulletin'], :genre => "alternative"}
    @sdb.put_attributes("bands", "The Flaming Lips", attrs)
    
    # Read the attributes back
    results = @sdb.get_attributes("bands", "Wilco")
    assert results[:attributes]["albums"].sort == ['Being There', 'Summer Teeth']
    assert results[:attributes]["genre"] == ["rock"]
    
    # Query the bands domain
    results = @sdb.query("bands", "['genre' = 'alternative']")
    assert results[:items].sort == ["Radiohead", "The Flaming Lips"]
    
    results = @sdb.query("bands", "['albums' = 'Being There']")
    assert results[:items] == ["Wilco"]
    
    results = @sdb.query("bands", "['albums' starts-with 'OK' or 'albums' = 'The Soft Bulletin']")
    assert results[:items].sort == ["Radiohead", "The Flaming Lips"]
  
    # Modify and re-read attributes
    @sdb.put_attributes("bands", "The Flaming Lips", {:albums => "Yoshimi Battles the Pink Robots"})
    @sdb.put_attributes("bands", "The Flaming Lips", {:genre => "rock"}, :replace)
    
    results = @sdb.get_attributes("bands", "The Flaming Lips")
    assert results[:attributes]["albums"].sort == ["The Soft Bulletin", "Yoshimi Battles the Pink Robots"]
    assert results[:attributes]["genre"] == ["rock"]
  end
  
end