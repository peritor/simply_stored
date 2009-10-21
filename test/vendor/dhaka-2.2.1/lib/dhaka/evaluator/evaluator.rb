module Dhaka
  # Abstract base class for evaluators.
  #
  # Defining an evaluator is an easy way to perform syntax-directed evaluation without having to generate an abstract
  # syntax tree representation of the input. 
  #
  # An evaluation rule for a given production named +bar+ is defined by calling +for_bar+ with
  # a block that performs the evaluation. For detailed examples, see the evaluators in the 
  # test suite.
  # 
  # The following is an evaluator for arithmetic expressions. When a parse tree node is encountered that
  # corresponds to the production named +addition+, the block passed to +for_addition+ is invoked. The +evaluate+
  # method is then recursively called on the child nodes, in this case the operands to the addition operation. The
  # result is obtained by adding the evaluation results of the child nodes.
  # 
  #    class ArithmeticPrecedenceEvaluator < Dhaka::Evaluator
  #
  #      self.grammar = ArithmeticPrecedenceGrammar
  #
  #      define_evaluation_rules do
  #
  #        for_subtraction do 
  #          evaluate(child_nodes[0]) - evaluate(child_nodes[2])
  #        end
  #
  #        for_addition do
  #          evaluate(child_nodes[0]) + evaluate(child_nodes[2])
  #        end
  #
  #        for_division do
  #          evaluate(child_nodes[0]).to_f/evaluate(child_nodes[2]) 
  #        end
  #
  #        for_multiplication do
  #          evaluate(child_nodes[0]) * evaluate(child_nodes[2])
  #        end
  #
  #        for_literal do
  #          child_nodes[0].token.value.to_i
  #        end
  #
  #        for_parenthetized_expression do
  #          evaluate(child_nodes[1])
  #        end
  #
  #        for_negated_expression do
  #          -evaluate(child_nodes[1])
  #        end
  #
  #        for_power do
  #          evaluate(child_nodes[0])**evaluate(child_nodes[2])
  #        end
  #
  #      end
  #
  #    end

  class Evaluator < SimpleDelegator
    class << self
      # Define evaluation rules within a block passed to this method. The evaluator will define
      # default evaluation rules for pass-through productions (i.e. productions with expansions
      # consisting of exactly one grammar symbol). The default evaluation rule for such productions
      # is to simply return the result of calling +evaluate+ on the unique child node. Setting the
      # <tt>:raise_error</tt> option to true tells the evaluator to throw an exception if you neglect
      # to define a rule for a non-pass-through production (one where the expansion consists of
      # multiple symbols), listing all the productions that absolutely need to be defined before you
      # can continue.
      def define_evaluation_rules(options = {})
        yield
        check_definitions(options)
      end
      
      private

      def check_definitions(options)
        filter = lambda {|productions| productions.map {|production| production.name} - actions}
        pass_through_productions_without_rules = filter[grammar.productions.select {|production| production.expansion.size == 1}]
        pass_through_productions_without_rules.each do |rule_name|
          send(:define_method, rule_name) do
            evaluate(child_nodes.first)
          end
        end
        non_trivial_productions_with_rules_undefined = filter[grammar.productions.select {|production| production.expansion.size != 1}]
        raise EvaluatorDefinitionError.new(non_trivial_productions_with_rules_undefined) unless non_trivial_productions_with_rules_undefined.empty? || !options[:raise_error]
      end

      def inherited(evaluator)
        class << evaluator
          attr_accessor :grammar, :actions
        end
        evaluator.actions = []
      end
    
      def method_missing(method_name, *args, &blk)
        name = method_name.to_s
        if name =~ /^for_(.+)$/
          rule_name = $1
          raise "Attempted to define evaluation rule for non-existent production '#{rule_name}'" unless grammar.production_named(rule_name)
          actions   << rule_name
          send(:define_method, rule_name, &blk)
        else
          super
        end
      end
    end

    # Evaluate a parse tree node.
    def evaluate node
      @node_stack ||= []
      @node_stack << node
      __setobj__(@node_stack.last)
      result      = send(node.production.name)
      @node_stack.pop
      __setobj__(@node_stack.last)
      result
    end

    def initialize
      
    end
  end

  class EvaluatorDefinitionError < StandardError #:nodoc:
    def initialize(non_trivial_productions_with_rules_undefined)
      @non_trivial_productions_with_rules_undefined = non_trivial_productions_with_rules_undefined
    end
  
    def to_s
      result = "The following non-trivial productions do not have any evaluation rules defined:\n" 
      result << @non_trivial_productions_with_rules_undefined.join("\n")
    end
  end
end