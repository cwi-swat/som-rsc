module lang::som::SOM

extend lang::std::Whitespace;
extend lang::std::Id;

start syntax Program = Classdef*;

syntax Classdef  = Id "=" Id? "(" Locals? Method* ClassDecls? ")"; 

syntax ClassDecls = Sep Locals? Method*;    

// TODO Sep is ambiguous with binary selector
// so a unary class method can be interpreted as
// a binary method where the separator is the binop
lexical Sep = [\-] !<< "----"[\-]* !>> [\-] ;    

syntax Locals = "|" Id* "|"; 
    
syntax Method 
  = Pattern "=" "primitive" 
  | Pattern "=" "(" BlockContents? ")"
  ;
    
syntax Pattern 
  = UnarySelector 
  | BinarySelector Id
  | KeywordArg+
  ;
  
syntax KeywordArg = Keyword Id;    
  
syntax BlockContents = Locals? {Stmt Dot}+ Dot?;
    
lexical Dot
  = [0-9] << "." !>> [0-9]
  | [0-9] !<< "." >> [0-9]
  | [0-9] !<< "." !>> [0-9]
  ;
    
syntax Stmt
  = Expression
  | "^" Expression
  ;
    
syntax Expression = Assignment* Primary Messages?;

syntax Assignment = Id ":=";

syntax Primary 
  = Id 
  | @category="Constant" Literal
  | bracket "(" Expression ")" 
  | "[" BlockPattern? BlockContents? "]" 
  ;

syntax Messages 
  = UnaryMessage+ BinaryMessage* KeywordMessage?
  | BinaryMessage+ KeywordMessage?
  | KeywordMessage
  ;
  
syntax UnaryMessage = UnarySelector;
syntax BinaryMessage = BinarySelector BinaryOperand;
syntax BinaryOperand = Primary UnaryMessage*;
syntax KeywordMessage = KeywordForm+;

syntax KeywordForm = Keyword Formula;

syntax Formula = BinaryOperand BinaryMessage*;

syntax Literal 
  = Symbol
  | @category="StringLiteral" String
  | Number
  | Float
  ;

lexical Float = "-"? [0-9]+ "." [0-9]+ !>> [0-9];

lexical Number 
  = "-"? [1-9][0-9]* !>> [0-9]
  | [0]
  ; 

syntax Symbol 
  = "#" String
  | "#" Selector
  ;
  
syntax Selector
  = BinarySelector 
  | KeywordSelector 
  | UnarySelector
  ;

syntax UnarySelector = Id;

lexical BinarySelector 
  = [~|,\-=!&*/\\+\>\<@%] !<< BC !>> [~|,\-=!&*/\\+\>\<@%]
  | [~|,\-=!&*/\\+\>\<@%] !<< BC BC !>> [~|,\-=!&*/\\+\>\<@%]
  | [~|,\-=!&*/\\+\>\<@%] !<< BC BC BC !>> [~|,\-=!&*/\\+\>\<@%]
  | [~|,\-=!&*/\\+\>\<@%] !<< FourBC \ Separator BC* !>> [~|,\-=!&*/\\+\>\<@%]
  ;

lexical FourBC = BC BC BC BC;
  
keyword Separator = "----";
  
lexical BC = [~|,\-=!&*/\\+\>\<@%]; 
  
lexical Keyword = @category="Identifier" Id ":";

syntax KeywordSelector = Keyword+;  
  
lexical String = "\'" StrChar* "\'";

lexical StrChar
  = ![\'] // escaping?
  ;

syntax BlockPattern = BlockArgument+ "|";

syntax BlockArgument = ":" Id;

layout Standard 
  = WhitespaceOrComment* !>> [\u0009-\u000D \u0020 \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000] !>> "\"";
  
lexical WhitespaceOrComment 
  = Whitespace
  | Comment
  ; 
  
lexical Comment 
  = @category="Comment" [\"] ![\"]* [\"];

