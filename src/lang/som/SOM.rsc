module lang::som::SOM

extend lang::std::Whitespace;
extend lang::std::Id;

start syntax Program = ClassDef* defs;

syntax ClassDef  = Id name "=" Id? "(" ClassBody body ")"; 

syntax ClassBody = Locals? Method* methods ClassDecls?;

syntax ClassDecls = Sep Locals? Method* methods;    

lexical Sep = [\-] !<< "----"[\-]* !>> [\-] ;    

syntax Locals = "|" Id* "|"; 
    
syntax Method 
  = Pattern pattern "=" "primitive" 
  | Pattern pattern "=" "(" BlockContents? contents ")"
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
  = Expr
  | "^" Expr
  ;

    
syntax Expr 
  = Id
  | @category="Constant" Symbol
  | @category="StringLiteral" String
  | @category="Constant" Integer
  | @category="Constant" Double
  | "[" BlockPattern? BlockContents? contents "]"
  | Expr!kw UnarySelector
  > left Expr!kw BinarySelector Expr!kw
  > kw: Expr!kw KeywordForms
  > Id ":=" Expr  
  | bracket "(" Expr ")" 
  ;

syntax KeywordForms = KeywordForm+;
  
syntax KeywordForm = Keyword key Expr!kw expr;
 
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

syntax UnarySelector = @category="Identifier" Id;

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

lexical StrChar = ![\']; // escaping?

syntax BlockPattern = BlockArgument+ "|";

syntax BlockArgument = ":" Id;

layout Standard 
  = WhitespaceOrComment* !>> [\u0009-\u000D \u0020 \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000] !>> "\"";
  
lexical WhitespaceOrComment 
  = Whitespace
  | Comment
  ; 
  
lexical Comment = @category="Comment" [\"] ![\"]* [\"];

