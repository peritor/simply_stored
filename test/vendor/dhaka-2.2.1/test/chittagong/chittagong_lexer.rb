class ChittagongLexer < Dhaka::CompiledLexer

  self.specification = ChittagongLexerSpecification

  start_with 23993520499080

  at_state(23993520490540) {
    accept(">")
  }

  at_state(23993520496080) {
    accept("\\d*(\\.\\d+)?")
    for_characters("6", "7", "8", "9", "0", "1", "2", "3", "4", "5") { switch_to 23993520496080 }
  }

  at_state(23993520497360) {
    accept("\\d*(\\.\\d+)?")
    for_characters("6", "7", "8", "9", "0", "1", "2", "3", "4", "5") { switch_to 23993520497360 }
    for_characters(".") { switch_to 23993520496640 }
  }

  at_state(23993520499080) {
    accept("\\d*(\\.\\d+)?")
    for_characters("\n") { switch_to 23993520492400 }
    for_characters("*") { switch_to 23993520491960 }
    for_characters("!") { switch_to 23993520479360 }
    for_characters(" ") { switch_to 23993520478920 }
    for_characters("/") { switch_to 23993520479800 }
    for_characters("-") { switch_to 23993520477160 }
    for_characters(",") { switch_to 23993520477600 }
    for_characters("+") { switch_to 23993520480240 }
    for_characters(")") { switch_to 23993520478040 }
    for_characters("^") { switch_to 23993520478480 }
    for_characters("J", "o", "p", "K", "q", "L", "r", "M", "s", "N", "t", "O", "a", "u", "P", "b", "Q", "c", "v", "R", "d", "w", "S", "e", "x", "T", "f", "y", "A", "U", "g", "z", "B", "h", "C", "V", "i", "D", "W", "j", "E", "X", "F", "Y", "k", "G", "Z", "l", "H", "m", "I", "n") { switch_to 23993520490080 }
    for_characters("=") { switch_to 23993520491540 }
    for_characters(">") { switch_to 23993520490540 }
    for_characters("<") { switch_to 23993520497800 }
    for_characters("(") { switch_to 23993520498240 }
    for_characters("8", "9", "0", "1", "2", "3", "4", "5", "6", "7") { switch_to 23993520497360 }
    for_characters(".") { switch_to 23993520496640 }
  }

  at_state(23993520478480) {
    accept("\\^")
  }

  at_state(23993520492400) {
    accept("\n")
  }

  at_state(23993520496640) {
    for_characters("6", "7", "8", "9", "0", "1", "2", "3", "4", "5") { switch_to 23993520496080 }
  }

  at_state(23993520477600) {
    accept(",")
  }

  at_state(23993520478040) {
    accept("\\)")
  }

  at_state(23993520491540) {
    accept("=")
    for_characters("=") { switch_to 23993520490980 }
  }

  at_state(23993520491960) {
    accept("\\*")
  }

  at_state(23993520497800) {
    accept("<")
  }

  at_state(23993520498240) {
    accept("\\(")
  }

  at_state(23993520479800) {
    accept("\\/")
  }

  at_state(23993520490980) {
    accept("==")
  }

  at_state(23993520478920) {
    accept(" ")
  }

  at_state(23993520477160) {
    accept("-")
  }

  at_state(23993520479360) {
    accept("!")
  }

  at_state(23993520480240) {
    accept("\\+")
  }

  at_state(23993520490080) {
    accept("\\w+")
    for_characters("k", "v", "V", "K", "A", "w", "l", "a", "W", "L", "b", "m", "M", "x", "B", "X", "Y", "c", "y", "n", "N", "C", "D", "o", "d", "z", "Z", "O", "P", "e", "E", "p", "Q", "q", "f", "F", "G", "g", "r", "R", "S", "H", "s", "h", "t", "T", "I", "i", "J", "j", "u", "U") { switch_to 23993520490080 }
  }

end