module lang::som::Heap

import lang::som::SOM;
import List;
import util::FileSystem;
import ParseTree;

// Constants
public Id NIL = (Id)`nil`;
public Id TRUE = (Id)`true`;
public Id FALSE = (Id)`false`;
public Id SELF = (Id)`self`;
public Id SUPER = (Id)`super`;
public Id SYSTEM = (Id)`system`;


data Ref
  = ref(int id)
  | null()
  ;

data Obj
  = object(Ref class, Env fields)
  | super(Ref class, Ref self)
  | class(Ref class, Ref super, Env fields, Env env, Id name, ClassBody body)
  | block(Ref class, Env env, K hat, Expr block, Ref() restart = Ref() { return null(); })
  | primitive(Ref class, value val) 
  ;

alias Heap = tuple[Ref(Obj) alloc, void(Ref, Obj) put, Obj(Ref) deref, map[Ref,Obj]() inspect, str() toString];

alias Env = map[Id var, Ref ref];

alias Ctx = tuple[Heap heap, Env env, K next, K hat];  

alias K = Ref(Ref);

str obj2str(Obj obj) {
  if (obj is class) {
    return "class(<obj.class>, <obj.super>, <envInline(obj.fields)>, <obj.name>)";
  }
  if (obj is block) {
    return "block(<obj.class>)";
  }
  if (obj is object) {
    return "object(<obj.class>, <envInline(obj.fields)>)";
  }
  return "<obj>";
}

str envInline(Env env) = "(" + intercalate(", ", [ "<k>: <env[k]>" | Id k <- env ]) + ")";

str envStr(Env env) {
  str s = "";
  for (Id k <- env) {
    s += "<k>: <env[k]>\n";
  }
  return s[..-1];
}

Heap newHeap() {
  int id = 0;
  Heap this;
  map[Ref, Obj] mem = ();
  
  Ref alloc(Obj x) {
    Ref c = ref(id);
    mem[c] = x;
    id += 1;
    return c;
  }
  
  void put(Ref c, Obj x) {
    mem[c] = x;
  }
  
  Obj deref(Ref c) {
    return mem[c];
  }
  
  map[Ref, Obj] inspect() {
    return mem;
  }
  
  str toString() {
    str s = "";
    for (Ref k <- mem) {
      s += "<k>: <obj2str(mem[k])>\n";
    }
    return s[..-1];
  }
  
  return <alloc, put, deref, inspect, toString>;
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
