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