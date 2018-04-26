module lang::som::IDE

import util::IDE;
import lang::som::SOM;
import ParseTree;

void main() {
  registerLanguage("SOM", "som", start[Program](str src, loc l) {
    return parse(#start[Program], src, l);
  });
}