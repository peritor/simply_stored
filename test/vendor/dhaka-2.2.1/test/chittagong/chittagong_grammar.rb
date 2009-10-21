class ChittagongGrammar < Dhaka::Grammar

  precedences do
    nonassoc %w| == |
    nonassoc %w| < > |
    left     %w| + - |
    left     %w| * / |
    nonassoc %w| ^ |
    nonassoc %w| ! |
  end
  # lipi:grammar_overview
  
  for_symbol(Dhaka::START_SYMBOL_NAME) do
    program                             %w| opt_terms main_body opt_terms |
  end

  for_symbol('main_body') do
    single_main_body_statement          %w| main_body_statement |
    multiple_main_body_statements       %w| main_body terms main_body_statement |
  end
  
  for_symbol('main_body_statement') do
    main_body_simple_statement          %w| simple_statement |
    function_definition                 %w| def function_name ( arg_declarations ) terms 
                                                function_body terms end |
    main_body_if_statement              %w| if expression terms main_body terms end |
    main_body_if_else_statement         %w| if expression terms main_body terms else terms main_body 
                                                terms end |
    main_body_while_statement           %w| while expression terms main_body terms end |
  end
  # lipi:grammar_overview

  for_symbol('simple_statement') do
    assignment_statement                %w| var_name = expression |
    print_statement                     %w| print expression |
    function_call_statement             %w| function_name ( arg_list ) |
  end
  
  for_symbol('function_body') do
    single_function_body_statement      %w| function_body_statement |
    multiple_function_body_statements   %w| function_body terms function_body_statement |
  end
  
  for_symbol('function_body_statement') do
    function_body_simple_statement      %w| simple_statement |
    return_statement                    %w| return expression |
    function_body_if_statement          %w| if expression terms function_body terms end |
    function_body_if_else_statement     %w| if expression terms function_body terms else terms function_body terms end |
    function_body_while_statement       %w| while expression terms function_body terms end |
  end
  
  for_symbol('function_name') do
    function_name                       %w| word_literal |
  end
  
  for_symbol('var_name') do
    variable_name                       %w| word_literal |
  end
  
  for_symbol('arg_declarations') do
    no_arg_decl                         %w| |
    single_arg_declaration              %w| arg_decl |
    multiple_arg_declarations           %w| arg_declarations , arg_decl |
  end
  
  for_symbol('arg_decl') do
    arg_declaration                     %w| word_literal |
  end
  
  for_symbol('arg_list') do
    no_args                             %w| |
    single_arg                          %w| expression |
    multiple_args                       %w| arg_list , expression |
  end
  # lipi:expressions
  for_symbol('expression') do
    negation                            %w| ! expression |
    equality_comparison                 %w| expression == expression |
    greater_than_comparison             %w| expression > expression |
    less_than_comparison                %w| expression < expression |
    addition                            %w| expression + expression |
    subtraction                         %w| expression - expression |
    multiplication                      %w| expression * expression |
    division                            %w| expression / expression |
    power                               %w| expression ^ expression |
    literal                             %w| numeric_literal |
    function_call_expression            %w| function_name ( arg_list ) |
    variable_reference                  %w| var_name |
    parenthetized_expression            %w| ( expression ) |
    negated_expression                  %w| - expression |, :prec => '*'
  end
  # lipi:expressions
  
  for_symbol('terms') do
    single_term                         %w| newline |
    multiple_terms                      %w| terms newline |
  end

  for_symbol('opt_terms') do
    some_terms                          %w| terms |
    no_terms                            %w| |
  end
  
end