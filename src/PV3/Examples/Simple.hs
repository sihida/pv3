{- |
Very simple example.

Part of PV - Project 3.

Authors: Jaap van der Plas and Danny Bergsma
Version: 0.1, 2 April 2013
-}

module PV3.Examples.Simple where

import PV3.Condition.ConditionAST
import PV3.Program.ProgramAST

program :: Program
program = Program 0 0 [SInstruction (InstPushLiteral (LInt 1)),
                       SInstruction (Instreturn)]
                       
postcondition :: Cond
postcondition = CEQ IReturnValue (ILit 1)       

precondition :: Cond
precondition = CLit True