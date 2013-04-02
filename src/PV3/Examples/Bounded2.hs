{- |
Example that just returns the first parameter, but uses a (useless) loop for this. To test bounded verification.

Part of PV - Project 3.

Authors: Jaap van der Plas and Danny Bergsma
Version: 0.1, 2 April 2013
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
precondition = CGTE (IParamOld 0) (ILit 0)