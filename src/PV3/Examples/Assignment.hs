module PV3.Examples.Assignment where

import PV3.WP
import PV3.Condition.AG

body :: StatementList
body = [SInstruction (InstSetLocal  0 (LInt 10)),
        SInstruction (InstLoadParam 0),
        SInstruction (InstLoadParam 1),
        SInstruction (InstAdd),
        SInstruction (InstLoadLocal 0),
        SInstruction (InstEQ),
        SIfTrueElse  [SInstruction (InstPushLiteral (LInt 1))] [SInstruction (InstPushLiteral (LInt (-1)))],
        SInstruction (Instreturn)]

program :: Program
program = Program 2 1 body
                       
postcondition :: Cond
postcondition = CEquiv (CEQ (IAdd (IParamOld (ILit 0)) (IParamOld (ILit 1)))
                            (ILit 10))
                       (CEQ IReturnValue
                            (ILit 1))        

precondition :: Cond
precondition = CLit True