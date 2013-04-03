{- |
Example that uses most instructions and the control structures. The program multiplies its second argument by two.

Part of PV - Project 3.

Authors: Jaap van der Plas and Danny Bergsma
Version: 0.1, 2 April 2013
-}
module PV3.Examples.AnotherExample where

import PV3.Condition.ConditionAST
import PV3.Program.ProgramAST

{- | A Java-like equivalent of this program would be:
  
  prog P(a0,a1) {
    var x0 = 10;
    var x1 = 10;
    if (10 == 10) {
      x0 = 10;
    } else {
      x0 = 11;
    }
    a1 = a0 + 10;
    if (a0 >= 10) {
    } else {
      return 0;
    }
    return a1 * 2;
  }
  // NB: there are a few instruction here which modify the stack, for which there is no Java-like equivalent
-}
program :: Program
program = Program 2 2 [
  SInstruction (InstSetLocal 0 (LInt 10)),      -- local_0 := 10
  SInstruction (InstLoadLocal 0),               -- push 10
  SInstruction (InstStoreLocal 1),              -- local_1 := 10
  SInstruction (InstLoadLocal 1),               -- push 10
  SInstruction (InstPushLiteral (LInt 10)),     -- push 10
  SInstruction (InstEQ),                        -- 10 == 10
  SIfTrueElse                                   -- if
    [SInstruction (InstSetLocal 0 (LInt 10))]   -- then: local_0 := 10
    [SInstruction (InstSetLocal 0 (LInt 11)),   -- else: local_0 := 11
     SInstruction (InstPushLiteral (LInt 1))],  --       push 1
  SInstruction (InstLoadParam 0),               -- push param_0
  SInstruction (InstLoadLocal 0),               -- push 10
  SInstruction (InstAdd),                       -- param_0 + 10
  SInstruction (InstStoreParam 1),              -- param_1 := param_0 + 10
  SInstruction (InstLoadParam 1),               -- push param_1
  SInstruction (InstPop),                       -- pop
  SInstruction (InstLoadParam 0),               -- push param_0
  SInstruction (InstLoadLocal 1),               -- push 10
  SInstruction (InstGTE),                       -- param_0 >= 10
  SIfTrueElse                                   -- if
    []                                          -- then
    [SInstruction (InstPushLiteral (LInt 0)),   -- else: push 0
     SInstruction (Instreturn)],                --       return 0
  SInstruction (InstLoadParam 1),               -- push param_1
  SInstruction (InstPushLiteral (LInt 2)),      -- push 2
  SInstruction (InstMul),                       -- param_1 * 2
  SInstruction (Instreturn)]                    -- return param_1 * 2
                       
-- | The postcondition is:
--   ((param_0 >= 10) ==> return == ((param_0 + 10) * 2)) && ((param_0 < 10) ==> return == 0)
postcondition :: Cond
postcondition =
  ((IParamOld 0 `CGTE` (ILit 10)) `CImplies` (IReturnValue `CEQ` ((IParamOld 0 `IAdd` (ILit 10)) `IMul` (ILit 2))))
  `CAnd`
  ((IParamOld 0 `CLT` (ILit 10)) `CImplies` (IReturnValue `CEQ` (ILit 0)))

precondition :: Cond
precondition = CLit True
