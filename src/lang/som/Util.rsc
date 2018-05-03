module lang::som::Util

import lang::som::SOM;
import ParseTree;
import List;

Selector pattern2selector((Pattern)`<UnarySelector u>`) = (Selector)`<UnarySelector u>`;
Selector pattern2selector((Pattern)`<BinarySelector b> <Id _>`) = (Selector)`<BinarySelector b>`;
Selector pattern2selector((Pattern)`<Keyword k> <Id _>`) = (Selector)`<Keyword k>`;
Selector pattern2selector((Pattern)`<Keyword k> <Id _> <KeywordArg+ kas>`) 
  = (Selector)`<Keyword k><Keyword+ ks>`
  when 
    (Selector)`<Keyword+ ks>` := pattern2selector((Pattern)`<KeywordArg+ kas>`);


int arity((Pattern)`<UnarySelector _>`) = 0;
 
int arity((Pattern)`<BinarySelector _> <Id _>`) = 1;

int arity((Pattern)`<Keyword _> <Id _>`) = 1;

int arity((Pattern)`<Keyword _> <Id _> <KeywordArg+ kas>`) = 1 + arity((Pattern)`<KeywordArg+ kas>`);

list[Id] params((Pattern)`<UnarySelector _>`) = [];
 
list[Id] params((Pattern)`<BinarySelector _> <Id x>`) = [x];

list[Id] params((Pattern)`<Keyword _> <Id x>`) = [x];

list[Id] params((Pattern)`<Keyword _> <Id x> <KeywordArg+ kas>`) = [x, *params((Pattern)`<KeywordArg+ kas>`)];


str primitiveStubs(list[loc] classPath = [|project://rascal-som/src/lang/som/stdlib|]) {
  list[Tree] soms = [ parse(#start[Program], f) | loc dir <- classPath, loc f <- files(dir) ];
  str src = "";
  
  for (start[Program] p <- soms, ClassDef cd <- p.top.defs) {
     Id class = cd.name;
     str comment = "\n// <cd.name>\n\n";
     bool first = true;
     
     for (/(Method)`<Pattern p> = primitive` := cd) {
       if (first) {
         src += comment;
         first = false;
       }
       Selector selector = pattern2selector(p);
       str args = "[<intercalate(", ", [ "Ref <x>" | Id x <- params(p) ])>]";
     
       src += "Ref eval((Id)`<class>`, (Selector)`<selector>`, Ref self, <args>, Ctx ctx) 
              '  = notImplemented((Id)`<class>`, (Selector)`<selector>`, ctx);\n\n";
     } 
  }
  
  return src;
  
}

Selector makeSelector([Keyword k]) = (Selector)`<Keyword k>`;

Selector makeSelector([Keyword k, *ks]) = (Selector)`<Keyword k><Keyword+ kws>`
  when 
    (Selector)`<Keyword+ kws>` := makeSelector(ks);
 
list[Method] methods(ClassBody body, bool isClass) {
  if (!isClass) {
    return [ m | Method m <- body.methods ];
  }
  if ((ClassBody)`<Locals? _> <Method* _> <ClassDecls cd>` := body) {
    return [ m | Method m <- cd.methods ];
  }
  return [];
}


bool match((Pattern)`<UnarySelector u1>`, (Selector)`<UnarySelector u2>`) = u1 == u2;

bool match((Pattern)`<BinarySelector b1> <Id _>`, (Selector)`<BinarySelector b2>`) = b1 == b2;

bool match((Pattern)`<KeywordArg+ kwas>`, (Selector)`<Keyword+ kws>`)
  = [ k | (KeywordArg)`<Keyword k> <Id _>` <- kwas ] == [ k | Keyword k <- kws ];
  
default bool match(Pattern _, Selector _) = false; 


