module PV3.Examples.AnotherExample where


import PV3.Condition.ConditionAST
import PV3.Program.ProgramAST

program :: Program
program = Program 2 2 [
  SInstruction (InstSetLocal 0 (LInt 10)),      -- local_0 := 10
  SInstruction (InstLoadLocal 0),               -- *push* 10
  SInstruction (InstStoreLocal 1),              -- *pop* local_1 := 10
  SInstruction (InstLoadLocal 1),               -- *push* 10
  SInstruction (InstPushLiteral (LInt 10)),     -- *push* 10
  SInstruction (InstEQ),                        -- *pop* 10 == 10
  SIfTrueElse                                   -- *pop* if
    [SInstruction (InstSetLocal 0 (LInt 10))]   -- then: local_0 := 10
    [SInstruction (InstSetLocal 0 (LInt 11))],  -- else: local_0 := 11
  SInstruction (InstLoadParam 0),               -- *push* param_0
  SInstruction (InstLoadLocal 0),               -- *push* 10
  SInstruction (InstAdd),                       -- *pop* param_0 + 10
  SInstruction (InstStoreParam 1),              -- *pop* param_2 := param_0 + 10
  SInstruction (InstLoadParam 1),               -- *push* param_2
  SInstruction (InstPop),                       -- *pop* param_2
  SInstruction (InstLoadParam 0),               -- *push* param_0
  SInstruction (InstLoadLocal 1),               -- *push* 10
  SInstruction (InstGTE),                       -- *pop* param_0 >= 10
  SIfTrueElse                                   -- *pop* if
    []                                          -- then
    [SInstruction (InstPushLiteral (LInt 0)),   -- else: *push* 0
     SInstruction (Instreturn)],                --       return 0
  SInstruction (InstLoadParam 0),               -- *push* param_0
  SInstruction (InstPushLiteral (LInt 2)),      -- *push* 2
  SInstruction (InstMul),                       -- *pop* param_0 * 2
  SInstruction (Instreturn)]                    -- return param_0 * 2
                       
-- ((param_0 >= 10) ==> return == ((param_0 + 10) * 2)) /\ ((param_0 < 10) ==> return == 0)
postcondition :: Cond
postcondition =
  ((IParamOld 0 `CGTE` (ILit 10)) `CImplies` (IReturnValue `CEQ` ((IParamOld 0 `IAdd` (ILit 10)) `IMul` (ILit 2))))
  `CAnd`
  ((IParamOld 0 `CLT` (ILit 10)) `CImplies` (IReturnValue `CEQ` (ILit 0)))

precondition :: Cond
precondition = CLit True
