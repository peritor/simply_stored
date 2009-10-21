# Exceptions that are caused by an invalid request from the client.
class ClientException < Exception
  attr_accessor :code, :msg
  
  def initialize(code, msg)
    @code = code
    @msg = msg
  end
  
end