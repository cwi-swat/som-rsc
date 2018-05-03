module lang::som::Test

import lang::som::SOM;
import ParseTree;
import util::FileSystem;
import IO;

void runAll() {
  root = |project://rascal-som/src/lang/som/examples/benchmarks|;
  stdlib = |project://rascal-som/src/lang/som/stdlib|;
  for(loc l <- files(root) + files(stdlib), l.extension == "som") {
    try {
      parse(#start[Program], l);
      println("Success <l>");
    }
    catch p:ParseError(_): {
      println(p);    
    }
    catch Ambiguity(_, _, _): {
      println("Amb for <l>:");
    } 
  }
 
}