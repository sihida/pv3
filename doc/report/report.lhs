\documentclass[a4paper]{scrartcl}
%include polycode.fmt

\usepackage{amsmath}
\usepackage{lmodern}
\usepackage{mathpazo}
\usepackage{graphicx}
\usepackage[font=sf,labelfont=sf]{caption}
\usepackage{semantic}
\usepackage{mathtools}
\usepackage{wasysym}
\mathlig{;}{\;;\;}
\mathlig{>=}{\ge}
\mathlig{=<}{\le}
\mathlig{==}{\equiv}
\mathlig{:=}{\coloneqq}

\newcommand{\semwprule}[3]{
  \begin{align*}
  \texttt{#1} &=_{sem} \{#2\}
  \\wp \; (\texttt{#1}) \; Q \; &=_{def} \; #3
  \end{align*}
}
\newcommand{\wprule}[2]{
  \begin{align*}
  &wp \; (\texttt{#1}) \; Q \; =_{def} \; #2
  \end{align*}
}

\title{Program Verification 2012--2013 \\ Project 3: Bytecode Verification Engine}
\author{Danny Bergsma \and Jaap van der Plas}

\begin{document}

\maketitle

\section{Introduction}

\section{Weakest precondition rules}

These are our weakest-precondition rules \smiley:

\semwprule{SETLOCAL $k$ $x$}
{loc_k := x}
{Q[x/loc_k]}
\semwprule{LOADLOCAL $k$}
{T := T+1; stack_T := loc_k}
{(Q[loc_k/stack_T])[(T+1)/T]}
\semwprule{STORELOCAL $k$}  
{loc_k := stack_T; T := T-1}
{(Q[(T-1)/T])[stack_T/loc_k] \wedge T >= 0}
\semwprule{LOADPARAM $k$}   
{T := T+1; stack_T := param_k}
{(Q[param_k/stack_T])[(T+1)/T]}
\semwprule{STOREPARAM $k$}  
{param_k := stack_T; T := T-1}
{(Q[(T-1)/T])[stack_T/param_k] \wedge T >= 0}
\semwprule{PUSHLITERAL $l$} 
{T := T+1; stack_T := l}
{(Q[l/stack_T])[(T+1)/T]}
\semwprule{POP}
{T := T-1}
{Q[T-1/T] \wedge T >= 0}
\semwprule{ADD}           
{stack_{T-1} := stack_{T-1} + stack_T; T := T-1}
{(Q[(T-1)/T])[(stack_{T-1} + stack_T)/stack_{T-1}] \wedge T >= 1}
\semwprule{MIN}           
{stack_{T-1} := stack_{T-1} - stack_T; T := T-1}
{(Q[(T-1)/T])[(stack_{T-1} - stack_T)/stack_{T-1}] \wedge T >= 1}
\semwprule{MUL}           
{stack_{T-1} := stack_{T-1} * stack_T; T := T-1}
{(Q[(T-1)/T])[(stack_{T-1} * stack_T)/stack_{T-1}] \wedge T >= 1}
\semwprule{EQ}            
{stack_{T-1} := stack_{T-1} == stack_T; T := T-1}
{(Q[(T-1)/T])[(stack_{T-1} == stack_T)/stack_{T-1}] \wedge T >= 1}
\semwprule{LT}            
{stack_{T-1} := stack_{T-1} < stack_T; T := T-1}
{(Q[(T-1)/T])[(stack_{T-1} < stack_T)/stack_{T-1}] \wedge T >= 1}
\semwprule{LTE}           
{stack_{T-1} := stack_{T-1} =< stack_T; T := T-1}
{(Q[(T-1)/T])[(stack_{T-1} =< stack_T)/stack_{T-1}] \wedge T >= 1}
\semwprule{GT}            
{stack_{T-1} := stack_{T-1} > stack_T; T := T-1}
{(Q[(T-1)/T])[(stack_{T-1} > stack_T)/stack_{T-1}] \wedge T >= 1}
\semwprule{GTE}           
{stack_{T-1} := stack_{T-1} >= stack_T; T := T-1}
{(Q[(T-1)/T])[(stack_{T-1} >= stack_T)/stack_{T-1}] \wedge T >= 1}
\semwprule{EQUIV}           
{stack_{T-1} := stack_{T-1} \leftrightarrow stack_T; T := T-1}
{(Q[(T-1)/T])[(stack_{T-1} \leftrightarrow stack_T)/stack_{T-1}] \wedge T >= 1}
\semwprule{return}
{return := stack_T; T := T-1}
{(Q[T-1/T])[stack_T/return] \wedge T >= 0}

\wprule{$s_1$; $s_2$; $\ldots$; $s_n$}
{wp \; s_1 \; (wp \; s_2 \; (\ldots \; (wp \; s_n \; Q)))}

\wprule{iftrue $s_1$ else $s_2$}
{
\begin{aligned}
&((wp \; s_1 \; Q)[T-1/T] \wedge stack_T) \; \vee \\
&((wp \; s_2 \; Q)[T-1/T] \wedge \neg stack_T)) \wedge T >= 0
\end{aligned}
}

\wprule{prog P $n$ s}
{((wp \; s \; (Q \wedge T == -1))[a_0/param_0][a_1/param_1] \dots [a_{n-1}/param_{n-1}])[-1/T]}



\end{document}
