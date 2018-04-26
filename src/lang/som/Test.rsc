module lang::som::Test

import lang::som::SOM;
import ParseTree;
import util::FileSystem;
import IO;

void runAll() {
  root = |project://rascal-som/src/lang/som/examples/benchmarks|;
  for(loc l <- files(root), l.extension == "som") {
    try {
      parse(#start[Program], l);
    }
    catch p:ParseError(_): {
      println(p);    
    }
    catch Ambiguity(_, _, _): {
      println("Amb for <l>:");
    } 
  }
 
}