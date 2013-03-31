module Main where

import PV3.Verification

import PV3.Examples.ReturnFromAnywhere

import Data.SBV

main = do s <- prove $ verify precondition program postcondition
          print s 