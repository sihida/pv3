module PV3.Examples.AnotherExample where


import PV3.Condition.ConditionAST
import PV3.Program.ProgramAST

program :: Program
program = Program 2 1 [
  SInstruction (InstSetLocal 1 (LInt 10)),      -- local_1 := 10
  SInstruction (InstLoadLocal 1),               -- push 10
  SInstruction (InstStoreLocal 2),              -- local_2 := 10
  SInstruction (InstLoadLocal 2),               -- push 10
  SInstruction (InstPushLiteral (LInt 10)),     -- push 10
  SInstruction (InstEQ),                        -- 10 == 10
  SIfTrueElse                                   -- if
    [SInstruction (InstSetLocal 1 (LInt 10))]   -- then: local_1 := 10
    [SInstruction (InstSetLocal 1 (LInt 11)),   -- else: local_1 := 11
     SInstruction (InstLoadLocal 1)],           -- push 1
  SInstruction (InstLoadParam 1),               -- push param_1
  SInstruction (InstLoadLocal 1),               -- push 10
  SInstruction (InstAdd),                       -- param_1 + 10
  SInstruction (InstStoreParam 2),              -- param_2 := param_1 + 10
  SInstruction (InstLoadParam 2),               -- push param_2
  SInstruction (InstPop),                       -- pop param_2
  SInstruction (InstLoadParam 1),               -- push param_1
  SInstruction (InstLoadLocal 2),               -- push 10
  SInstruction (InstGTE),                       -- param_1 >= 10
  SIfTrueElse                                   -- if
    []                                          -- then
    [SInstruction (InstPushLiteral (LInt 0)),   -- else: push 0
     SInstruction (Instreturn)],                --       return 0
  SInstruction (InstLoadParam 1),               -- push param_1
  SInstruction (InstPushLiteral (LInt 2)),      -- push 2
  SInstruction (InstMul),                       -- param_1 * 2
  SInstruction (Instreturn)]                    -- return param_1 * 2
                       
-- ((param_1 >= 10) ==> return == ((param_1 + 10) * 2)) /\ ((param_1 < 10) ==> return == 0)
postcondition :: Cond
postcondition =
  ((IParamOld 1 `CGTE` (ILit 10)) `CImplies` (IReturnValue `CEQ` ((IParamOld 1 `IAdd` (ILit 10)) `IMul` (ILit 2))))
  `CAnd`
  ((IParamOld 1 `CLT` (ILit 10)) `CImplies` (IReturnValue `CEQ` (ILit 0)))

precondition :: Cond
precondition = CLit True
