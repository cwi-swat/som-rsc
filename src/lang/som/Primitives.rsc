module lang::som::Primitives

import lang::som::Heap;
import lang::som::SOM;
import String;
import IO;

public Id NIL = (Id)`nil`;
public Id TRUE = (Id)`true`;
public Id FALSE = (Id)`false`;
public Id SELF = (Id)`self`;
public Id SUPER = (Id)`super`;
public Id SYSTEM = (Id)`system`;

// stop evaluation when no implementation was found for a primitive.
default Ref eval(Id class, Selector s, Ref self, list[Ref] args, Ctx ctx) =
  ctx.heap.alloc(primitive(ctx.env[(Id)`String`], "ASSERTION FAILED: Unimplemented primitive <class>\>\><s>"));

// System

Ref eval((Id)`System`, (Selector)`printString:`, Ref self, [Ref s], Ctx ctx) {
  //println("PRINTING: <obj2str(ctx.heap.deref(s))>");
  print(ctx.heap.deref(s).val);
  return ctx.next(ctx.env[NIL]);
}

Ref eval((Id)`System`, (Selector)`printNewline`, Ref self, [], Ctx ctx) {
  println("");
  return ctx.next(ctx.env[NIL]);
}

Ref eval((Id)`System`, (Selector)`exit:`, Ref self, [Ref arg], Ctx ctx) = arg;


// Symbol

Ref eval((Id)`Symbol`, (Selector)`asString`, Ref self, [], Ctx ctx) 
  = ctx.next(ctx.heap.alloc(primitive(ctx.env[(Id)`String`], sym)))
  when
    primitive(_, str sym) := ctx.heap.deref(self);


// String

Ref eval((Id)`String`, (Selector)`concatenate:`, Ref self, [Ref arg], Ctx ctx) 
  = ctx.next(ctx.heap.alloc(primitive(ctx.env[(Id)`String`], s1 + s2)))
  when 
    primitive(_, str s1) := ctx.heap.deref(self), 
    primitive(_, str s2) := ctx.heap.deref(arg);

// Class

Ref eval((Id)`Class`, (Selector)`new`, Ref self, [], Ctx ctx) {
  Obj class = ctx.heap.deref(self);
  Env fields = ();
  if ((ClassBody)`|<Id* xs>| <Method* _> <ClassDecls? _>` := class.body) {
    fields = ( x: ctx.env[NIL] | Id x <- xs );
  }
  return ctx.next(ctx.heap.alloc(object(self, fields)));
} 

Ref eval((Id)`Class`, (Selector)`name`, Ref self, [], Ctx ctx) 
  = ctx.next(ctx.heap.alloc(primitive(ctx.env[(Id)`Symbol`], "<ctx.heap.deref(self).name>")));
   
// Object

Ref eval((Id)`Object`, (Selector)`class`, Ref self, [], Ctx ctx) 
  = ctx.next(ctx.heap.deref(self).class);   
   
// Integer
 
Ref eval((Id)`Integer`, (Selector)`+`, Ref self, [Ref arg], Ctx ctx) 
  = ctx.next(ctx.heap.alloc(primitive(ctx.env[(Id)`Integer`], x + y)))
  when
    primitive(_, int x) := ctx.heap.deref(self), 
    primitive(_, int y) := ctx.heap.deref(arg);

// Block 
 
Ref eval((Id)`Block`, (Selector)`value`, Ref self, [], Ctx ctx)
  = eval(c, ctx[hat=hat])
  when
    block(_, Env env, K hat, (Expr)`[<BlockContents c>]`) := ctx.heap.deref(self);

Ref eval((Id)`Block`, (Selector)`value`, Ref self, [], Ctx ctx)
  = ctx.next(ctx.env[NIL])
  when
    block(_, Env _, K _, (Expr)`[]`) := ctx.heap.deref(self);
  
