{- |
Example that uses (existential) quantification.

Part of PV - Project 3.

Authors: Jaap van der Plas and Danny Bergsma
Version: 0.1, 3 April 2013
-}

module PV3.Examples.Quantification where

import PV3.Condition.ConditionAST
import PV3.Program.ProgramAST

body :: StatementList
body = [SInstruction (InstLoadParam 0),
        SInstruction Instreturn]

program :: Program
program = Program 2 1 body
                       
postcondition :: Cond
postcondition = CExistQuant "x" (CAnd (CAnd (CGTE (IVarName "x") (ILit 6)) (CLTE (IVarName "x") (ILit 10))) (CEQ IReturnValue (IVarName "x")))       

precondition :: Cond
precondition = CAnd (CGTE (IParamOld 0) (ILit 6)) (CLTE (IParamOld 0) (ILit 10))