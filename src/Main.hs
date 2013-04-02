{- |
Main module of the Bytecode Verification Engine.

Verifies the specification of the imported example using Data.SBV-Z3.

Part of PV - Project 3.

Authors: Jaap van der Plas and Danny Bergsma
Version: 0.1, 2 April 2013
-}

module Main where

import PV3.Verification

import PV3.Examples.Bounded2  -- example that will be verified

import Data.SBV

-- | Verifies the specification of the imported example.
main = do s <- prove $ verify precondition program postcondition
          print s