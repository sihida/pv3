module PV3.Examples.Simple where

import PV3.WP
import PV3.Condition.AG

program :: Program
program = Program 0 0 [SInstruction (InstPushLiteral (LInt 1)),
                       SInstruction (Instreturn)]
                       
postcondition :: Cond
postcondition = CEQ IReturnValue (ILit 1)       

precondition :: Cond
precondition = CLit True