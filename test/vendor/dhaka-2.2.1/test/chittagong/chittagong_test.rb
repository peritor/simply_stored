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
require File.dirname(__FILE__) + "/chittagong_evaluator"

class TestChittagong < Test::Unit::TestCase
  
  def fact(n)
    return 1 if n==1
    n * fact(n-1)
  end
  
  def program_output program
    output_stream = []
    parse_result = ChittagongParser.parse(ChittagongLexer.lex(program))
    result = ChittagongEvaluator.new([{}], output_stream).evaluate(parse_result)
    return result, output_stream
  end
  
  def test_iterative_fibonacci_without_functions
    program = "

    n = 1
    a = 0
    b = 1
    while n < 10
      print b
      c = a
      a = b
      b = c + b
      n = n + 1
    end
    
    "

    result, output_stream = program_output(program)
    assert_equal(["1.0", "1.0", "2.0", "3.0", "5.0", "8.0", "13.0", "21.0", "34.0"], output_stream)
  end

  def test_iterative_fibonacci_with_functions
    program = "

    def fib(n)
      i = 0
      a = 0
      b = 1
      while i < n
        c = a
        a = b
        b = c + b
        i = i + 1
      end
      return b
    end
    
    x = 0
    while x < 9
      print fib(x)
      x = x + 1
    end
    
    "
    result, output_stream = program_output(program)
    assert_equal(["1.0", "1.0", "2.0", "3.0", "5.0", "8.0", "13.0", "21.0", "34.0"], output_stream)
  end
  
  def test_recursive_factorial
    program = "
    def fact(n)
      if n == 1 
        return 1
      end
      return n * fact(n-1)
    end

    n = 1
    while n < 11
      print fact(n)
      n = n+1
    end"
    
    result, output_stream = program_output(program)
    assert_equal((1..10).collect {|i| fact(i).to_f.to_s}, output_stream)
  end
  
  def test_various_things
    program = "
    
    a = 1
    b = 2
    c = 3
    
    def foo(a, b, c)
      print a
      print b
      print c
      return c
      print 999
    end
    
    foo(4, a, 6)
    
    "
   
    result, output_stream = program_output(program)
    assert_equal(["4.0", "1.0", "6.0"], output_stream)
  end
  
  def test_if_else_block
    program = "

    def foo(a, b)
      if a < b
        print 1
      else
        print 2
      end
    end

    foo(1, 2)
    foo(2, 1)

    "

    result, output_stream = program_output(program)
    assert_equal(["1.0", "2.0"], output_stream)
  end
  
  def test_no_arg_functions
    program = "

    def foo()
      print 1
      print 2
    end
    foo()

    "

    result, output_stream = program_output(program)
    assert_equal(["1.0", "2.0"], output_stream)
  end

  def test_decimal_numbers
    program = "
    print 0.2347 * 23.34
    a = 1.012
    b = 345.44
    c = 0.234
    print (a^b)/c
    def foo(a)
      print a
    end
    foo(3.4)
    "

    result, output_stream = program_output(program)
    assert_equal(["5.477898", "263.233029427781", "3.4"], output_stream)
  end

  
  
end
