<b>simplerdb</b>
    by Gary Elliott (gary@tourb.us)
    http://simplerdb.rubyforge.org

== DESCRIPTION:
  
SimplerDB is an in-memory implementation of Amazon's SimpleDB REST API.
You can use it to test your application offline (for free!) or experiment with SimpleDB
without a beta account.

== FEATURES:
  
* Implements the current SimpleDB API specification as defined by http://docs.amazonwebservices.com/AmazonSimpleDB/2007-11-07/DeveloperGuide.
* Start/stop a server from within your ruby unit tests
* Run a standalone server for use by any SimpleDB client

== SYNOPSIS:

In order to use SimplerDB, you will need to replace Amazon's service url (http://sds.amazonaws.com)
with http://localhost:8087 in your client. RightAWS[http://rightaws.rubyforge.org/right_aws_gem_doc]
is the only ruby client I'm aware of that lets you do this.

To write a ruby-based unit test using SimplerDB, you can use the following setup/teardown methods to
start and stop the server for each test.

  def setup
    @server = SimplerDB::Server.new(8087)
    @thread = Thread.new { @server.start }
  end
  
  def teardown
    @server.shutdown
    @thread.join
  end

You will need to configure your SimpleDB client to point to http://localhost:8087 for the test,
but otherwise your code will work just as if it was accessing Amazon's live web service.

For a more complete example of a functional test using RightAWS take a look at
http://simplerdb.rubyforge.org/svn/trunk/test/functional_test.rb

Installed with the gem is the <tt>simplerdb</tt> command, which starts a standalone SimplerDB server.
The optional command-line argument allows you to set HTTP port (8087 by default).

== REQUIREMENTS:

* Dhaka[http://dhaka.rubyforge.org]
* Builder[http://builder.rubyforge.org]

== INSTALL:

* <tt>sudo gem install simplerdb</tt>

== CAVEATS:

* Since I don't have a SimplerDB beta account this software has not been tested in comparsion to the live web service and the behavior might differ. If you discover such a scenario please report it as a bug.
* SimplerDB has only been tested with ruby SimpleDB clients. 
* Query performance with large numbers of items (more than 1000) in a domain could be poor. 