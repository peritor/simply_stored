require 'rubygems'
require 'simplerdb/servlet'
require 'webrick'

# Runs the SimplerDB server
module SimplerDB
  class Server
    
    # Create the server running on the given port
    def initialize(port = nil)
      @port = port || 8087
    end
    
    # Run the server on the configured port.
    def start
      config = { :Port => @port, :AccessLog => [] }
      @server = WEBrick::HTTPServer.new(config)
      @server.mount("/", SimplerDB::RESTServlet)
      
      ['INT', 'TERM'].each do |signal| 
        trap(signal) { @server.shutdown }
      end
      
      @server.start
    end
  
    # Shut down the server
    def shutdown
      @server.shutdown
    end
    
  end
end