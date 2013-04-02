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
precondition = CAnd (CGTE (IParamOld 0) (ILit 0)) (CLTE (IParamOld 0) (ILit 5))