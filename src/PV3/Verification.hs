{- |
Main (high-level) verification module of the Bytecode Verification Engine.

Calculates verification conditions of given specifications (in Data.SBV format).

Part of PV - Project 3.

Authors: Jaap van der Plas and Danny Bergsma
Version: 0.1, 2 April 2013
-}

module PV3.Verification (verify) where


  -- Imports

  
import           PV3.Condition.ConditionAST
import qualified PV3.Condition.ConvertToSBV as Convert
import qualified PV3.Condition.External     as External
import qualified PV3.Condition.Extract      as Extract
import           PV3.Program.ProgramAST
import qualified PV3.Program.NumberOfLoops  as NumberOfLoops
import           PV3.WP

import           Data.SBV

import qualified Data.Map                   as Map 
import           Data.Maybe
import qualified Data.Set                   as Set
import           Text.Printf


  -- Constants


-- | Upper bound for bounded verification.  
bound = 100

errorExceedsBound         = "All executions exceed upper bound, increase the upper bound"  
errorInternal             = "Program incorrect, wp contains references to internal (stack) data"
errorSomeParamsBoolAndInt = "These parameters are used as bool and int: %s"


  -- Weakest precondition

  
-- | Calculates weakest precondition of given program - postcondition combination.
wp   :: Program      -- ^ Program the weakest precondition will be calculated over.
     -> Cond         -- ^ Postcondition used as ``start'' condition in het calculation.
     -> [Int]        -- ^ Holds the numbers of all loop iterations.
     -> (Cond, Int)  -- ^ Resulting weakest precondition (wrt params) and total number instructions (steps) in considered execution.
wp   p  q l = let wp' =              wrap_Program       (sem_Program p)        (Inh_Program       {wp_Inh_Program=q,       loopIterations_Inh_Program=l})
              in  (wp_Syn_Program wp', length_Syn_Program wp')

-- wpI, wpS and wpSS are never used, but are useful for (future) debug purposes...

-- | Calculates weakest precondition of given instruction - postcondition combination.
wpI  :: Instruction  -- ^ Instruction the weakest precondition will be calculated over. 
     -> Cond         -- ^ Postcondition used as ``start'' condition in the calculation.
     -> Cond         -- ^ Resulting weakest precondition (wrt params).
wpI  i  q   = wp_Syn_Instruction   $ wrap_Instruction   (sem_Instruction i)    (Inh_Instruction   {wp_Inh_Instruction=q,   wp'_Inh_Instruction=q})

-- | Calculates weakest precondition of given statement - postcondition combination.
wpS  :: Statement  -- ^ Statement the weakest precondition will be calculated over.
     -> Cond       -- ^ Postcondition used as ``start'' condition in the calculation.
     -> [Int]      -- ^ Holds the numbers of all loop iterations.
     -> Cond       -- ^ Resulting weakest precondition (wrt params).
wpS  s  q l = wp_Syn_Statement     $ wrap_Statement     (sem_Statement s)      (Inh_Statement     {wp_Inh_Statement=q,     wp'_Inh_Statement=q,         loopIterations_Inh_Statement=l})

-- | Calculates weakest precondition of given statements - postcondition combination.
wpSS :: StatementList  -- ^ Statements the weakest precondition will be calculated over.
     -> Cond           -- ^ Postcondition used as ``start'' condition in the calculation.
     -> [Int]          -- ^ Holds the numbers of all loop iterations.
     -> Cond           -- ^ Resulting weakest precondition (wrt params). 
wpSS ss q l = wp_Syn_StatementList $ wrap_StatementList (sem_StatementList ss) (Inh_StatementList {wp_Inh_StatementList=q, wp'_Inh_StatementList=q,     loopIterations_Inh_StatementList=l})


  -- External check

  
-- | Returns whether the given condition (boolean expression) is external, i.e. it contains no references to internal (stack) data.  
isExternal :: Cond  -- ^ The condition that will be checked for being external. 
           -> Bool  -- ^ True iff given condition is external.
isExternal c = External.external_Syn_Cond $ External.wrap_Cond (External.sem_Cond c) (External.Inh_Cond {})


  -- Convert to SBV

  
-- | Converts given condition (boolean expression) to a condition in SBV format, using the given environments to lookup variables.
convertToSBV :: Cond                     -- ^ Condition that will be converted. 
             -> Map.Map String SBool     -- ^ Environment that will be used to lookup boolean variables.
             -> Map.Map String SInteger  -- ^ Environment that will be used to lookup int variables.
             -> Symbolic SBool           -- ^ Resulting condition in SBV format.
convertToSBV c mB mI = (Convert.symCond_Syn_Cond $ Convert.wrap_Cond (Convert.sem_Cond c) (Convert.Inh_Cond {})) mB mI


  -- Extract type info params

  
-- | Returns a pair of sets containing all parameter indexes that are used as boolean/int expression in the given condition (boolean expression). The intersection is non-empty for a ``mistyped'' condition. 
extract :: Cond                                -- ^ Condition that will be used to extract parameter type info from. 
        -> (Set.Set Integer, Set.Set Integer)  -- ^ First element: all parameter indexes used as boolean expression in given condition. Second element: ~ used as int expression.
extract c = let syn = Extract.wrap_Cond (Extract.sem_Cond c) (Extract.Inh_Cond {}) in (Extract.paramsB_Syn_Cond syn, Extract.paramsI_Syn_Cond syn)


  -- Verify


  
{- | 
Calculates the verification condition (in Data.SBV) format wrt the given specification (precondition - program - postcondition combination), 
i.e. precondition => wp program postcondition.
Gives an error when the verification condition is ``mistyped'' (parameters are used as boolean and int expressions) or when it contains references 
to internal (stack) data, i.e. program is malformed.
-}
verify :: Cond            -- ^ Precondition of specification. 
       -> Program         -- ^ Program of specification.
       -> Cond            -- ^ Postcondition of specification.
       -> Symbolic SBool  -- ^ Resulting verification condition.
verify pre program@(Program nParams _ _) post = let wp = driver [] 0 (NumberOfLoops.numberOfLoops_Syn_Program $ NumberOfLoops.wrap_Program (NumberOfLoops.sem_Program program) (NumberOfLoops.Inh_Program {}), (-1))
                                                in  if   isNothing wp
                                                    then error errorExceedsBound 
                                                    else let vc = CImplies pre (fst $ fromJust wp)
                                                         in  if   isExternal vc 
                                                             then let (paramsB, paramsI) = extract vc
                                                                      intersect = Set.intersection paramsB paramsI
                                                                  in if   Set.null intersect                                                          -- VC not "mistyped"?
                                                                     then let paramsB' = Set.toList paramsB
                                                                              paramsI' = Set.toList paramsI
                                                                          in  do vB <- mapM (\i -> sBool    ("a" ++ show i)) paramsB'                 -- declare boolean params
                                                                                 vI <- mapM (\i -> sInteger ("a" ++ show i)) paramsI'                 -- declare int params
                                                                                 let mB = Map.fromList $ zip (map (\i -> "a" ++ show i) paramsB') vB  -- build boolean environment
                                                                                     mI = Map.fromList $ zip (map (\i -> "a" ++ show i) paramsI') vI  -- build int environment
                                                                                 convertToSBV vc mB mI
                                                                     else error $ printf errorSomeParamsBoolAndInt (show intersect)                                                                                                                     
                                                             else error errorInternal
  where driver h _ (0, pl) = let wpl@(wp', length') = wp program post h
                             in  if   pl < length' && length' <= bound
                                 then Just wpl
                                 else Nothing
        driver h i (n, pl) = let wpN = driver (h ++ [i]) 0 (n-1, pl)
                             in  if   isNothing wpN
                                 then wpN  -- Nothing
                                 else let (wpN', pl') = fromJust wpN
                                          wp'         = driver h (i+1) (n, pl')
                                      in  if   isNothing wp'
                                          then Just (wpN', -1)
                                          else Just (CAnd wpN' (fst $ fromJust wp'), (-1))                             