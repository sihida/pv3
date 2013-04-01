module PV3.Verification where

import PV3.Condition.ConditionAST
import qualified PV3.Condition.ConvertToSBV as Convert
import qualified PV3.Condition.External     as External
import qualified PV3.Condition.Extract      as Extract
import PV3.Program.ProgramAST
import PV3.WP

import Data.SBV

import qualified Data.Map as Map 
import qualified Data.Set as Set

  -- Weakest precondition

wp   :: Program -> Cond -> Cond
wp   p  q = wp_Syn_Program       $ wrap_Program       (sem_Program p)        (Inh_Program       {wp_Inh_Program=q})

wpI  :: Instruction -> Cond -> Cond
wpI  i  q = wp_Syn_Instruction   $ wrap_Instruction   (sem_Instruction i)    (Inh_Instruction   {wp_Inh_Instruction=q,   wp'_Inh_Instruction=q})

wpS  :: Statement -> Cond -> Cond
wpS  s  q = wp_Syn_Statement     $ wrap_Statement     (sem_Statement s)      (Inh_Statement     {wp_Inh_Statement=q,     wp'_Inh_Statement=q})

wpSS :: StatementList -> Cond -> Cond
wpSS ss q = wp_Syn_StatementList $ wrap_StatementList (sem_StatementList ss) (Inh_StatementList {wp_Inh_StatementList=q, wp'_Inh_StatementList=q})

  -- External check

isExternal :: Cond -> Bool
isExternal c = External.external_Syn_Cond $ External.wrap_Cond (External.sem_Cond c) (External.Inh_Cond {})

  -- Convert to SBV

convertToSBV :: Cond -> Map.Map String SBool -> Map.Map String SInteger -> Symbolic SBool
convertToSBV c mB mI = (Convert.symCond_Syn_Cond $ Convert.wrap_Cond (Convert.sem_Cond c) (Convert.Inh_Cond {})) mB mI

  -- Extract type info params

extract :: Cond -> (Set.Set Integer, Set.Set Integer)
extract c = let syn = Extract.wrap_Cond (Extract.sem_Cond c) (Extract.Inh_Cond {}) in (Extract.paramsB_Syn_Cond syn, Extract.paramsI_Syn_Cond syn)

  -- Verify

verify :: Cond -> Program -> Cond -> Symbolic SBool
verify pre program@(Program nParams _ _) post = let vc = CImplies pre (wp program post)
                                                in  if   isExternal vc 
                                                    then let (paramsB, paramsI) = extract vc
                                                             intersect = Set.intersection paramsB paramsI
                                                         in if   Set.null intersect
                                                            then let paramsB' = Set.toList paramsB
                                                                     paramsI' = Set.toList paramsI
                                                                 in  do vB <- mapM (\i -> sBool    ("a" ++ show i)) paramsB'
                                                                        vI <- mapM (\i -> sInteger ("a" ++ show i)) paramsI'
                                                                        let mB = Map.fromList $ zip (map (\i -> "a" ++ show i) paramsB') vB
                                                                            mI = Map.fromList $ zip (map (\i -> "a" ++ show i) paramsI') vI
                                                                        convertToSBV vc mB mI
                                                            else error ("These parameters are used as bool and int: " ++ show intersect)                                                                                                                      
                                                    else error "Program incorrect, wp contains references to internal (stack) data"