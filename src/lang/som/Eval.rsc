module lang::som::Eval

import lang::som::SOM;
import lang::som::Heap;
import lang::som::Primitives;

import util::FileSystem;
import ParseTree;
import String;
import IO;
import util::Maybe;

Ref identityK(Ref v) = v;

str eval(Expr e) {
  <heap, env> = boot();
  Ref result = eval(e, <heap, env, identityK, identityK>);
  Obj obj = heap.deref(result);
  return "<heap.deref(obj.class).name>: <obj2str(obj)>";
}

tuple[Heap, Env] boot(list[loc] classPath = [|project://rascal-som/src/lang/som/stdlib|]) {
  // bug, becomes list of Tree
  list[Tree] soms = [ parse(#start[Program], f) | loc dir <- classPath, loc f <- files(dir) ];
  
  Env env = ();
  Heap heap = newHeap();
  
  // preallocate classes
  for (start[Program] p <- soms, ClassDef cd <- p.top.defs) {
    Ref c = heap.alloc(class(null(), null(), (), (), cd.name, cd.body));
    env[cd.name] = c;
  }

  // NB: nil is needed as superclass for Object
  env[NIL] = heap.alloc(object(env[(Id)`Nil`], ()));
  env[TRUE] = heap.alloc(object(env[(Id)`True`], ()));
  env[FALSE] = heap.alloc(object(env[(Id)`False`], ()));
  env[SYSTEM] = heap.alloc(object(env[(Id)`System`], ()));
  
  // TODO: initialize class fields to nil
  for (start[Program] p <- soms, ClassDef cd <- p.top.defs) {
    obj = heap.deref(env[cd.name]);
    obj.class = env[(Id)`Metaclass`];
    if ((ClassDef)`<Id _> = <Id sup> (<ClassBody _>)` := cd) {
      obj.super = env[sup];
    }
    else {
      obj.super = env[(Id)`Object`]; 
    }
    obj.env = env; // class defs capture the current (global) environment
    heap.put(env[cd.name], obj);
  }
  
  return <heap, env>;  
}

/*
 * Statements
 */

Ref eval(BlockContents? b, Ctx ctx) 
  = size(b.args) > 0 ? eval(b.args[0], ctx) : ctx.next(ctx.env[NIL]);
 
Ref eval((BlockContents)`|<Id* xs>| <{Stmt Dot}+ stms> <Dot? _>`, Ctx ctx) {
  for (Id x <- xs) {
    ctx.env[x] = ctx.heap.alloc(ctx.env[NIL]);
  }
  return eval((BlockContents)`<{Stmt Dot}+ stms>`, ctx);
} 

Ref eval((BlockContents)`<Stmt s>. <{Stmt Dot}+ ss> <Dot? _>`, Ctx ctx) 
  = eval(s, ctx[next=Ref(Ref v) { return eval((BlockContents)`<{Stmt Dot}+ ss>`, ctx); }]);

Ref eval((BlockContents)`<Stmt s> <Dot? _>`, Ctx ctx) 
  = eval(s, ctx); 

Ref eval((Stmt)`<Expr e>`, Ctx ctx) = eval(e, ctx);

Ref eval((Stmt)`^<Expr e>`, Ctx ctx)  = eval(e, ctx[next=ctx.hat]);


/*
 * Expressions
 */

Ref eval((Expr)`<Id x>`, Ctx ctx) = ctx.next(ctx.env[x]);

Ref eval((Expr)`(<Expr e>)`, Ctx ctx) = eval(e, ctx);

Ref eval((Expr)`<Symbol s>`, Ctx ctx) 
  = ctx.next(ctx.heap.alloc(primitive(ctx.env[(Id)`Symbol`], "<s>"[1..])));

Ref eval((Expr)`<String s>`, Ctx ctx) 
  = ctx.next(ctx.heap.alloc(primitive(ctx.env[(Id)`String`], "<s>"[1..-1])));

Ref eval((Expr)`<Integer n>`, Ctx ctx) 
  = ctx.next(ctx.heap.alloc(primitive(ctx.env[(Id)`Integer`], toInt("<n>"))));

Ref eval((Expr)`<Double n>`, Ctx ctx) 
  = ctx.next(ctx.heap.alloc(primitive(ctx.env[(Id)`Double`], toReal("<n>"))));
 
Ref eval(b:(Expr)`[<BlockContents? _>]`, Ctx ctx) 
  = ctx.next(ctx.heap.alloc(block(ctx.env[(Id)`Block`], ctx.env, ctx.hat, b)));

Ref eval(b:(Expr)`[:<Id x> | <BlockContents? _>]`, Ctx ctx) 
  = ctx.next(ctx.heap.alloc(block(ctx.env[(Id)`Block1`], ctx.env, ctx.hat, b)));

Ref eval(b:(Expr)`[:<Id x> :<Id y> | <BlockContents? _>]`, Ctx ctx) 
  = ctx.next(ctx.heap.alloc(block(ctx.env[(Id)`Block2`], ctx.env, ctx.hat, b)));

Ref eval(b:(Expr)`[:<Id x> :<Id y> :<Id z> | <BlockContents? _>]`, Ctx ctx) 
  = ctx.next(ctx.heap.alloc(block(ctx.env[(Id)`Block3`], ctx.env, ctx.hat, b)));

Ref eval((Expr)`<Expr e> <UnarySelector u>`, Ctx ctx)
  = eval(e, ctx[next=Ref(Ref v) { 
      return dispatch((Selector)`<UnarySelector u>`, v, [], ctx); 
    }]);

Ref eval((Expr)`<Expr e1> <BinarySelector b> <Expr e2>`, Ctx ctx) 
 = eval(e1, ctx[next=Ref(Ref v1) { 
     return eval(e2, ctx[next=Ref(Ref v2) {
        return dispatch((Selector)`<BinarySelector b>`, v1, [v2], ctx); 
      }]); 
   }]);


Ref eval((Expr)`<Expr e> <KeywordForms kws>`, Ctx ctx) 
 = eval(e, ctx[next=Ref(Ref v) { 
     return eval(kws, v, [], [], ctx);
   }]);


Ref eval((KeywordForms)`<KeywordForm kw>`, Ref recv, list[Keyword] ks, list[Ref] args, Ctx ctx)
  = eval(kw.expr, ctx[next=Ref(Ref v) {
      return dispatch(makeSelector(ks + [kw.key]), recv, args + [v], ctx);
    }]);

Ref eval((KeywordForms)`<KeywordForm kw> <KeywordForm+ kws>`, Ref recv, list[Keyword] ks, list[Ref] args, Ctx ctx)
  = eval(kw.expr, ctx[next=Ref(Ref v) {
      return eval(kws, recv, ks + [kw.key], args + [v], ctx);
    }]);


/*
 * Dispatching selectors
 */
  
Ref dispatch(Selector selector, Ref recv, list[Ref] args, Ctx ctx) {
  Obj obj = ctx.heap.deref(recv);
  if (obj is class) {
    return dispatchVia(obj, selector, recv, args, ctx);
  }
  return dispatchVia(ctx.heap.deref(obj.class), selector, obj is super ? obj.self : recv, args, ctx);
}


Ref dispatchVia(Obj class, Selector selector, Ref recv, list[Ref] args, Ctx ctx) {
  Obj obj = ctx.heap.deref(recv);

  if (just(<Method m, Id found>) := lookup(class, obj is class, selector, ctx)) {
    //println("Found <selector> in <found>");
    //println("Calling <selector> on <obj2str(obj)>");

    if (m has contents) {
      Env env = class.env; // start with the class-level captured environment.
      env += obj has fields ? obj.fields : (); // add the fields, if any
      env += (SELF: recv); // add self
      env += (SUPER: ctx.heap.alloc(super(class.super, recv))); // add the super "object"
      env += paramEnv(m.pattern, args); // and the parameters
      
      // if method ends without ^ what does it return? Last expression result or nil?
      return eval(m.contents, ctx[hat=ctx.next][env=env]);
    }

    // primitive
    return eval(found, selector, recv, args, ctx);
  }
  
  return doesNotUnderstand(selector, recv, args, ctx);
}


Ref doesNotUnderstand(Selector selector, Ref recv, list[Ref] args, Ctx ctx) {
  Selector dnu = (Selector)`doesNotUnderstand:arguments:`;
  Ref sym = ctx.heap.alloc(primitive(ctx.env[(Id)`Symbol`], "<selector>"));
  Ref argArray = ctx.heap.alloc(primitive(ctx.env[(Id)`Array`], args));
  return dispatch(dnu, recv, [sym, argArray], ctx);
}


Maybe[tuple[Method, Id]] lookup(Obj class, bool isClass, Selector selector, Ctx ctx) {
  //println("Lookup in <obj2str(class)> (isClass = <isClass>) of <selector>");
  if (Method m <- methods(class.body, isClass), match(m.pattern, selector)) {
    //println("Matched <m.pattern> to <selector>");
    return just(<m, class.name>);
  }
  
  if (class.super != ctx.env[NIL]) {
    return lookup(ctx.heap.deref(class.super), isClass, selector, ctx);
  }
  
  if (isClass, class.super == ctx.env[NIL]) {
    return lookup(ctx.heap.deref(ctx.env[(Id)`Class`]), false, selector, ctx);
  }
  
  return nothing();
}

/*
 * Utilities
 */
 
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


Env paramEnv((Pattern)`<UnarySelector _>`, list[Ref] _) = ();

Env paramEnv((Pattern)`<BinarySelector _> <Id x>`, list[Ref] args) = (x: args[0]);

Env paramEnv((Pattern)`<KeywordArg+ kws>`, list[Ref] args) 
  = ( xs[i]: args[i] | int i <- [0..size(xs)] ) 
  when 
    list[Id] xs := [ x | (KeywordArg)`<Keyword _> <Id x>` <- kws ]; 



