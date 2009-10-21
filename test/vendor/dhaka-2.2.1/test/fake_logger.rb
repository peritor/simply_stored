class FakeLogger
  attr_reader :warnings, :debugs, :errors
  def initialize
    @warnings = []
    @debugs = []
    @errors = []
  end
  def debug message
    @debugs << message
  end
  def error message
    @errors << message
  end
  def warn message
    @warnings << message
  end
end