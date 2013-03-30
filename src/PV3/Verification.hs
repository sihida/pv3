module PV3.Verification where

import PV3.Condition.ConditionAST
import qualified PV3.Condition.External     as External
import qualified PV3.Condition.ConvertToSBV as Convert
import PV3.WP

import Data.Map 
import Data.SBV

wp :: Program -> Cond -> Cond
wp p q = wp_Syn_Program $ wrap_Program (sem_Program p) (Inh_Program {wp_Inh_Program=q})

wpI :: Instruction -> Cond -> Cond
wpI i q = wp_Syn_Instruction $ wrap_Instruction (sem_Instruction i) (Inh_Instruction {wp_Inh_Instruction=q})

wpS :: Statement -> Cond -> Cond
wpS s q = wp_Syn_Statement $ wrap_Statement (sem_Statement s) (Inh_Statement {wp_Inh_Statement=q})

wpSS :: StatementList -> Cond -> Cond
wpSS ss q = wp_Syn_StatementList $ wrap_StatementList (sem_StatementList ss) (Inh_StatementList {wp_Inh_StatementList=q})

isExternal :: Cond -> Bool
isExternal c = External.external_Syn_Cond $ External.wrap_Cond (External.sem_Cond c) (External.Inh_Cond {})

convertToSBV :: Cond -> Map String SBool -> Map String SInteger -> Symbolic SBool
convertToSBV c mB mI = (Convert.symCond_Syn_Cond $ Convert.wrap_Cond (Convert.sem_Cond c) (Convert.Inh_Cond {})) mB mI

verify :: Cond -> Program -> Cond -> Symbolic SBool
verify pre program@(Program nParams _ _) post = let vc = CImplies pre (wp program post)
                                                in  if   isExternal vc 
                                                    then do vB      <- mapM (\i -> sBool    ("a" ++ show i)) [0..nParams-1]
                                                            vI      <- mapM (\i -> sInteger ("a" ++ show i)) [0..nParams-1]
                                                            returnB <- sBool    "return"
                                                            returnI <- sInteger "return"
                                                            let mB = insert "return" returnB (fromList $ zip (Prelude.map (\i -> "a" ++ show i) [0..nParams-1]) vB)
                                                                mI = insert "return" returnI (fromList $ zip (Prelude.map (\i -> "a" ++ show i) [0..nParams-1]) vI)
                                                            convertToSBV vc mB mI
                                                    else error "Program incorrect, wp contains references to internal (stack) data"