EXPORT Pattern_Definitions := MACRO
  // Pure Whitespace
  PATTERN LowControl    := PATTERN(U'[\u0001-\u0008\u000B\u000C\u000E\u000F]');
  PATTERN HighControl    := PATTERN(U'[\u007F-\u009F]');
  PATTERN Space          := U' ' OR LowControl OR HighControl;
  PATTERN Spaces        := Space+;
  PATTERN WhiteSpace    := Spaces;
  // Symbols that are keywords
  PATTERN Ampersand      := U'&';
  PATTERN Apostrophe    := U'\'';
  PATTERN Section        := U'\u00A7';
  PATTERN SubSection    := U'\u00A7\u00A7';
  PATTERN Dollar        := U'$';
  PATTERN Slash          := U'/';
  PATTERN  LeftParen      := U'(';
  PATTERN RightParen    := U')';
  PATTERN NumSign        := U'#';
  PATTERN Percent        := U'%';
  PATTERN Equal          := U'=';
  PATTERN AtSign        := U'@';
  PATTERN LessThan      := U'<';
  PATTERN GreaterThan    := U'>';
  PATTERN Cent          := U'\u00A2';
  PATTERN  Sterling      := U'\u00A3';
  PATTERN CopyRight      := U'\u00A9';
  PATTERN Registered    := U'\u00AE';
  PATTERN NotSign        := U'\u00AC';
  PATTERN Degree        := U'\u00B0';
  PATTERN  MidDot        := U'\u00B7';
  PATTERN FractSyms      := PATTERN(U'[\u00BC-\u00BE]');
  PATTERN SymbolNoSpec  := Ampersand OR Apostrophe OR Section OR SubSection
                           OR Dollar /* OR Equal*/ OR Slash
                           OR NumSign OR Percent OR AtSign OR LessThan
                           OR GreaterThan OR Cent OR Sterling OR CopyRight
                           OR Registered OR NotSign OR Degree OR MidDot
                           OR FractSyms;
  PATTERN SearchLeftP    := U'\\(';
  PATTERN SearchRightP  := U'\\)';
  PATTERN SearchEqual    := U'\\=';
  PATTERN SymbolChar    := SymbolNoSpec OR LeftParen OR RightParen OR Equal;
  PATTERN Symbol4Search  := SymbolNoSpec OR SearchLeftP OR SearchRightP
                          OR SearchEqual;
  // Symbols that are noise
  PATTERN Comma          := U',';
  PATTERN Period        := U'.';
  PATTERN Hyphen        := U'-';
  PATTERN  NBSP          := U'\u00A0';
  PATTERN  CR            := U'\r';
  PATTERN NL            := U'\n';
  PATTERN Underscore    := U'_';
  PATTERN Tab            := U'\t';
  PATTERN Exclamation    := U'!';
  PATTERN  Plus          := U'+';
  PATTERN Quote          := U'"';
  PATTERN Asterisk      := U'*';
  PATTERN Colon          := U':';
  PATTERN SemiColon      := U';';
  PATTERN LeftSqB        := U'\u005B';
  PATTERN Question      := U'?';
  PATTERN BSlash        := U'\u005C';
  PATTERN RightSqB      := U'\u005D';
  PATTERN Caret          := U'\u005E';
  PATTERN Grave          := U'\u0060';
  PATTERN LeftBrace      := U'{';
  PATTERN RightBrace    := U'}';
  PATTERN Tilde          := U'~';
  PATTERN SplitBar      := U'\u00A6';
  PATTERN VBar          := U'\u007C';
  PATTERN SoftHyphen    := U'\u00AD';
  PATTERN TypoSpaces    := PATTERN(U'[\u2000-\u200B]');
  PATTERN TypoHyphens    := PATTERN(U'[\u2010-\u2015]');
  PATTERN TypoQuotes    := PATTERN(U'[\u2018-\u201F]');
  PATTERN Bullet        := U'\u2022';
  PATTERN  Ellipse        := U'\u2026';
  PATTERN BlkSmSq        := U'\u25AA';
  PATTERN  NoiseNoSpecial:= Comma OR Period OR Hyphen OR NBSP OR CR OR NL
                           OR Underscore OR Tab
                           OR Exclamation OR Plus /*OR Quote*/ OR Asterisk
                           OR Colon OR SemiColon OR LeftSqB OR Question
                           /*OR BSlash*/ OR RightSqB OR Caret OR Grave OR LeftBrace
                           OR RightBrace OR Tilde OR SplitBar OR VBar
                           OR SoftHyphen OR TypoSpaces OR TypoHyphens OR TypoQuotes
                           OR Bullet OR Ellipse OR BlkSmSq;
  PATTERN SearchQuote    := '\\"';    // sequence of back-slash and quote characters
  PATTERN SearchBSlash  := '\\\\';  // sequence of 2 back-slash characters
  PATTERN Noise          := NoiseNoSpecial OR Quote OR BSlash;
  PATTERN Noise4Search  := NoiseNoSpecial OR SearchQuote OR SearchBSlash;
  // Catch all
  PATTERN AnyChar        := PATTERN(U'[\u0001-\uD7FF\uE000-\uFFFF]') PENALTY(10);
  PATTERN HighSurrogate  := PATTERN(U'[\uD800-\uDBFF]');
  PATTERN LowSurrogate  := PATTERN(U'[\uDC00-\uDFFF]');
  PATTERN AnyPair        := HighSurrogate LowSurrogate;
  PATTERN AnyNoQuote    := PATTERN(U'[\u0001-\u0021\u0023-\uFFFF]');
  PATTERN AnyNoApos     := PATTERN(U'[\u0001-\u0026\u0028-\uFFFF]');
  PATTERN AnyNoHyphen    := PATTERN(U'[\u0001-\u002C\u002E-\uFFFF]');
  // Singles
  PATTERN Single         := Noise | SymbolChar | AnyPair | AnyChar;
  PATTERN Single4Search  := Noise4Search | Symbol4Search | AnyPair | AnyChar;

  // Composite patterns
  // Word strings
  PATTERN Letter        := PATTERN(U'[[:alpha:]]');
	//PATTERN NOLetter        := PATTERN(U'[^[:alpha:]]');
  PATTERN LowerCase      := PATTERN(U'[[:lower:]]');
  PATTERN UpperCase      := PATTERN(U'[[:upper:]]');
  PATTERN Digit          := PATTERN(U'[[:digit:]]');
  PATTERN Alphanumeric  := Letter OR Digit;
  PATTERN  LowerNumeric  := LowerCase OR Digit;
  PATTERN UpperNumeric  := UpperCase OR Digit;
  PATTERN WordAllLower  := Digit* LowerCase LowerNumeric*;
  PATTERN WordAllUpper  := Digit* UpperCase UpperNumeric*;
  PATTERN WordTitleCase  := UpperCase lowerNumeric*;
  PATTERN WordMixedCase  := Digit* LowerCase LowerNumeric* UpperCase Alphanumeric*
                        OR Digit* UpperCase UpperNumeric* LowerCase AlphaNumeric*;
  PATTERN WordNoLetters  := Digit+;
  PATTERN WordAlphaNum  := Alphanumeric+;
  // Special tag strings
  PATTERN PoundCode      := U'#' Alphanumeric+ REPEAT(U'-' Alphanumeric*) U'#';
  PATTERN AlphanumWild  := Alphanumeric OR U'*' OR REPEAT(U'?', 1);
  PATTERN PoundCodeWild := U'#' AlphanumWild+ REPEAT(U'-' AlphanumWild*) U'#';
ENDMACRO;
