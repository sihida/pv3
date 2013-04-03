{- |
Example that just returns the first parameter, but uses a (useless) loop for this. To test bounded verification.

Pseudo-Java:
int P (int a0) {
  var x0 = 0;
  var x1 = 0;
  while (x1 < 1) {
    x0 = x0 + a0;
    x1 = x1 + 1;
  }
  return x0;
}

Pre:  true
Post: return == a0

Part of PV - Project 3.

Authors: Jaap van der Plas and Danny Bergsma
Version: 0.1, 3 April 2013
-}

module PV3.Examples.Bounded2 where

import PV3.Condition.ConditionAST
import PV3.Program.ProgramAST

body :: StatementList
body = [SInstruction (InstSetLocal  0 (LInt 0)),
        SInstruction (InstSetLocal  1 (LInt 0)),
        SInstruction (InstLoadLocal 1),
        SInstruction (InstPushLiteral (LInt 1)),
        SInstruction InstLT,
        SWhileTrue   [SInstruction (InstLoadLocal 0), 
                      SInstruction (InstLoadParam 0), 
                      SInstruction InstAdd, 
                      SInstruction (InstStoreLocal 0), 
                      SInstruction (InstLoadLocal 1),
                      SInstruction (InstPushLiteral (LInt 1)),
                      SInstruction InstAdd,
                      SInstruction (InstStoreLocal 1),
                      SInstruction (InstLoadLocal 1),
                      SInstruction (InstPushLiteral (LInt 1)),
                      SInstruction InstLT],
        SInstruction (InstLoadLocal 0),
        SInstruction Instreturn]
                
program :: Program
program = Program 1 2 body
                       
postcondition :: Cond
postcondition = CEQ IReturnValue (IParamOld 0) 

precondition :: Cond
precondition = CLit True