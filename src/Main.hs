module Main where

import PV3.Verification
import PV3.Condition.ConditionAST

import PV3.Examples.Bounded2

import Data.SBV

main = do s <- prove $ verify precondition program postcondition
          print s