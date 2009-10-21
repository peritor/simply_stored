module Dhaka
  module LexerSupport #:nodoc:all

    class RegexGrammar < Dhaka::Grammar

      for_symbol(Dhaka::START_SYMBOL_NAME) do
        regex                         %w| Disjunction |                         do Dhaka::LexerSupport::RootNode.new(child_nodes[0], Dhaka::LexerSupport::AcceptingNode.new) end
        regex_with_lookahead          %w| Disjunction / Disjunction |           do Dhaka::LexerSupport::RootNode.new(Dhaka::LexerSupport::LookaheadNode.new(child_nodes[0], child_nodes[2]), Dhaka::LexerSupport::LookaheadAcceptingNode.new) end
      end
      
      for_symbol('Disjunction') do                                   
        disjunction                   %w| Alternative \| Disjunction |          do Dhaka::LexerSupport::OrNode.new(child_nodes[0], child_nodes[2]) end
        alternative                   %w| Alternative |                         do child_nodes[0] end
      end                                                   
                                                          
      for_symbol('Alternative') do                            
        concatenation                 %w| Alternative Term |                    do Dhaka::LexerSupport::CatNode.new(child_nodes[0], child_nodes[1]) end
        term                          %w| Term |                                do child_nodes[0] end
      end                                                   
                                                          
      for_symbol('Term') do                             
        zero_or_more                  %w| Atom * |                              do Dhaka::LexerSupport::ZeroOrMoreNode.new(child_nodes[0]) end
        one_or_more                   %w| Atom + |                              do Dhaka::LexerSupport::OneOrMoreNode.new(child_nodes[0]) end
        zero_or_one                   %w| Atom ? |                              do Dhaka::LexerSupport::ZeroOrOneNode.new(child_nodes[0]) end
        atom                          %w| Atom |                                do child_nodes[0] end
      end                                                   
                                                          
      for_symbol('Atom') do                        
        group                         %w| ( Disjunction ) |                     do child_nodes[1] end
        char                          %w| Character |                           do Dhaka::LexerSupport::LeafNode.new(child_nodes[0]) end 
        anything                      %w| . |                                   do Dhaka::LexerSupport::OrNode.new(*(Dhaka::LexerSupport::ALL_CHARACTERS - ["\r", "\n"]).collect {|char| Dhaka::LexerSupport::LeafNode.new(char)}) end
        positive_set                  %w| [ SetContents ] |                     do OrNode.new(*child_nodes[1].collect{|char| Dhaka::LexerSupport::LeafNode.new(char)}) end
        negative_set                  %w| [ ^ SetContents ] |                   do Dhaka::LexerSupport::OrNode.new(*(Dhaka::LexerSupport::ALL_CHARACTERS - child_nodes[2]).collect {|char| Dhaka::LexerSupport::LeafNode.new(char)}) end

        Dhaka::LexerSupport::CLASSES.each do |char, expansion|
          send("character_class_#{char}", ['\\', char]) do
            Dhaka::LexerSupport::OrNode.new(*Dhaka::LexerSupport::CLASSES[char].collect {|c| Dhaka::LexerSupport::LeafNode.new(c)})
          end 
        end

        Dhaka::LexerSupport::OPERATOR_CHARACTERS.each do |char, method_name|
          send(method_name, ['\\', char]) do
            Dhaka::LexerSupport::LeafNode.new(char)
          end
        end
      end
      
      for_symbol('Character') do
        letter_character              %w| Letter |                              do child_nodes[0] end
        digit_character               %w| Digit |                               do child_nodes[0] end  
        white_space_character         %w| Whitespace |                          do child_nodes[0] end
        symbol_character              %w| Symbol |                              do child_nodes[0] end
      end
      
      
      for_symbol('SetContents') do
        single_item                   %w| SetItem |                             do child_nodes[0] end
        multiple_items                %w| SetContents SetItem |                 do child_nodes[0].concat child_nodes[1] end
      end
    
      for_symbol('SetItem') do
        single_char_item              %w| SetCharacter |                        do [child_nodes[0]] end
        lower_case_letter_range       %w| LowercaseLetter - LowercaseLetter |   do (child_nodes[0]..child_nodes[2]).to_a end
        upper_case_letter_range       %w| UppercaseLetter - UppercaseLetter |   do (child_nodes[0]..child_nodes[2]).to_a end
        digit_range                   %w| Digit - Digit |                       do (child_nodes[0]..child_nodes[2]).to_a end
      end

      
      
      for_symbol('Letter') do
        lower_case_letter             %w| LowercaseLetter |                     do child_nodes[0] end
        upper_case_letter             %w| UppercaseLetter |                     do child_nodes[0] end
      end
      
      for_symbol('LowercaseLetter') do
        Dhaka::LexerSupport::LOWERCASE_LETTERS.each do |letter|
          send("lower_char_letter_#{letter}", letter) do
            letter
          end
        end
      end
      
      for_symbol('UppercaseLetter') do
        Dhaka::LexerSupport::UPPERCASE_LETTERS.each do |letter|
          send("upper_case_letter_#{letter}", letter) do
            letter
          end
        end
      end

      for_symbol('Digit') do
        Dhaka::LexerSupport::DIGITS.each do |digit|
          send("digit_#{digit}", digit) do
            digit
          end
        end
      end

      for_symbol('Whitespace') do
        Dhaka::LexerSupport::WHITESPACE.each do |whitespace_char|
          send("whitespace_#{to_byte(whitespace_char)}", whitespace_char) do
            whitespace_char
          end
        end
      end
      
      for_symbol('Symbol') do
        Dhaka::LexerSupport::SYMBOLS.each do |symbol_char|
          send("symbol_char_#{to_byte(symbol_char)}", symbol_char) do
            symbol_char
          end
        end
      end

      for_symbol('SetCharacter') do
        (Dhaka::LexerSupport::ALL_CHARACTERS - Dhaka::LexerSupport::SET_OPERATOR_CHARACTERS).each do |char|
          send("set_character_#{to_byte(char)}", char) do
            char
          end
        end
        Dhaka::LexerSupport::SET_OPERATOR_CHARACTERS.each do |char|
          send("set_operator_character_#{to_byte(char)}", ['\\', char]) do
            char
          end
        end
      end
    end
  
  
    class ASTNode
      def checkpoint
        false
      end
      
      def accepting
        false
      end
    end
  
    class BinaryNode < ASTNode
      attr_reader :left, :right
      def initialize left, right
        @left, @right = left, right
      end

      def to_dot(graph)
        graph.node(self, :label => label)
        graph.edge(self, left)
        graph.edge(self, right)
        left.to_dot(graph)
        right.to_dot(graph)
      end
    
      def calculate_follow_sets
        left.calculate_follow_sets
        right.calculate_follow_sets
      end
    end

    class OrNode < ASTNode
      attr_reader :children
      def initialize(*children)
        @children = children
      end
      def label
        "|"
      end

      def nullable
        children.any? {|child| child.nullable}
      end

      def first
        result = Set.new
        children.each do |child|
          result.merge child.first
        end
        result
      end
    
      def last
        result = Set.new
        children.each do |child|
          result.merge child.last
        end
        result
      end
    
      def to_dot(graph)
        graph.node(self, :label => label)
        children.each do |child|
          graph.edge(self, child)
          child.to_dot(graph)
        end
      end
    
      def calculate_follow_sets
        children.each do |child|
          child.calculate_follow_sets
        end
      end
    end
  
    class CatNode < BinaryNode
      def label
        "cat"
      end

      def nullable
        left.nullable && right.nullable
      end
    
      def first
        left.nullable ? (left.first | right.first) : left.first
      end
    
      def last
        right.nullable ? (left.last | right.last) : right.last
      end
    
      def calculate_follow_sets
        super
        left.last.each do |leaf_node|
          leaf_node.follow_set.merge right.first
        end
      end
    end

    class LookaheadNode < CatNode
      def label
        "/"
      end
      
      def calculate_follow_sets
        super
        left.last.each do |leaf_node|
          leaf_node.follow_set.merge(Set.new([CheckpointNode.new]))
        end
      end
    end
  
    class UnaryNode < ASTNode
      attr_reader :child
      def initialize child
        @child = child
      end

      def to_dot(graph)
        graph.node(self, :label => label)
        graph.edge(self, child)
        child.to_dot(graph)
      end

      def nullable
        child.nullable
      end

      def first
        child.first
      end

      def last
        child.last
      end
    
      def calculate_follow_sets
        child.calculate_follow_sets
      end
    end
  
    class RootNode < CatNode
      def label
        "start"
      end

      def head_node?
        true
      end
    end
  
    class ZeroOrMoreNode < UnaryNode
      def label
        "*"
      end

      def nullable
        true
      end
    
      def calculate_follow_sets
        super
        last.each do |leaf_node| 
          leaf_node.follow_set.merge first
        end
      end
    end
  
    class ZeroOrOneNode < UnaryNode
      def label
        "?"
      end
    
      def nullable
        true
      end
    end
  
    class OneOrMoreNode < UnaryNode
      def label
        "+"
      end
    
      def calculate_follow_sets
        super
        last.each do |leaf_node| 
          leaf_node.follow_set.merge first
        end
      end
    end
  
    class LeafNode < ASTNode
      attr_reader :character, :follow_set
      def initialize character
        @character = character
        @follow_set = Set.new
      end

      def to_dot(graph)
        graph.node(self, :label => character)
      end

      def nullable
        false
      end

      def first
        Set.new([self])
      end

      def last
        Set.new([self])
      end
    
      def calculate_follow_sets
      end
    end
    
    class CheckpointNode < ASTNode
      def to_dot(graph)
        graph.node(self, :label => "lookahead")
      end
      
      def character
      end
      
      def checkpoint
        true
      end
    end
  
    class AcceptingNode < ASTNode
      def accepting
        true
      end
    
      def character
      end
      
      def action(pattern)
        AcceptAction.new(pattern)
      end

      def first
        Set.new([self])
      end

      def calculate_follow_sets
      end
    
      def to_dot(graph)
        graph.node(self, :label => '#')
      end
    end
    
    class LookaheadAcceptingNode < AcceptingNode
      def action(pattern)
        LookaheadAcceptAction.new(pattern)
      end
    end
    
  end
end
