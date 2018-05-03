module lang::som::Primitives

import lang::som::Heap;
import lang::som::SOM;
import lang::som::Eval;
import String;
import IO;


Ref notImplemented(Id class, Selector s, Ctx ctx)
  = ctx.heap.alloc(primitive(ctx.env[(Id)`String`], "ASSERTION FAILED: Unimplemented primitive <class>\>\><s>"));


// stop evaluation when no implementation was found for a primitive.
default Ref eval(Id class, Selector s, Ref self, list[Ref] args, Ctx ctx) 
  = notImplemented(class, s, ctx);
  

// System

Ref eval((Id)`System`, (Selector)`global:`, Ref self, [Ref name], Ctx ctx) 
  = notImplemented((Id)`System`, (Selector)`global:`, ctx);

Ref eval((Id)`System`, (Selector)`global:put:`, Ref self, [Ref name, Ref \value], Ctx ctx) 
  = notImplemented((Id)`System`, (Selector)`global:put:`, ctx);

Ref eval((Id)`System`, (Selector)`hasGlobal:`, Ref self, [Ref name], Ctx ctx) 
  = notImplemented((Id)`System`, (Selector)`hasGlobal:`, ctx);

Ref eval((Id)`System`, (Selector)`load:`, Ref self, [Ref symbol], Ctx ctx) 
  = notImplemented((Id)`System`, (Selector)`load:`, ctx);

Ref eval((Id)`System`, (Selector)`exit:`, Ref self, [Ref arg], Ctx ctx) = arg;


Ref eval((Id)`System`, (Selector)`printString:`, Ref self, [Ref s], Ctx ctx) {
  print(ctx.heap.deref(s).val);
  return ctx.next(ctx.env[NIL]);
}

Ref eval((Id)`System`, (Selector)`printNewline`, Ref self, [], Ctx ctx) {
  println("");
  return ctx.next(ctx.env[NIL]);
}


Ref eval((Id)`System`, (Selector)`time`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`System`, (Selector)`time`, ctx);

Ref eval((Id)`System`, (Selector)`ticks`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`System`, (Selector)`ticks`, ctx);

Ref eval((Id)`System`, (Selector)`fullGC`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`System`, (Selector)`fullGC`, ctx);


// Primitive

Ref eval((Id)`Primitive`, (Selector)`signature`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Primitive`, (Selector)`signature`, ctx);

Ref eval((Id)`Primitive`, (Selector)`holder`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Primitive`, (Selector)`holder`, ctx);

Ref eval((Id)`Primitive`, (Selector)`invokeOn:with:`, Ref self, [Ref obj, Ref args], Ctx ctx) 
  = notImplemented((Id)`Primitive`, (Selector)`invokeOn:with:`, ctx);


// Block

//Ref eval((Id)`Block`, (Selector)`value`, Ref self, [], Ctx ctx)
//  = eval(c, ctx[hat=hat][env=env])
//  when
//    block(_, Env env, K hat, (Expr)`[<<BlockContents? c>]`) := ctx.heap.deref(self);

Ref eval((Id)`Block`, (Selector)`restart`, Ref self, [], Ctx ctx) 
  = ctx.next(restart())
  when
    block(_, Env _, K _, _, restart = restart) := ctx.heap.deref(self);


// Object

Ref eval((Id)`Object`, (Selector)`class`, Ref self, [], Ctx ctx) 
  = ctx.next(ctx.heap.deref(self).class);   

Ref eval((Id)`Object`, (Selector)`objectSize`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Object`, (Selector)`objectSize`, ctx);

Ref eval((Id)`Object`, (Selector)`==`, Ref self, [Ref other], Ctx ctx) 
  = notImplemented((Id)`Object`, (Selector)`==`, ctx);

Ref eval((Id)`Object`, (Selector)`hashcode`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Object`, (Selector)`hashcode`, ctx);

Ref eval((Id)`Object`, (Selector)`inspect`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Object`, (Selector)`inspect`, ctx);

Ref eval((Id)`Object`, (Selector)`halt`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Object`, (Selector)`halt`, ctx);

Ref eval((Id)`Object`, (Selector)`perform:`, Ref self, [Ref aSymbol], Ctx ctx) 
  = notImplemented((Id)`Object`, (Selector)`perform:`, ctx);

Ref eval((Id)`Object`, (Selector)`perform:withArguments:`, Ref self, [Ref aSymbol, Ref args], Ctx ctx) 
  = notImplemented((Id)`Object`, (Selector)`perform:withArguments:`, ctx);

Ref eval((Id)`Object`, (Selector)`perform:inSuperclass:`, Ref self, [Ref aSymbol, Ref cls], Ctx ctx) 
  = notImplemented((Id)`Object`, (Selector)`perform:inSuperclass:`, ctx);

Ref eval((Id)`Object`, (Selector)`perform:withArguments:inSuperclass:`, Ref self, [Ref aSymbol, Ref args, Ref cls], Ctx ctx) 
  = notImplemented((Id)`Object`, (Selector)`perform:withArguments:inSuperclass:`, ctx);

Ref eval((Id)`Object`, (Selector)`instVarAt:`, Ref self, [Ref idx], Ctx ctx) 
  = notImplemented((Id)`Object`, (Selector)`instVarAt:`, ctx);

Ref eval((Id)`Object`, (Selector)`instVarAt:put:`, Ref self, [Ref idx, Ref obj], Ctx ctx) 
  = notImplemented((Id)`Object`, (Selector)`instVarAt:put:`, ctx);

Ref eval((Id)`Object`, (Selector)`instVarNamed:`, Ref self, [Ref sym], Ctx ctx) 
  = notImplemented((Id)`Object`, (Selector)`instVarNamed:`, ctx);


// Block1

Ref eval((Id)`Block1`, (Selector)`value`, Ref self, [], Ctx ctx) { 
  Obj b = ctx.heap.deref(self);
  if (block(_, Env env, K hat, (Expr)`[<BlockContents? c>]`) := b) {
    Ref restart() {
      return  eval(c, ctx[hat=hat][env=env]);
    }
    b.restart = restart;
    ctx.heap.put(self, b);
    return restart();
  }
  fail;
}    

// Block2

Ref eval((Id)`Block2`, (Selector)`value:`, Ref self, [Ref argument], Ctx ctx) {
  Obj b = ctx.heap.deref(self);
  if (block(_, Env env, K hat, (Expr)`[ :<Id x> | <BlockContents? c>]`) := b) {
    Ref restart() {
      return  eval(c, ctx[hat=hat][env=env + (x: argument)]);
    }
    b.restart = restart;
    ctx.heap.put(self, b);
    return restart();
  }
 fail;
}    


// Block3

Ref eval((Id)`Block3`, (Selector)`value:with:`, Ref self, [Ref arg1, Ref arg2], Ctx ctx) 
= eval(c, ctx[hat=hat][env=env + (x: arg1,  y: arg2)])
  when
    block(_, Env env, K hat, (Expr)`[ :<Id x> :<Id y> | <BlockContents? c>]`) := ctx.heap.deref(self);


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

Ref eval((Id)`Class`, (Selector)`superclass`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Class`, (Selector)`superclass`, ctx);

Ref eval((Id)`Class`, (Selector)`fields`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Class`, (Selector)`fields`, ctx);

Ref eval((Id)`Class`, (Selector)`methods`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Class`, (Selector)`methods`, ctx);


// Array

Ref eval((Id)`Array`, (Selector)`at:`, Ref self, [Ref index], Ctx ctx) 
  = notImplemented((Id)`Array`, (Selector)`at:`, ctx);

Ref eval((Id)`Array`, (Selector)`at:put:`, Ref self, [Ref index, Ref \value], Ctx ctx) 
  = notImplemented((Id)`Array`, (Selector)`at:put:`, ctx);

Ref eval((Id)`Array`, (Selector)`length`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Array`, (Selector)`length`, ctx);

Ref eval((Id)`Array`, (Selector)`new:`, Ref self, [Ref length], Ctx ctx) 
  = notImplemented((Id)`Array`, (Selector)`new:`, ctx);


// Integer

Ref eval((Id)`Integer`, (Selector)`+`, Ref self, [Ref arg], Ctx ctx) 
  = ctx.next(ctx.heap.alloc(primitive(ctx.env[(Id)`Integer`], x + y)))
  when
    primitive(_, int x) := ctx.heap.deref(self), 
    primitive(_, int y) := ctx.heap.deref(arg);

Ref eval((Id)`Integer`, (Selector)`-`, Ref self, [Ref argument], Ctx ctx) 
  = ctx.next(ctx.heap.alloc(primitive(ctx.env[(Id)`Integer`], x - y)))
  when
    primitive(_, int x) := ctx.heap.deref(self), 
    primitive(_, int y) := ctx.heap.deref(argument);

Ref eval((Id)`Integer`, (Selector)`*`, Ref self, [Ref argument], Ctx ctx) 
  = ctx.next(ctx.heap.alloc(primitive(ctx.env[(Id)`Integer`], x * y)))
  when
    primitive(_, int x) := ctx.heap.deref(self), 
    primitive(_, int y) := ctx.heap.deref(argument);

Ref eval((Id)`Integer`, (Selector)`/`, Ref self, [Ref argument], Ctx ctx) 
  = ctx.next(ctx.heap.alloc(primitive(ctx.env[(Id)`Integer`], x / y)))
  when
    primitive(_, int x) := ctx.heap.deref(self), 
    primitive(_, int y) := ctx.heap.deref(argument);

Ref eval((Id)`Integer`, (Selector)`//`, Ref self, [Ref argument], Ctx ctx) 
  = notImplemented((Id)`Integer`, (Selector)`//`, ctx);

Ref eval((Id)`Integer`, (Selector)`%`, Ref self, [Ref argument], Ctx ctx) 
  = notImplemented((Id)`Integer`, (Selector)`%`, ctx);

Ref eval((Id)`Integer`, (Selector)`rem:`, Ref self, [Ref argument], Ctx ctx) 
  = notImplemented((Id)`Integer`, (Selector)`rem:`, ctx);

Ref eval((Id)`Integer`, (Selector)`&`, Ref self, [Ref argument], Ctx ctx) 
  = notImplemented((Id)`Integer`, (Selector)`&`, ctx);

Ref eval((Id)`Integer`, (Selector)`\<\<`, Ref self, [Ref argument], Ctx ctx) 
  = notImplemented((Id)`Integer`, (Selector)`\<\<`, ctx);

Ref eval((Id)`Integer`, (Selector)`\>\>\>`, Ref self, [Ref argument], Ctx ctx) 
  = notImplemented((Id)`Integer`, (Selector)`\>\>\>`, ctx);

Ref eval((Id)`Integer`, (Selector)`bitXor:`, Ref self, [Ref argument], Ctx ctx) 
  = notImplemented((Id)`Integer`, (Selector)`bitXor:`, ctx);

Ref eval((Id)`Integer`, (Selector)`sqrt`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Integer`, (Selector)`sqrt`, ctx);

Ref eval((Id)`Integer`, (Selector)`atRandom`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Integer`, (Selector)`atRandom`, ctx);

Ref eval((Id)`Integer`, (Selector)`=`, Ref self, [Ref argument], Ctx ctx) 
  = ctx.next(x == y ? ctx.env[TRUE] : ctx.env[FALSE])
  when
    primitive(_, int x) := ctx.heap.deref(self), 
    primitive(_, int y) := ctx.heap.deref(argument);

Ref eval((Id)`Integer`, (Selector)`\<`, Ref self, [Ref argument], Ctx ctx) 
  = ctx.next(x < y ? ctx.env[TRUE] : ctx.env[FALSE])
  when
    primitive(_, int x) := ctx.heap.deref(self), 
    primitive(_, int y) := ctx.heap.deref(argument);

Ref eval((Id)`Integer`, (Selector)`asString`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Integer`, (Selector)`asString`, ctx);

Ref eval((Id)`Integer`, (Selector)`as32BitSignedValue`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Integer`, (Selector)`as32BitSignedValue`, ctx);

Ref eval((Id)`Integer`, (Selector)`as32BitUnsignedValue`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Integer`, (Selector)`as32BitUnsignedValue`, ctx);

Ref eval((Id)`Integer`, (Selector)`fromString:`, Ref self, [Ref aString], Ctx ctx) 
  = notImplemented((Id)`Integer`, (Selector)`fromString:`, ctx);


// Double

Ref eval((Id)`Double`, (Selector)`+`, Ref self, [Ref argument], Ctx ctx) 
  = notImplemented((Id)`Double`, (Selector)`+`, ctx);

Ref eval((Id)`Double`, (Selector)`-`, Ref self, [Ref argument], Ctx ctx) 
  = notImplemented((Id)`Double`, (Selector)`-`, ctx);

Ref eval((Id)`Double`, (Selector)`*`, Ref self, [Ref argument], Ctx ctx) 
  = notImplemented((Id)`Double`, (Selector)`*`, ctx);

Ref eval((Id)`Double`, (Selector)`//`, Ref self, [Ref argument], Ctx ctx) 
  = notImplemented((Id)`Double`, (Selector)`//`, ctx);

Ref eval((Id)`Double`, (Selector)`%`, Ref self, [Ref argument], Ctx ctx) 
  = notImplemented((Id)`Double`, (Selector)`%`, ctx);

Ref eval((Id)`Double`, (Selector)`sqrt`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Double`, (Selector)`sqrt`, ctx);

Ref eval((Id)`Double`, (Selector)`round`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Double`, (Selector)`round`, ctx);

Ref eval((Id)`Double`, (Selector)`asInteger`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Double`, (Selector)`asInteger`, ctx);

Ref eval((Id)`Double`, (Selector)`cos`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Double`, (Selector)`cos`, ctx);

Ref eval((Id)`Double`, (Selector)`sin`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Double`, (Selector)`sin`, ctx);

Ref eval((Id)`Double`, (Selector)`=`, Ref self, [Ref argument], Ctx ctx) 
  = notImplemented((Id)`Double`, (Selector)`=`, ctx);

Ref eval((Id)`Double`, (Selector)`\<`, Ref self, [Ref argument], Ctx ctx) 
  = notImplemented((Id)`Double`, (Selector)`\<`, ctx);

Ref eval((Id)`Double`, (Selector)`asString`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Double`, (Selector)`asString`, ctx);

Ref eval((Id)`Double`, (Selector)`PositiveInfinity`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Double`, (Selector)`PositiveInfinity`, ctx);


// String

Ref eval((Id)`String`, (Selector)`concatenate:`, Ref self, [Ref arg], Ctx ctx) 
  = ctx.next(ctx.heap.alloc(primitive(ctx.env[(Id)`String`], s1 + s2)))
  when 
    primitive(_, str s1) := ctx.heap.deref(self), 
    primitive(_, str s2) := ctx.heap.deref(arg);

Ref eval((Id)`String`, (Selector)`asSymbol`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`String`, (Selector)`asSymbol`, ctx);

Ref eval((Id)`String`, (Selector)`hashcode`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`String`, (Selector)`hashcode`, ctx);

Ref eval((Id)`String`, (Selector)`length`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`String`, (Selector)`length`, ctx);

Ref eval((Id)`String`, (Selector)`=`, Ref self, [Ref argument], Ctx ctx) 
  = notImplemented((Id)`String`, (Selector)`=`, ctx);

Ref eval((Id)`String`, (Selector)`primSubstringFrom:to:`, Ref self, [Ref \start, Ref end], Ctx ctx) 
  = notImplemented((Id)`String`, (Selector)`primSubstringFrom:to:`, ctx);


// Symbol

Ref eval((Id)`Symbol`, (Selector)`asString`, Ref self, [], Ctx ctx) 
  = ctx.next(ctx.heap.alloc(primitive(ctx.env[(Id)`String`], sym)))
  when
    primitive(_, str sym) := ctx.heap.deref(self);


// Method

Ref eval((Id)`Method`, (Selector)`signature`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Method`, (Selector)`signature`, ctx);

Ref eval((Id)`Method`, (Selector)`holder`, Ref self, [], Ctx ctx) 
  = notImplemented((Id)`Method`, (Selector)`holder`, ctx);

Ref eval((Id)`Method`, (Selector)`invokeOn:with:`, Ref self, [Ref obj, Ref args], Ctx ctx) 
  = notImplemented((Id)`Method`, (Selector)`invokeOn:with:`, ctx);

  
  