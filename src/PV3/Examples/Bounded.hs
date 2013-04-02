{- |
Example that squares the first (int) parameter.

Part of PV - Project 3.

Authors: Jaap van der Plas and Danny Bergsma
Version: 0.1, 2 April 2013
-}

module PV3.Examples.Bounded where

import PV3.Condition.ConditionAST
import PV3.Program.ProgramAST

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
        SInstruction (InstLoadLocal 0),
        SInstruction Instreturn]

program :: Program
program = Program 1 2 body
                       
postcondition :: Cond
postcondition = CEQ IReturnValue (IMul (IParamOld 0) (IParamOld 0))
precondition :: Cond
precondition = (IParamOld 0) `CGTE` (ILit 0)
