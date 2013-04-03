{- |
Example that squares the first (int) parameter, using two loops. Combination of Bounded and Bounded2.

Pseudo-Java:

int p (int a0) {
  var x0 = 0;
  var x1 = 0;
  x1 = a0;
  while (x1 > 0) {
    x0 = x0 + a0;
    x1 = x1 - 1;
  }
  x1 = 0;
  var x2 = 0;
  while (x1 < 1) {
    x2 = x0 + x2;
    x1 = x1 + 1;
  }
  return x2;
}

Pre:  a0 >= 0
Post: return == a0*a0

Part of PV - Project 3.

Authors: Jaap van der Plas and Danny Bergsma
Version: 0.1, 3 April 2013
-}

module PV3.Examples.Bounded3 where

import PV3.Condition.ConditionAST
import PV3.Program.ProgramAST

{- | A Java-like equivalent of this program would be:

  prog P(a0) {
   
  }
-}
body :: StatementList
body = [SInstruction (InstSetLocal  0 (LInt 0)),
        SInstruction (InstSetLocal  1 (LInt 0)),
        SInstruction (InstLoadParam 0),
        SInstruction (InstStoreLocal 1),
        SInstruction (InstLoadLocal 1),
        SInstruction (InstPushLiteral (LInt 0)),
        SInstruction InstGT,
        SWhileTrue   [SInstruction (InstLoadLocal 0), 
                      SInstruction (InstLoadParam 0), 
                      SInstruction InstAdd, 
                      SInstruction (InstStoreLocal 0), 
                      SInstruction (InstLoadLocal 1),
                      SInstruction (InstPushLiteral (LInt 1)),
                      SInstruction InstMin,
                      SInstruction (InstStoreLocal 1),
                      SInstruction (InstLoadLocal 1),
                      SInstruction (InstPushLiteral (LInt 0)),
                      SInstruction InstGT],
        SInstruction (InstSetLocal  1 (LInt 0)),
        SInstruction (InstSetLocal  2 (LInt 0)),
        SInstruction (InstLoadLocal 1),
        SInstruction (InstPushLiteral (LInt 1)),
        SInstruction InstLT,
        SWhileTrue   [SInstruction (InstLoadLocal 0), 
                      SInstruction (InstLoadLocal 2), 
                      SInstruction InstAdd, 
                      SInstruction (InstStoreLocal 2), 
                      SInstruction (InstLoadLocal 1),
                      SInstruction (InstPushLiteral (LInt 1)),
                      SInstruction InstAdd,
                      SInstruction (InstStoreLocal 1),
                      SInstruction (InstLoadLocal 1),
                      SInstruction (InstPushLiteral (LInt 1)),
                      SInstruction InstLT],
        SInstruction (InstLoadLocal 2),
        SInstruction Instreturn]

program :: Program
program = Program 1 3 body
                       
postcondition :: Cond
postcondition = CEQ IReturnValue (IMul (IParamOld 0) (IParamOld 0))

precondition :: Cond
precondition = CGTE (IParamOld 0) (ILit 0)