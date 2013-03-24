module PV3.Verification where

import PV3.Condition.AG
import PV3.WP

wp :: Program -> Cond -> Cond
wp p q = wp_Syn_Program $ wrap_Program (sem_Program p) (Inh_Program {wp_Inh_Program=q})

wpI :: Instruction -> Cond -> Cond
wpI i q = wp_Syn_Instruction $ wrap_Instruction (sem_Instruction i) (Inh_Instruction {wp_Inh_Instruction=q})

wpS :: Statement -> Cond -> Cond
wpS s q = wp_Syn_Statement $ wrap_Statement (sem_Statement s) (Inh_Statement {wp_Inh_Statement=q})

wpSS :: StatementList -> Cond -> Cond
wpSS ss q = wp_Syn_StatementList $ wrap_StatementList (sem_StatementList ss) (Inh_StatementList {wp_Inh_StatementList=q})