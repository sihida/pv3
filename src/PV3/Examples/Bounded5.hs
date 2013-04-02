{- |
Example that squares the first (int) parameter, using two loops. Combination of Bounded and Bounded2.

Part of PV - Project 3.

Authors: Jaap van der Plas and Danny Bergsma
Version: 0.1, 2 April 2013
-}

module PV3.Examples.Bounded5 where

import PV3.Condition.ConditionAST
import PV3.Program.ProgramAST

{-
local0 := 0
local1 := param0
while local1 > 0
  local1 := local1 - 1
  local2 := 0
  while local2 > 0
    local2 := local2 - 1
    local0 := local0 + 1
return local1
-}

body :: StatementList
body = [SInstruction (InstSetLocal 0 (LInt 0)),
        SInstruction (InstLoadParam 0),
        SInstruction (InstStoreLocal 1),
        SInstruction (InstLoadLocal 1),
        SInstruction (InstPushLiteral (LInt 0)),
        SInstruction (InstGT),
        SWhileTrue   [SInstruction (InstLoadLocal 1),
                      SInstruction (InstPushLiteral (LInt 1)),
                      SInstruction (InstMin),
                      SInstruction (InstStoreLocal 1),
                      SInstruction (InstSetLocal 2 (LInt 0)),
                      SInstruction (InstLoadLocal 2),
                      SInstruction (InstPushLiteral (LInt 0)),
                      SInstruction (InstGT),
                      SWhileTrue   [SInstruction (InstLoadLocal 2),
                                    SInstruction (InstPushLiteral (LInt 1)),
                                    SInstruction (InstMin),
                                    SInstruction (InstStoreLocal 2),
                                    SInstruction (InstLoadLocal 0),
                                    SInstruction (InstPushLiteral (LInt 1)),
                                    SInstruction (InstAdd),
                                    SInstruction (InstStoreLocal 0),
                                    SInstruction (InstLoadLocal 2),
                                    SInstruction (InstPushLiteral (LInt 0)),
                                    SInstruction (InstGT)],
                      SInstruction (InstLoadLocal 1),
                      SInstruction (InstPushLiteral (LInt 0)),
                      SInstruction (InstGT)],
        SInstruction (InstLoadLocal 0),
        SInstruction (Instreturn)]

program :: Program
program = Program 1 3 body
                       
postcondition :: Cond
postcondition = CEQ IReturnValue (IMul (IParamOld 0) (IParamOld 0))

precondition :: Cond
precondition = CGTE (IParamOld 0) (ILit 0)
