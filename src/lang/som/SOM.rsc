module lang::som::SOM

extend lang::std::Whitespace;
extend lang::std::Id;

start syntax Program = Classdef* defs;

syntax Classdef  = Id name "=" Id? "(" ClassBody body ")"; 

syntax ClassBody = Locals? Method* ClassDecls?;

syntax ClassDecls = Sep Locals? Method*;    

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
    
syntax Expression 
  = @category="Variable" Id 
  | @category="Constant" Symbol
  | @category="StringLiteral" String
  | @category="Constant" Integer
  | @category="Constant" Double
  | "[" BlockPattern? BlockContents? "]"
  | Expression!kw UnarySelector
  > left Expression!kw BinarySelector Expression!kw
  > kw: Expression!kw KeywordForm+
  > Id ":=" Expression  
  | bracket "(" Expression ")" 
  ;
  
syntax KeywordForm = Keyword Expression!kw;
 
lexical Double = "-"? [0-9]+ "." [0-9]+ !>> [0-9];

lexical Integer 
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

