module lang::som::SOM

extend lang::std::Whitespace;
extend lang::std::Id;

start syntax Program = Classdef*;

syntax Classdef  = Id "=" Id? "(" Locals? Method* ClassDecls? ")"; 

syntax ClassDecls = "----" Locals? Method*;    
    
syntax Locals = "|" Id* "|"; 
    
syntax Method 
  = Pattern "=" "primitive" 
  | Pattern "=" "(" BlockContents ")"
  ;
    
syntax Pattern 
  = UnarySelector 
  | BinarySelector Id
  | KeywordArg+
  ;
  
syntax KeywordArg = Keyword Id;    
  
syntax BlockContents = Locals? {Stmt "."}+ "."?;
    
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
  | "[" BlockPattern? BlockContents "]" 
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
  ;

syntax Number 
  = "-" Integer 
  | Integer
  ;

lexical Integer = [1-9][0-9]* !>> [0-9];  

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

lexical BinarySelector = [|,\-=!&*/\\+\>\<@%] !<< [|,\-=!&*/\\+\>\<@%]+ !>> [|,\-=!&*/\\+\>\<@%]; 
  
lexical Keyword = @category="Identifier" Id ":";

syntax KeywordSelector = Keyword+;  
  
lexical String = "\'" StrChar "\'";

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
