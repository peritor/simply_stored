require File.dirname(__FILE__) + '/../dhaka_test_helper'
require File.dirname(__FILE__) + "/chittagong_grammar"
require File.dirname(__FILE__) + "/chittagong_lexer_specification"
begin
  require File.dirname(__FILE__) + "/chittagong_parser"
  require File.dirname(__FILE__) + "/chittagong_lexer"
rescue LoadError
  puts "Please run the rake command in the root folder to generate the lexer and parser required for this test."
  exit
end
require File.dirname(__FILE__) + "/chittagong_driver"

class TestChittagongDriver < Test::Unit::TestCase
  def setup
    @driver = ChittagongDriver.new
  end
  
  def test_return_statement_not_allowed_in_main
    # Programs with problems
    program = "

    if 1 > 2
      return 5
    end

    print 2
    "
    assert_equal(
    "Unexpected token return:


    if 1 > 2
      >>>return 5
    end

    print 2
    ", @driver.run(program))
  end
  
  def test_catches_unexpected_end_of_input
    program = "
      def"
    assert_equal("Unexpected end of file.", @driver.run(program))
  end
  
  def test_catches_unexpected_characters
    program = "
      print 2
      def #}
        "
    assert_equal(
    "Unexpected character #:

      print 2
      def >>>#}
        ", @driver.run(program))
  end
  
  def test_catches_undefined_variables
    program = "
      x = 1
      y = 2
      def foo(n)
        return 2
      end
      foo(1)
      
      if x > y
        print 999
        print 777
      else
        print 66
      end
      
      print x
      print y
      print 2*3+c
      print 888
      
    "

    assert_equal(
    "66.0
1.0
2.0
Undefined variable c:

      x = 1
      y = 2
      def foo(n)
        return 2
      end
      foo(1)
      
      if x > y
        print 999
        print 777
      else
        print 66
      end
      
      print x
      print y
      print 2*3+>>>c
      print 888
      
    ", @driver.run(program))
  end

  def test_catches_undefined_functions
    program = "

      def foo(n)
        bar(x)
      end
      
      foo(2)
      
    "
    assert_equal(
    "Undefined function bar:


      def foo(n)
        >>>bar(x)
      end
      
      foo(2)
      
    ", @driver.run(program))
  end
  # lipi:variable_scoping
  def test_variable_scope
    program = "
      x = 1
      
      def bar(n)
        print 999
      end
      
      def foo(n)
        bar(x)
      end
      
      foo(2)
      
    "
    assert_equal(
    "Undefined variable x:

      x = 1
      
      def bar(n)
        print 999
      end
      
      def foo(n)
        bar(>>>x)
      end
      
      foo(2)
      
    ", @driver.run(program))
  end
  # lipi:variable_scoping
  
  def test_nested_function_calls
    
    program = "
    
    def foo(a)
      return a + 2
    end
    
    def bar(b, c)
      return b + c
    end
    
    def baz(x, y, z)
      return foo(y) + bar(x, z)
    end
    
    print baz(foo(1), bar(2, 3), bar(6, 2))
    
    "
    assert_equal("18.0", @driver.run(program))
  end
  
  def test_wrong_number_of_arguments
    
    program = "
    
    def whatever(a, b)
      return a + b
    end
    
    whatever(1, 2, 3)
    
    "
    assert_equal(
    "Wrong number of arguments:

    
    def whatever(a, b)
      return a + b
    end
    
    whatever>>>(1, 2, 3)
    
    ", @driver.run(program))
    
  end

  def test_an_empty_program
    program = ""
    assert_equal("Unexpected end of file.", @driver.run(program))
  end

  def test_associating_equality_tests_should_show_an_error
    program = "
    def foo()
      print 999
    end

    foo()
    print 1 == 1 == 1"
    
    assert_equal("Unexpected token ==:

    def foo()
      print 999
    end

    foo()
    print 1 == 1 >>>== 1",  @driver.run(program))
  end

  def test_catches_bad_decimal_points
    program = "
    a = .234
    c = 23.523
    b = 20..2
    "
    
    assert_equal("Unexpected character .:

    a = .234
    c = 23.523
    b = 20.>>>.2
    ",  @driver.run(program))
  end
  # lipi:recursive_fib
  def test_recursive_fibonacci
    program = "

    def fib(n)
      if n == 0
        return 1
      end
      if n == 1
        return 1
      end
      return fib(n-1) + fib(n-2)
    end
    
    x = 0
    while x < 9
      print fib(x)
      x = x + 1
    end
    
    "
    assert_equal(["1.0", "1.0", "2.0", "3.0", "5.0", "8.0", "13.0", "21.0", "34.0"].join("\n"), @driver.run(program))
  end
  # lipi:recursive_fib
end
