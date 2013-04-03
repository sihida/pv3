Program Verification 2012-2013: Project 3 (Bytecode Verification Engine)
========================================================================

Jaap van der Plas (3998312)
Danny Bergsma (4019474)

Utrecht, 3 April 2013

========================================================================
Contents
--------
1. Features
2. Usage
3. Used libraries
4. File/directory overview
A. References

1) Features
-----------
* Verifies specifications (precondition - bytecode program - postcondition combination) using WP calculus and Z3.
  * Pre- and postconditions support universal and existential quantification. 
* Gives an counterexample when the specification cannot be proven correct (only if one or more variables appear in the VC).
* Return from anywhere extension.
* Bounded verification (loops) extension: verifies executions up to PV3.WP.bound instructions.
  * Gives an error when # instructions of a program (with zero iterations for all loops) > PV3.WP.bound.
* Gives an error when program is malformed, i.e. no precondition - postcondition combination could be proven correct.
* Gives an error when in the pre- and/or postcondition parameters are used in a boolean *and* int context.
* Gives an error when in the pre- and/or postcondition a variable is not quantified, nor a return value or pre-invocation parameter value.

2) Usage
--------
To build using cabal (from the root):

    cabal configure
    cabal build

If you get a 'Couldn't match expected type with actual type' error, update cabal (cabal install cabal-install) and try again. If you still
get the error, change 'versionBranch' in /dist/setup/setup.version to 1,16,0,3.

To run the verifier, run (from the root):

    dist\build\verify\verify.exe
    
This will verify the example that is specified in the Main module (Main). You can verify another example by importing another Example module,
building and running it again.

If the specification is correct (wrt the given upper bound), the verifier will output 'Q.E.D.'. If not, the verifier will output
'Falsifiable.'; it will also output a counterexample if one or more variables appear in the VC. 
Various errors may also be given (see features).

3) Used libraries
-----------------
cabal
uuagc
uuagc-cabal
sbv-2.9 (Z3(-4.3.0) does not seem to work with 2.10!)

Z3-4.3.0

4) File/directory overview
--------------------------
/src                                     -- Haskell source (including AG files)
/dist                                    -- Distribution built by cabal (configure and build)
/doc/haddock                             -- Generated Haddock HTML files
/doc/report                              -- Report (explanation of implementation), including lhs source
/examples                                -- Various examples
pvp3.cabal                               -- cabal file
Setup.hs                                 -- needed for cabal
uuagc_options                            -- options for building the AGs, used by uuagc-cabal
README.md                                -- this file...

A) References
-------------
based on: http://www.cs.uu.nl/docs/vakken/pv/1213/stuffs/PV_P3_1213.pdf