module lang::som::Heap

import lang::som::SOM;
import List;

data Ref
  = ref(int id)
  | null()
  ;

data Obj
  = object(Ref class, Env fields)
  | super(Ref class, Ref self)
  | class(Ref class, Ref super, Env fields, Env env, Id name, ClassBody body)
  | block(Ref class, Env env, K hat, Expr block)
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
