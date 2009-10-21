class ChittagongParser < Dhaka::CompiledParser

  self.grammar = ChittagongGrammar

  start_with 0

  at_state(91) {
    for_symbols("newline") { shift_to 1 }
    for_symbols("^") { shift_to 14 }
    for_symbols("<") { shift_to 24 }
    for_symbols("terms") { shift_to 92 }
    for_symbols("+") { shift_to 22 }
    for_symbols("-") { shift_to 26 }
    for_symbols("/") { shift_to 20 }
    for_symbols("*") { shift_to 16 }
    for_symbols(">") { shift_to 12 }
    for_symbols("==") { shift_to 18 }
  }

  at_state(83) {
    for_symbols("while") { shift_to 68 }
    for_symbols("newline") { shift_to 51 }
    for_symbols("return") { shift_to 86 }
    for_symbols("if") { shift_to 74 }
    for_symbols("simple_statement") { shift_to 85 }
    for_symbols("var_name") { shift_to 44 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_body_statement") { shift_to 66 }
    for_symbols("function_name") { shift_to 40 }
    for_symbols("print") { shift_to 88 }
    for_symbols("end") { shift_to 84 }
  }

  at_state(72) {
    for_symbols("while") { shift_to 68 }
    for_symbols("newline") { shift_to 51 }
    for_symbols("return") { shift_to 86 }
    for_symbols("if") { shift_to 74 }
    for_symbols("simple_statement") { shift_to 85 }
    for_symbols("var_name") { shift_to 44 }
    for_symbols("end") { shift_to 73 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_body_statement") { shift_to 66 }
    for_symbols("function_name") { shift_to 40 }
    for_symbols("print") { shift_to 88 }
  }

  at_state(68) {
    for_symbols("(") { shift_to 6 }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("expression") { shift_to 69 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
  }

  at_state(49) {
    for_symbols("_End_", "newline") { reduce_with "main_body_while_statement" }
  }

  at_state(6) {
    for_symbols("(") { shift_to 6 }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("expression") { shift_to 36 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
  }

  at_state(15) {
    for_symbols("+", "==", ",", "-", "/", "<", "_End_", ">", "newline", ")", "*") { reduce_with "power" }
  }

  at_state(100) {
    for_symbols("newline") { shift_to 51 }
    for_symbols("var_name") { shift_to 44 }
    for_symbols("def") { shift_to 52 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("simple_statement") { shift_to 96 }
    for_symbols("function_name") { shift_to 40 }
    for_symbols("while") { shift_to 5 }
    for_symbols("if") { shift_to 90 }
    for_symbols("print") { shift_to 88 }
    for_symbols("main_body_statement") { shift_to 50 }
    for_symbols("end") { shift_to 101 }
  }

  at_state(97) {
    for_symbols("newline") { shift_to 1 }
    for_symbols("terms") { shift_to 98 }
  }

  at_state(53) {
    for_symbols("(") { reduce_with "function_name" }
  }

  at_state(52) {
    for_symbols("function_name") { shift_to 54 }
    for_symbols("word_literal") { shift_to 53 }
  }

  at_state(104) {
    for_symbols("newline") { shift_to 51 }
    for_symbols("var_name") { shift_to 44 }
    for_symbols("def") { shift_to 52 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("simple_statement") { shift_to 96 }
    for_symbols("function_name") { shift_to 40 }
    for_symbols("while") { shift_to 5 }
    for_symbols("if") { shift_to 90 }
    for_symbols("print") { shift_to 88 }
    for_symbols("_End_") { reduce_with "some_terms" }
    for_symbols("main_body_statement") { shift_to 50 }
  }

  at_state(89) {
    for_symbols("^") { shift_to 14 }
    for_symbols("<") { shift_to 24 }
    for_symbols("+") { shift_to 22 }
    for_symbols("-") { shift_to 26 }
    for_symbols("/") { shift_to 20 }
    for_symbols("_End_", "newline") { reduce_with "print_statement" }
    for_symbols("*") { shift_to 16 }
    for_symbols(">") { shift_to 12 }
    for_symbols("==") { shift_to 18 }
  }

  at_state(77) {
    for_symbols("newline") { shift_to 1 }
    for_symbols("terms") { shift_to 78 }
  }

  at_state(76) {
    for_symbols("while") { shift_to 68 }
    for_symbols("newline") { shift_to 51 }
    for_symbols("return") { shift_to 86 }
    for_symbols("if") { shift_to 74 }
    for_symbols("simple_statement") { shift_to 85 }
    for_symbols("function_body_statement") { shift_to 63 }
    for_symbols("var_name") { shift_to 44 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 40 }
    for_symbols("print") { shift_to 88 }
    for_symbols("function_body") { shift_to 77 }
  }

  at_state(66) {
    for_symbols("newline") { reduce_with "multiple_function_body_statements" }
  }

  at_state(14) {
    for_symbols("(") { shift_to 6 }
    for_symbols("expression") { shift_to 15 }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
  }

  at_state(59) {
    for_symbols("arg_decl") { shift_to 60 }
    for_symbols("word_literal") { shift_to 57 }
  }

  at_state(105) {
    for_symbols("newline") { shift_to 51 }
    for_symbols("word_literal", "def", "print", "if", "while") { reduce_with "some_terms" }
  }

  at_state(19) {
    for_symbols("^") { shift_to 14 }
    for_symbols("<") { shift_to 24 }
    for_symbols(",", "_End_", "newline", ")") { reduce_with "equality_comparison" }
    for_symbols("+") { shift_to 22 }
    for_symbols("-") { shift_to 26 }
    for_symbols("/") { shift_to 20 }
    for_symbols("*") { shift_to 16 }
    for_symbols(">") { shift_to 12 }
  }

  at_state(33) {
    for_symbols("^") { shift_to 14 }
    for_symbols("+", "==", ",", "-", "/", "<", "_End_", ">", "newline", ")", "*") { reduce_with "negated_expression" }
  }

  at_state(31) {
    for_symbols("+", "==", ",", "-", "/", "<", "_End_", ">", "^", "newline", ")", "*") { reduce_with "negation" }
  }

  at_state(99) {
    for_symbols("newline") { shift_to 1 }
    for_symbols("terms") { shift_to 100 }
  }

  at_state(74) {
    for_symbols("(") { shift_to 6 }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("expression") { shift_to 75 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
  }

  at_state(67) {
    for_symbols("_End_", "newline") { reduce_with "function_definition" }
  }

  at_state(37) {
    for_symbols("+", "==", ",", "-", "/", "<", "_End_", ">", "^", "newline", ")", "*") { reduce_with "parenthetized_expression" }
  }

  at_state(12) {
    for_symbols("(") { shift_to 6 }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("expression") { shift_to 13 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
  }

  at_state(60) {
    for_symbols(",", ")") { reduce_with "multiple_arg_declarations" }
  }

  at_state(27) {
    for_symbols("^") { shift_to 14 }
    for_symbols("/") { shift_to 20 }
    for_symbols("*") { shift_to 16 }
    for_symbols("+", "==", ",", "-", "<", "_End_", ">", "newline", ")") { reduce_with "subtraction" }
  }

  at_state(103) {
    for_symbols("_End_") { reduce_with "program" }
  }

  at_state(86) {
    for_symbols("(") { shift_to 6 }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("expression") { shift_to 87 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
  }

  at_state(82) {
    for_symbols("newline") { shift_to 1 }
    for_symbols("terms") { shift_to 83 }
  }

  at_state(46) {
    for_symbols("^") { shift_to 14 }
    for_symbols("<") { shift_to 24 }
    for_symbols("_End_", "newline") { reduce_with "assignment_statement" }
    for_symbols("+") { shift_to 22 }
    for_symbols("-") { shift_to 26 }
    for_symbols("/") { shift_to 20 }
    for_symbols("*") { shift_to 16 }
    for_symbols(">") { shift_to 12 }
    for_symbols("==") { shift_to 18 }
  }

  at_state(11) {
    for_symbols("^") { shift_to 14 }
    for_symbols("<") { shift_to 24 }
    for_symbols(",", ")") { reduce_with "multiple_args" }
    for_symbols("+") { shift_to 22 }
    for_symbols("-") { shift_to 26 }
    for_symbols("/") { shift_to 20 }
    for_symbols("*") { shift_to 16 }
    for_symbols(">") { shift_to 12 }
    for_symbols("==") { shift_to 18 }
  }

  at_state(16) {
    for_symbols("(") { shift_to 6 }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("expression") { shift_to 17 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
  }

  at_state(43) {
    for_symbols("_End_", "newline") { reduce_with "function_call_statement" }
  }

  at_state(28) {
    for_symbols("+", "==", ",", "-", "/", "<", "_End_", ">", "^", "newline", ")", "*") { reduce_with "variable_reference" }
  }

  at_state(78) {
    for_symbols("while") { shift_to 68 }
    for_symbols("newline") { shift_to 51 }
    for_symbols("return") { shift_to 86 }
    for_symbols("else") { shift_to 80 }
    for_symbols("end") { shift_to 79 }
    for_symbols("if") { shift_to 74 }
    for_symbols("simple_statement") { shift_to 85 }
    for_symbols("var_name") { shift_to 44 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_body_statement") { shift_to 66 }
    for_symbols("function_name") { shift_to 40 }
    for_symbols("print") { shift_to 88 }
  }

  at_state(69) {
    for_symbols("newline") { shift_to 1 }
    for_symbols("^") { shift_to 14 }
    for_symbols("<") { shift_to 24 }
    for_symbols("terms") { shift_to 70 }
    for_symbols("+") { shift_to 22 }
    for_symbols("-") { shift_to 26 }
    for_symbols("/") { shift_to 20 }
    for_symbols("*") { shift_to 16 }
    for_symbols(">") { shift_to 12 }
    for_symbols("==") { shift_to 18 }
  }

  at_state(63) {
    for_symbols("newline") { reduce_with "single_function_body_statement" }
  }

  at_state(94) {
    for_symbols("newline") { shift_to 51 }
    for_symbols("var_name") { shift_to 44 }
    for_symbols("else") { shift_to 97 }
    for_symbols("end") { shift_to 95 }
    for_symbols("def") { shift_to 52 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("simple_statement") { shift_to 96 }
    for_symbols("function_name") { shift_to 40 }
    for_symbols("while") { shift_to 5 }
    for_symbols("if") { shift_to 90 }
    for_symbols("print") { shift_to 88 }
    for_symbols("main_body_statement") { shift_to 50 }
  }

  at_state(62) {
    for_symbols("while") { shift_to 68 }
    for_symbols("newline") { shift_to 51 }
    for_symbols("return") { shift_to 86 }
    for_symbols("if") { shift_to 74 }
    for_symbols("simple_statement") { shift_to 85 }
    for_symbols("function_body_statement") { shift_to 63 }
    for_symbols("var_name") { shift_to 44 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 40 }
    for_symbols("print") { shift_to 88 }
    for_symbols("function_body") { shift_to 64 }
  }

  at_state(10) {
    for_symbols("(") { shift_to 6 }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("expression") { shift_to 11 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
  }

  at_state(0) {
    for_symbols("newline") { shift_to 1 }
    for_symbols("terms") { shift_to 105 }
    for_symbols("opt_terms") { shift_to 2 }
    for_symbols("word_literal", "def", "print", "if", "while") { reduce_with "no_terms" }
  }

  at_state(80) {
    for_symbols("newline") { shift_to 1 }
    for_symbols("terms") { shift_to 81 }
  }

  at_state(79) {
    for_symbols("newline") { reduce_with "function_body_if_statement" }
  }

  at_state(75) {
    for_symbols("newline") { shift_to 1 }
    for_symbols("^") { shift_to 14 }
    for_symbols("<") { shift_to 24 }
    for_symbols("terms") { shift_to 76 }
    for_symbols("+") { shift_to 22 }
    for_symbols("-") { shift_to 26 }
    for_symbols("/") { shift_to 20 }
    for_symbols("*") { shift_to 16 }
    for_symbols(">") { shift_to 12 }
    for_symbols("==") { shift_to 18 }
  }

  at_state(47) {
    for_symbols("newline") { shift_to 1 }
    for_symbols("terms") { shift_to 48 }
  }

  at_state(57) {
    for_symbols(",", ")") { reduce_with "arg_declaration" }
  }

  at_state(7) {
    for_symbols("(") { shift_to 8 }
  }

  at_state(61) {
    for_symbols("newline") { shift_to 1 }
    for_symbols("terms") { shift_to 62 }
  }

  at_state(24) {
    for_symbols("(") { shift_to 6 }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("expression") { shift_to 25 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
  }

  at_state(2) {
    for_symbols("main_body_statement") { shift_to 3 }
    for_symbols("var_name") { shift_to 44 }
    for_symbols("def") { shift_to 52 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("simple_statement") { shift_to 96 }
    for_symbols("main_body") { shift_to 102 }
    for_symbols("function_name") { shift_to 40 }
    for_symbols("while") { shift_to 5 }
    for_symbols("if") { shift_to 90 }
    for_symbols("print") { shift_to 88 }
  }

  at_state(102) {
    for_symbols("newline") { shift_to 1 }
    for_symbols("terms") { shift_to 104 }
    for_symbols("_End_") { reduce_with "no_terms" }
    for_symbols("opt_terms") { shift_to 103 }
  }

  at_state(96) {
    for_symbols("_End_", "newline") { reduce_with "main_body_simple_statement" }
  }

  at_state(73) {
    for_symbols("newline") { reduce_with "function_body_while_statement" }
  }

  at_state(51) {
    for_symbols("word_literal", "def", "end", "print", "else", "if", "_End_", "return", "newline", "while") { reduce_with "multiple_terms" }
  }

  at_state(13) {
    for_symbols("^") { shift_to 14 }
    for_symbols("+") { shift_to 22 }
    for_symbols("-") { shift_to 26 }
    for_symbols("/") { shift_to 20 }
    for_symbols("*") { shift_to 16 }
    for_symbols("==", ",", "_End_", "newline", ")") { reduce_with "greater_than_comparison" }
  }

  at_state(3) {
    for_symbols("_End_", "newline") { reduce_with "single_main_body_statement" }
  }

  at_state(20) {
    for_symbols("(") { shift_to 6 }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("expression") { shift_to 21 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
  }

  at_state(9) {
    for_symbols(",") { shift_to 10 }
    for_symbols(")") { shift_to 34 }
  }

  at_state(92) {
    for_symbols("newline") { shift_to 51 }
    for_symbols("main_body_statement") { shift_to 3 }
    for_symbols("var_name") { shift_to 44 }
    for_symbols("def") { shift_to 52 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("main_body") { shift_to 93 }
    for_symbols("simple_statement") { shift_to 96 }
    for_symbols("function_name") { shift_to 40 }
    for_symbols("while") { shift_to 5 }
    for_symbols("if") { shift_to 90 }
    for_symbols("print") { shift_to 88 }
  }

  at_state(81) {
    for_symbols("while") { shift_to 68 }
    for_symbols("newline") { shift_to 51 }
    for_symbols("return") { shift_to 86 }
    for_symbols("function_body") { shift_to 82 }
    for_symbols("if") { shift_to 74 }
    for_symbols("simple_statement") { shift_to 85 }
    for_symbols("function_body_statement") { shift_to 63 }
    for_symbols("var_name") { shift_to 44 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 40 }
    for_symbols("print") { shift_to 88 }
  }

  at_state(39) {
    for_symbols("newline") { shift_to 51 }
    for_symbols("main_body_statement") { shift_to 3 }
    for_symbols("var_name") { shift_to 44 }
    for_symbols("def") { shift_to 52 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("simple_statement") { shift_to 96 }
    for_symbols("function_name") { shift_to 40 }
    for_symbols("while") { shift_to 5 }
    for_symbols("if") { shift_to 90 }
    for_symbols("print") { shift_to 88 }
    for_symbols("main_body") { shift_to 47 }
  }

  at_state(17) {
    for_symbols("^") { shift_to 14 }
    for_symbols("+", "==", ",", "-", "/", "<", "_End_", ">", "newline", ")", "*") { reduce_with "multiplication" }
  }

  at_state(8) {
    for_symbols("(") { shift_to 6 }
    for_symbols("arg_list") { shift_to 9 }
    for_symbols(",", ")") { reduce_with "no_args" }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
    for_symbols("expression") { shift_to 35 }
  }

  at_state(58) {
    for_symbols(")") { shift_to 61 }
    for_symbols(",") { shift_to 59 }
  }

  at_state(98) {
    for_symbols("newline") { shift_to 51 }
    for_symbols("main_body_statement") { shift_to 3 }
    for_symbols("main_body") { shift_to 99 }
    for_symbols("var_name") { shift_to 44 }
    for_symbols("def") { shift_to 52 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("simple_statement") { shift_to 96 }
    for_symbols("function_name") { shift_to 40 }
    for_symbols("while") { shift_to 5 }
    for_symbols("if") { shift_to 90 }
    for_symbols("print") { shift_to 88 }
  }

  at_state(22) {
    for_symbols("(") { shift_to 6 }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
    for_symbols("expression") { shift_to 23 }
  }

  at_state(50) {
    for_symbols("_End_", "newline") { reduce_with "multiple_main_body_statements" }
  }

  at_state(30) {
    for_symbols("(") { shift_to 6 }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("expression") { shift_to 31 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
  }

  at_state(35) {
    for_symbols("^") { shift_to 14 }
    for_symbols("<") { shift_to 24 }
    for_symbols(",", ")") { reduce_with "single_arg" }
    for_symbols("+") { shift_to 22 }
    for_symbols("-") { shift_to 26 }
    for_symbols("/") { shift_to 20 }
    for_symbols("*") { shift_to 16 }
    for_symbols(">") { shift_to 12 }
    for_symbols("==") { shift_to 18 }
  }

  at_state(56) {
    for_symbols(",", ")") { reduce_with "single_arg_declaration" }
  }

  at_state(32) {
    for_symbols("(") { shift_to 6 }
    for_symbols("expression") { shift_to 33 }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
  }

  at_state(48) {
    for_symbols("newline") { shift_to 51 }
    for_symbols("var_name") { shift_to 44 }
    for_symbols("def") { shift_to 52 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("simple_statement") { shift_to 96 }
    for_symbols("function_name") { shift_to 40 }
    for_symbols("end") { shift_to 49 }
    for_symbols("while") { shift_to 5 }
    for_symbols("if") { shift_to 90 }
    for_symbols("print") { shift_to 88 }
    for_symbols("main_body_statement") { shift_to 50 }
  }

  at_state(87) {
    for_symbols("^") { shift_to 14 }
    for_symbols("<") { shift_to 24 }
    for_symbols("+") { shift_to 22 }
    for_symbols("-") { shift_to 26 }
    for_symbols("newline") { reduce_with "return_statement" }
    for_symbols("/") { shift_to 20 }
    for_symbols("*") { shift_to 16 }
    for_symbols(">") { shift_to 12 }
    for_symbols("==") { shift_to 18 }
  }

  at_state(54) {
    for_symbols("(") { shift_to 55 }
  }

  at_state(29) {
    for_symbols("+", "==", ",", "-", "/", "<", "_End_", ">", "^", "newline", ")", "*") { reduce_with "literal" }
  }

  at_state(101) {
    for_symbols("_End_", "newline") { reduce_with "main_body_if_else_statement" }
  }

  at_state(90) {
    for_symbols("(") { shift_to 6 }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("expression") { shift_to 91 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
  }

  at_state(88) {
    for_symbols("(") { shift_to 6 }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("expression") { shift_to 89 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
  }

  at_state(85) {
    for_symbols("newline") { reduce_with "function_body_simple_statement" }
  }

  at_state(70) {
    for_symbols("while") { shift_to 68 }
    for_symbols("newline") { shift_to 51 }
    for_symbols("return") { shift_to 86 }
    for_symbols("if") { shift_to 74 }
    for_symbols("simple_statement") { shift_to 85 }
    for_symbols("function_body_statement") { shift_to 63 }
    for_symbols("var_name") { shift_to 44 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_body") { shift_to 71 }
    for_symbols("function_name") { shift_to 40 }
    for_symbols("print") { shift_to 88 }
  }

  at_state(1) {
    for_symbols("word_literal", "def", "end", "print", "else", "if", "_End_", "return", "newline", "while") { reduce_with "single_term" }
  }

  at_state(38) {
    for_symbols("newline") { shift_to 1 }
    for_symbols("^") { shift_to 14 }
    for_symbols("<") { shift_to 24 }
    for_symbols("+") { shift_to 22 }
    for_symbols("-") { shift_to 26 }
    for_symbols("/") { shift_to 20 }
    for_symbols("terms") { shift_to 39 }
    for_symbols("*") { shift_to 16 }
    for_symbols(">") { shift_to 12 }
    for_symbols("==") { shift_to 18 }
  }

  at_state(25) {
    for_symbols("^") { shift_to 14 }
    for_symbols("+") { shift_to 22 }
    for_symbols("-") { shift_to 26 }
    for_symbols("/") { shift_to 20 }
    for_symbols("==", ",", "_End_", "newline", ")") { reduce_with "less_than_comparison" }
    for_symbols("*") { shift_to 16 }
  }

  at_state(40) {
    for_symbols("(") { shift_to 41 }
  }

  at_state(64) {
    for_symbols("newline") { shift_to 1 }
    for_symbols("terms") { shift_to 65 }
  }

  at_state(84) {
    for_symbols("newline") { reduce_with "function_body_if_else_statement" }
  }

  at_state(71) {
    for_symbols("newline") { shift_to 1 }
    for_symbols("terms") { shift_to 72 }
  }

  at_state(18) {
    for_symbols("(") { shift_to 6 }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("expression") { shift_to 19 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
  }

  at_state(44) {
    for_symbols("=") { shift_to 45 }
  }

  at_state(55) {
    for_symbols("arg_decl") { shift_to 56 }
    for_symbols(",", ")") { reduce_with "no_arg_decl" }
    for_symbols("arg_declarations") { shift_to 58 }
    for_symbols("word_literal") { shift_to 57 }
  }

  at_state(65) {
    for_symbols("while") { shift_to 68 }
    for_symbols("newline") { shift_to 51 }
    for_symbols("return") { shift_to 86 }
    for_symbols("end") { shift_to 67 }
    for_symbols("if") { shift_to 74 }
    for_symbols("simple_statement") { shift_to 85 }
    for_symbols("var_name") { shift_to 44 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_body_statement") { shift_to 66 }
    for_symbols("function_name") { shift_to 40 }
    for_symbols("print") { shift_to 88 }
  }

  at_state(21) {
    for_symbols("^") { shift_to 14 }
    for_symbols("+", "==", ",", "-", "/", "<", "_End_", ">", "newline", ")", "*") { reduce_with "division" }
  }

  at_state(95) {
    for_symbols("_End_", "newline") { reduce_with "main_body_if_statement" }
  }

  at_state(93) {
    for_symbols("newline") { shift_to 1 }
    for_symbols("terms") { shift_to 94 }
  }

  at_state(36) {
    for_symbols("^") { shift_to 14 }
    for_symbols("<") { shift_to 24 }
    for_symbols(")") { shift_to 37 }
    for_symbols("+") { shift_to 22 }
    for_symbols("-") { shift_to 26 }
    for_symbols("/") { shift_to 20 }
    for_symbols("*") { shift_to 16 }
    for_symbols(">") { shift_to 12 }
    for_symbols("==") { shift_to 18 }
  }

  at_state(42) {
    for_symbols(",") { shift_to 10 }
    for_symbols(")") { shift_to 43 }
  }

  at_state(26) {
    for_symbols("(") { shift_to 6 }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("expression") { shift_to 27 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
  }

  at_state(5) {
    for_symbols("(") { shift_to 6 }
    for_symbols("expression") { shift_to 38 }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
  }

  at_state(41) {
    for_symbols("(") { shift_to 6 }
    for_symbols("arg_list") { shift_to 42 }
    for_symbols(",", ")") { reduce_with "no_args" }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
    for_symbols("expression") { shift_to 35 }
  }

  at_state(45) {
    for_symbols("(") { shift_to 6 }
    for_symbols("numeric_literal") { shift_to 29 }
    for_symbols("expression") { shift_to 46 }
    for_symbols("word_literal") { shift_to 4 }
    for_symbols("function_name") { shift_to 7 }
    for_symbols("var_name") { shift_to 28 }
    for_symbols("-") { shift_to 32 }
    for_symbols("!") { shift_to 30 }
  }

  at_state(4) {
    for_symbols("(") { reduce_with "function_name" }
    for_symbols("+", "==", ",", "-", "/", "<", "_End_", "=", ">", "^", "newline", ")", "*") { reduce_with "variable_name" }
  }

  at_state(23) {
    for_symbols("^") { shift_to 14 }
    for_symbols("/") { shift_to 20 }
    for_symbols("+", "==", ",", "-", "<", "_End_", ">", "newline", ")") { reduce_with "addition" }
    for_symbols("*") { shift_to 16 }
  }

  at_state(34) {
    for_symbols("+", "==", ",", "-", "/", "<", "_End_", "^", ">", "newline", ")", "*") { reduce_with "function_call_expression" }
  }

end