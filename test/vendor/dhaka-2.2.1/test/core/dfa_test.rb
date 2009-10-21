require File.dirname(__FILE__) + '/../dhaka_test_helper'

class TestDFA < Test::Unit::TestCase
  def test_build_AST_from_parse_tree_and_compute_follow_first_and_last
    root      = Dhaka::LexerSupport::RegexParser.parse(Dhaka::LexerSupport::RegexTokenizer.tokenize("(a|b)*abb"))
    star_node = root.left.left.left.left
    or_node   = star_node.child
    first_a   = or_node.children[0]
    first_b   = or_node.children[1]
    second_a  = root.left.left.left.right
    second_b  = root.left.left.right
    last_b    = root.left.right
    sentinel  = root.right
  
    assert(!root.nullable)
    assert(!root.left.nullable)
    assert(!root.left.left.nullable)
    assert(star_node.nullable)
  
    assert_equal(Set.new([first_a, first_b, second_a]), root.first)
    assert_equal(Set.new([last_b]), root.left.last)
  
    root.calculate_follow_sets
  
    assert_equal(Set.new([first_a, first_b, second_a]), first_a.follow_set)
    assert_equal(Set.new([first_a, first_b, second_a]), first_b.follow_set)
    assert_equal(Set.new([second_b]), second_a.follow_set)
    assert_equal(Set.new([last_b]), second_b.follow_set)
    assert_equal(Set.new([sentinel]), last_b.follow_set)
  end

  def test_DFA_raises_exception_if_empty_regex
    machine = Dhaka::LexerSupport::DFA.new("")
    flunk "Should have thrown an unexpected end of regex exception"
  rescue Dhaka::LexerSupport::InvalidRegexException => e
    assert_equal("Unexpected end of regex.", e.message)
  end

  def test_DFA_raises_exception_if_error_parsing_regex
    machine = Dhaka::LexerSupport::DFA.new("(a|b)*+abb")
    flunk "Should have thrown an unexpected token exception"
  rescue Dhaka::LexerSupport::InvalidRegexException => e
    assert_equal("Unexpected token +: (a|b)*>>>+abb", e.message)
  end

  def test_match_a_regex
    machine = Dhaka::LexerSupport::DFA.new("(a|b)*abb")
    assert_full_match(machine, "abababb")
    assert_full_match(machine, "ababaabb")
    assert_empty(machine.match("abababab"))
    assert_equal("abababb", machine.match("abababbc"))
    assert_equal("abababb", machine.match("abababbaa"))
  end

  def test_match_a_regex_with_optional_characters_at_the_end
    machine = Dhaka::LexerSupport::DFA.new("bad(c|d)+(ab)*")
    assert_full_match(machine, "badccddabab")
    assert_full_match(machine, "baddcc")
    assert_empty(machine.match("badab"))
    assert_empty(machine.match("bacdab"))
  end

  def test_match_a_nullable_regex
    machine = Dhaka::LexerSupport::DFA.new("(ab)*")
    assert_full_match(machine, "abab")
    assert_full_match(machine, "ab")
    assert_full_match(machine, "")
    assert_equal("", machine.match("b"))
  end

  def test_match_a_regex_with_the_dot_character
    machine = Dhaka::LexerSupport::DFA.new("ab.*cd")
    assert_full_match(machine, "abacd")
    assert_full_match(machine, "abcd")
    assert_full_match(machine, "abAcd")
    assert_empty(machine.match("ab999c"))
  end

  def test_match_a_regex_with_sets
    machine = Dhaka::LexerSupport::DFA.new("ab[j-lu]*cd")
    assert_empty(machine.match("abacd"))
    assert_full_match(machine, "abcd")
    assert_full_match(machine, "abjklucd")
    assert_empty(machine.match("abijklucd"))
    assert_empty(machine.match("ab999c"))
  end

  def test_match_a_regex_with_negative_sets
    machine = Dhaka::LexerSupport::DFA.new("ab[^j-lr]*cd")
    assert_full_match(machine, "abcd")
    assert_empty(machine.match("abjcd"))
    assert_empty(machine.match("abrcd"))
    assert_empty(machine.match("abijklucd"))
    assert_full_match(machine, "abyqcd")
  end

  def test_match_a_regex_with_sets_containing_escaped_characters
    machine = Dhaka::LexerSupport::DFA.new("ab[\\^\\-.]*cd")
    assert_full_match(machine, "abcd")
    assert_empty(machine.match("abjcd"))
    assert_full_match(machine, "ab^-.cd")
    assert_empty(machine.match("abijklucd"))
    assert_empty(machine.match("ab\\cd"))
  end

  def test_match_a_regex_using_unescaped_caret_and_dash_characters
    machine = Dhaka::LexerSupport::DFA.new("(\\^-)+")
    assert_full_match(machine, "^-")
    assert_full_match(machine, "^-^-")
    assert_empty(machine.match("?cd"))
  end

  def test_match_a_regex_using_escape_characters
    machine = Dhaka::LexerSupport::DFA.new(%q/(-\?\(\)\\\\)*/)
    assert_full_match(machine, "-?()\\")
  end

  def test_match_a_regex_using_lt_and_gt
    machine = Dhaka::LexerSupport::DFA.new('<.+>')
    assert_full_match(machine, "<ab>")
    assert_full_match(machine, "<absdf><sdg><sse>")
    assert_empty(machine.match("ab>"))
  end

  def test_simulating_curly_brace_quantifiers
    machine = Dhaka::LexerSupport::DFA.new('aaa?a?a?')
    assert_full_match(machine, "aa")
    assert_full_match(machine, "aaa")
    assert_full_match(machine, "aaaa")
    assert_full_match(machine, "aaaaa")
    assert_equal("aaaaa", machine.match("aaaaaa"))
    assert_empty(machine.match("a"))
  end
  
  def test_matching_a_regex_with_lookahead
    machine = Dhaka::LexerSupport::DFA.new('ab/cd')
    assert_equal("ab", machine.match("abcd"))
    assert_empty(machine.match("ab"))
    assert_empty(machine.match("abef"))
  end
  
  def test_matching_a_regex_with_nullable_pre_lookahead_regex
    machine = Dhaka::LexerSupport::DFA.new('(ab)*/cd')
    assert_equal("ab", machine.match("abcd"))
    assert_equal("ababab", machine.match("abababcd"))
    assert_empty(machine.match("ababc"))
    assert_empty(machine.match("abef"))
  end

  def test_matching_a_regex_with_post_lookahead_characters_in_common_with_pre_lookahead_characters
    machine = Dhaka::LexerSupport::DFA.new('(ab)+/abcd')
    assert_equal("ababab", machine.match("abababcd"))
    assert_empty(machine.match("ab"))
    assert_empty(machine.match("abef"))
  end
  
  def test_machine_with_nullable_lookahead
    machine = Dhaka::LexerSupport::DFA.new(":/[aA\n\r\t]*")
    assert_equal(":", machine.match(":"))
  end
  
  private
    def assert_full_match(machine, input)
      assert_equal(input, machine.match(input))
    end
    
    def assert_empty(input)
      assert(input.empty?)
    end
end
