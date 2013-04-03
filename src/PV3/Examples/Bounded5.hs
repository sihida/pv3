{- |
Example that squares the first (int) parameter, using one outer and one inner loop.

Part of PV - Project 3.

Authors: Jaap van der Plas and Danny Bergsma
Version: 0.1, 2 April 2013
-}
module PV3.Examples.Bounded5 where

import PV3.Condition.ConditionAST
import PV3.Program.ProgramAST

{- | A Java-like equivalent of this program would be:

  prog P(a0) {
    var x0 = 0;
    var x1 = a0;
    while (x1 > 0) {
      x1--;
      var x2 = 0;
      while (x2 > 0) {
        x2--;
        x0++;
      }
    }
    return x0;
  }
-}
body :: StatementList
body = [SInstruction (InstSetLocal 0 (LInt 0)),  -- local0 := 0
        SInstruction (InstLoadParam 0),          -- push param0
        SInstruction (InstStoreLocal 1),         -- local1 := param0
        SInstruction (InstLoadLocal 1),          -- push local1
        SInstruction (InstPushLiteral (LInt 0)), -- push 0
        SInstruction (InstGT),                   -- while local1 > 0
        SWhileTrue   [SInstruction (InstLoadLocal 1),          -- push local1
                      SInstruction (InstPushLiteral (LInt 1)), -- push 1
                      SInstruction (InstMin),                  -- local1 - 1
                      SInstruction (InstStoreLocal 1),         -- local1 := local1 - 1
                      SInstruction (InstLoadParam 0),          -- push param0
                      SInstruction (InstStoreLocal 2),         -- local2 := param0
                      SInstruction (InstLoadLocal 2),          -- push local2
                      SInstruction (InstPushLiteral (LInt 0)), -- push 0
                      SInstruction (InstGT),                   -- while local2 > 0
                      SWhileTrue   [SInstruction (InstLoadLocal 2),          -- push local2
                                    SInstruction (InstPushLiteral (LInt 1)), -- push 1
                                    SInstruction (InstMin),                  -- local2 - 1
                                    SInstruction (InstStoreLocal 2),         -- local2 := local2 -1
                                    SInstruction (InstLoadLocal 0),          -- push local0
                                    SInstruction (InstPushLiteral (LInt 1)), -- push 1
                                    SInstruction (InstAdd),                  -- local0 + 1
                                    SInstruction (InstStoreLocal 0),         -- local0 := local0 + 1
                                    SInstruction (InstLoadLocal 2),          -- push local2
                                    SInstruction (InstPushLiteral (LInt 0)), -- push 0
                                    SInstruction (InstGT)],                  -- local > 0
                      SInstruction (InstLoadLocal 1),          -- push local1
                      SInstruction (InstPushLiteral (LInt 0)), -- push 0
                      SInstruction (InstGT)],                  -- local1 > 0
        SInstruction (InstLoadLocal 0),          -- push local0
        SInstruction (Instreturn)]               -- return local0

program :: Program
program = Program 1 3 body
                       
postcondition :: Cond
postcondition = CEQ IReturnValue (IMul (IParamOld 0) (IParamOld 0))

precondition :: Cond
precondition = CGTE (IParamOld 0) (ILit 0)
