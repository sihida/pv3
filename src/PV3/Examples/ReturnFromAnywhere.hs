{- |
Example from assignment, slightly altered to test the `return from anywhere' extension.

Pseudo-Java:
int p (int a0, int a1) {
  var x0 = 10;
  if (a0+a1 == x0) 
    return 1;
  return -1;
  return 1;
}

Pre:  true
Post: (a0 + a1 == 10) <==> (return == 1)

Part of PV - Project 3.

Authors: Jaap van der Plas and Danny Bergsma
Version: 0.1, 3 April 2013
-}

module PV3.Examples.ReturnFromAnywhere where

import PV3.Condition.ConditionAST
import PV3.Program.ProgramAST

body :: StatementList
body = [SInstruction (InstSetLocal  0 (LInt 10)),
        SInstruction (InstLoadParam 0),
        SInstruction (InstLoadParam 1),
        SInstruction InstAdd,
        SInstruction (InstLoadLocal 0),
        SInstruction InstEQ,
        SIfTrueElse  [SInstruction (InstPushLiteral (LInt 1)), SInstruction Instreturn] [],
        SInstruction (InstPushLiteral (LInt (-1))), 
        SInstruction Instreturn,
        SInstruction (InstPushLiteral (LInt 1)),
        SInstruction Instreturn]

program :: Program
program = Program 2 1 body
                       
postcondition :: Cond
postcondition = CEquiv (CEQ (IAdd (IParamOld 0) (IParamOld 1))
                            (ILit 10))
                       (CEQ IReturnValue
                            (ILit 1))        

precondition :: Cond
precondition = CLit True