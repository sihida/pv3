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
\usepackage{hyperref}
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
\newcommand{\semwprulex}[3]{
  \begin{align*}
  \texttt{#1} &=_{sem} \{#2\}
  \\wp \; (\texttt{#1}) \; (Q, Q') \; &=_{def} \; #3
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

For PV Project 3, we have designed and implemented a weakest-precondition calculus for a bytecode language. \cite{assignment} We use this
calculus to verify specifications (pre- and postcondition combinations) for programs in this language:
the specification is correct if and only if the precondition implies the weakest precondition (WP) with
respect to the given postcondition and program (we call this implication the verification condition - VC);
the WP is calculated by subsequently applying the rules from the defined WP calculus (see Section \ref{sec:wprules}).
We check the validity of the VC by converting it to Data.SBV \cite{sbv} format and subsequently calling 
SBV's prove function; SBV interfaces with Microsoft's theorem prover (SMT solver) Z3 \cite{z3}. Z3/SBV returns whether
the VC is valid or not; if the VC is invalid, Z3/SBV gives a counterexample.

We have implemented the verifier in Haskell, using attribute grammars \cite{ag}. This report will explain our solution 
with emphasis on the conceptual ideas. For (more) implementation details, we refer to the Haddock (HTML) documentation and 
the (documented) code. The included README elaborates on practical matters, like building and running the verifier, how to 
test the included examples, et cetera. The README also lists all implemented features. 

Section \ref{sec:basetask} explains our solution for the base task. Our `return from anywhere' extension is described
in Section \ref{sec:returnanywhere}; our bounded verification extension, to deal with loops, is described in Section
\ref{sec:bounded}.

\section{Base task} \label{sec:basetask}

This section presents our solution for the base task: designing and implementing a verification engine for a bytecode
language.

For a more detailed description of the base task, we refer to the assignment \cite{assignment}.

\subsection{Programs} \label{sec:programs}

The assignment \cite{assignment} already contained a description of the syntax and semantics of the bytecode language.
The representation in Haskell is straightforward; the file \texttt{PV3/\-Program/\-ProgramAST.ag} contains the defined AST.

We decided that the type of parameters, local variables, literals and return values is either \emph{bool} or \emph{int}. 
To compare two \emph{bool}s, we added the new instruction EQUIV; we cannot use the existing EQ instruction, as our substitution
implementation (Section \ref{sec:wprules}) needs to know the type of the terms $stack_{T}$ and $stack_{T-1}$ that are substituted for 
the term $stack_{T}$ in the WP rule for EQ/EQUIV (see Section \ref{sec:wprules}). If we compare two \emph{bool}s, both terms would be
of type \emph{bool}; if we compare two \emph{int}s, both terms would be of type \emph{int}. The required type information is not available from
a type checker, as we do not have one, so we decided to incorporate the type information explicitly into the syntax.

We have not developed a parser for programs.

\subsection{Conditions} \label{sec:conditions}

The assignment \cite{assignment} already outlined what conditions should be accepted by the verifier: simple expressions and first-order universal and
existential quantifications. We represent conditions (boolean expressions) again as ASTs, defined in the file \texttt{PV3/\-Condition/\-ConditionAST.ag}.
More complex boolean expressions can be built out of simpler ones, using the most common logical connectives ($\vee$, $\wedge$, \ldots). Relational
operators like $>$, $\geq$, \ldots are used to build boolean expressions out of integer expressions; more complex integer expressions can be built out
of simpler ones, using addition, subtraction, multiplication and (integer) division. Conditions can also consist of integer and boolean literals.
Return values ($return$) and pre-invocation parameter values ($a_i$) are explicitly encoded by a separate data constructor.

(Intermediate) Weakest preconditions are represented by the same AST type. As (intermediate) WPs may reference to internal (stack) data, like $stack_T$,
we defined the attribute grammar \texttt{PV3/\-Condition/\-External.ag} that checks whether a given condition is ``external'', i.e. it does \emph{not} refer to internal (stack)
data; this is useful for verification purposes, see Section \ref{sec:verification}.

\subsubsection {Quantifications}

Universal and existential quantification can be used in conditions, but we doubt the usefulness. We included the example \texttt{PV3/\-Examples/\-Quantification.hs}. Its
program's higher-level counterpart is:
\begin{verbatim}
int p (int a0) {
  return a0;
}
\end{verbatim}
The specification for the example is:
\\ \centerline{$pre: 6 \leq a_0 \leq 10$}
\\ \centerline{$post: \exists \ 6 \leq x \leq 10: return == x$}

When we verify this example, we indeed prove the specification correct: \texttt{{Q.E.D.}} When we change the postcondition to
\\ \centerline{$post: \exists \ 7 \leq x \leq 10: return == x$}
we get an counterexample, indicating that the specification is incorrect:
\begin{verbatim}
Falsifiable. Counter-example:
  a0 = 6 :: SInteger
\end{verbatim}

\subsubsection{Conversion to SBV}

Converting from conditions to SBV format is done by the attribute grammar \texttt{PV3/\-Condition/\-ConvertToSBV.ag}. This AG builds a \texttt{Symbolic} computation.
Essentially, every operator is replaced with its symbolic counterpart. Variables, including (pre-invocation) parameter values, are looked up in an environment (\texttt{Map}),
to ensure that each occurrence of a variable reference refer to the same actual variable. The environment is pre-filled with all parameters ($a_0$, \ldots). 
An (universal/existential) quantification inserts a new variable into this environment and passes the updated environment down to the (boolean) subexpression.

Our decision to accept boolean and \emph{int} parameters complicates this pre-filling of the environment, as type information is not available. Our first strategy was to insert each
parameter twice, once into the boolean environment and once into the \emph{int} environment (we need, at least conceptually, two environments, as our condition is typed). Unfortunately, 
when the verifier gave an counterexample, it listed all parameters twice, as there are two ``versions'' (a boolean and \emph{int} one). It also listed parameters which did not occur 
at all in the VC, as the pre-filling was done based on the number of variables \emph{specified by the program}; as these ``non-occurring'' parameters are irrelevant for a(n eventual) 
counterexample, we would like to omit them.

Our solution to these issues is to extract type information from the verification condition. This is done by the attribute grammar \texttt{PV3/\-Condition/\-Extract.ag}.
This AG returns a tuple: the first element a set of indices of all parameters that are used as boolean, the second element a set of indices of all parameters that are used as \emph{int}s.
If the intersection of these two sets is non-empty, one or more parameters are used as boolean \emph{and} integer, and an error is issued. In the other case, we now know exactly how
to fill the boolean and \emph{int} environments correctly.

We do not insert the return value into either of the environments, as a valid VC does not refer to the return value; if it does, the precondition refers to the return value, 
which makes no sense, or the postcondition refers to the value, but the program does not always (possibly never) return a value at all. This is at least inconsistent; programs
in our bytecode language that do not return a value are also pretty useless, as there is no global state the program could alter. If the VC does refer to the return value, an
error is given, as it cannot be found in either of the environments; the same error is issued when any other non-existing variable is being referred. 

We have not developed a parser for conditions.

\subsection{Weakest precondition rules} \label{sec:wprules}

Essentially, our weakest precondition rules rewind the effects of instructions. Some of the rules were already given in the assignment \cite{assignment}. 

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

Note that we enforce that the stack is empty after returning (which includes a \texttt{POP}) by incorporating the conjunct $T == -1$ into the WP rule for programs;
we enforce that the stack is empty before entering the program by substituting -1 for T in the same rule. The weakest precondition of the body of the program
may reference to (current) parameter values ($param_i$). As these values are now equal to the pre-invocation ones, we substitute $a_i$ for each $param_i$; 
they have now the same name as pre-invocation parameter values, if present, in the given pre- and postcondition.

The WP rules are straightforwardly implemented in the attribute grammar \texttt{PV3/\-WP.ag}. The actual substitutions are done by the attribute grammar
\texttt{PV3/\-Condition/\-Replace.ag}; this AG is called from within the AG \texttt{WP.ag}.

\subsection{Verification} \label{sec:verification}

The actual verification consists of these steps:
\begin{enumerate}
\item \texttt{WP.ag}: calculating the weakest precondition with respect to the given postcondition and program
\item \texttt{PV3/\-Verification.hs}: generating the VC: precondition $\rightarrow$ wp from step 1
\item \texttt{External.ag}: checking the VC for being ``external'' (see below)
\item \texttt{Extract.ag}: extracting the parameter type information from the VC
\item \texttt{Verification.hs}: pre-filling the environment(s)
\item \texttt{ConvertToSBV.ag}: converting the VC to a \texttt{Symbolic} SBV computation, using the pre-filled environment(s)
\item \texttt{Main.hs}: calling SBV's prove function to prove the VC from step 6 correct
\item SBV: calling Z3 and returning the result of the verification (correct or not); if not correct, giving counterexample
\item \texttt{Main.hs}: outputting result of the verification and counterexample, if present
\end{enumerate}

The function
\vspace{-1mm}
\begin{code}
verify :: Cond            -- Precondition of specification. 
       -> Program         -- Program of specification.
       -> Cond            -- Postcondition of specification.
       -> Symbolic SBool  -- Resulting verification condition.
\end{code}
from \texttt{Verification.hs} drives the first part (the first six steps) of the verification; $verify$ is called by the $main$ function in \texttt{Main.hs}. 

Consider the malformed program:
\vspace{-1mm}
\begin{verbatim}
P (0) {
  return ;
}
\end{verbatim}

with as postcondition:
\\ \centerline{$post: return == 2$}

The weakest precondition with respect to this program and postcondition refers to $stack_T$, as the $return$ term in the postcondition is replaced with $stack_T$.
This indicates that the program is malformed and no (non-trivial) specification for the program can be proven correct. Every weakest precondition (and, consequently, VC), with
respect to a given program, that refers to internal (stack) data indicates that the given program is malformed and that no (non-trivial) specification for this program can be
proven correct. So, if the VC is not ``external'', we do not need to convert it to SBV and give it to Z3; instead, we issue the error that the given program is malformed.

Note that a counterexample is only given when one or more (pre-invocation) values ($a_i$) and/or universally/existentially quantified variables appear in the (invalid) VC; 
if this is not the case, the invalidity of the VC does not depend on these values/variables and \verb|Falsifiable| is the only output given. 

\subsection{Examples}

We have included some examples that illustrate the workings of our verifier. Those can be found in the \texttt{PV3/Examples} directory.

\subsubsection{\texttt{Simple}}

This is a very simple example. The program just returns 1:
\begin{verbatim}
int p () {
  return 1;
}
\end{verbatim}
The specification is:
\\ \centerline{$pre: true$}
\\ \centerline{$post: return == 1$}

When we verify this example, the specification is indeed proven correct: \texttt{{Q.E.D.}} When we change the postcondition to
\\ \centerline{$post: return == 0$}
the output of the verifier becomes \texttt{Falsifiable}. As no pre-invocation values/variables appear in the VC, no counterexample is given.

\subsubsection{\texttt{Assignment}}
This is the example from the assignment:
\begin{verbatim}
int p (int a0, int a1) {
  var x0 = 10;
  if (a1+a2 == x0) 
    return 1;
  else 
    return -1;
}
\end{verbatim}
The specification is:
\\ \centerline{$pre: true$}
\\ \centerline{$post: (a_0+a_1 == 10) \leftrightarrow (return == 1)$}

When we verify this example, the specification is indeed proven correct: \texttt{{Q.E.D.}} When we change the postcondition to
\\ \centerline{$post: (a_0+a_1 == 11) \leftrightarrow (return == 1)$}
the output of the verifier becomes: 
\begin{verbatim}
Falsifiable. Counter-example:
  a0 = 10 :: SInteger
  a1 = 0 :: SInteger
\end{verbatim}
Now pre-invocation values do appear in the VC: a counterexample is given.

When we we change the specification to
\\ \centerline{$pre: a_0+a_1 == 10$}
\\ \centerline{$post: return == 1$} \\
the updated specification is also proven correct. But if you change the precondition back to the original one ($true$), we get a counterexample:
\begin{verbatim}
Falsifiable. Counter-example:
  a0 = 11 :: SInteger
  a1 = 0 :: SInteger
\end{verbatim}

\section{`Return from anywhere' extension} \label{sec:returnanywhere}

In the base task, a return instruction could only appear as the last instruction in a program. In this extension we will remove this restriction.

\subsection{Updated WP rules}

The extension is quite simple: We give to each statement/instruction not only a(n intermediate) WP, but also the program body's postcondition input 
``given'' by the program WP rule; this postcondition is identical to the postcondition from the specification, apart from the additional $T == -1$ conjunct (see Section
\ref{sec:wprules}). The return instruction always uses the body's postcondition; the other instructions use the ``normal'' (intermediate) WP, as was the case in the base task.

The input to the WP rules is now a tuple: the first element ($Q$) the ``normal'' (intermediate) WP, the second element the body's postcondition.
The output is now also a tuple: the first element the ``new'' (intermediate) WP, the second element is used to pass the body's postcondition to
the ``next'' (previous) statement.

The return instruction WP rule is updated to:
\semwprulex{return}
{return := stack_T; T := T-1}
{((Q'[T-1/T])[stack_T/return] \wedge T >= 0, Q')}

The rules for the other instructions remain the same, except it copies the body's postcondition $Q'$:
\semwprulex{SETLOCAL $k$ $x$}
{loc_k := x}
{(Q[x/loc_k], Q')}

\subsection{Examples}

\subsubsection{\texttt{ReturnFromAnywhere}}
This is the example from the assignment, slightly altered:
\begin{verbatim}
int p (int a0, int a1) {
  var x0 = 10;
  if (a0+a1 == x0) 
    return 1;
  return -1;
  return 1;
}
\end{verbatim}
The specification is:
\\ \centerline{$pre: true$}
\\ \centerline{$post: (a_0+a_1 == 10) \leftrightarrow (return == 1)$} \\
Note that the last \texttt{return} statement is dead code. 

When we verify this example, the specification is indeed proven correct: \texttt{{Q.E.D.}} When we change the postcondition to
\\ \centerline{$post: (a_0+a_1 == 11) \leftrightarrow (return == 1)$}
the output of the verifier becomes: 
\begin{verbatim}
Falsifiable. Counter-example:
  a0 = 10 :: SInteger
  a1 = 0 :: SInteger
\end{verbatim}

\subsubsection{\texttt{AnotherExample}}
This example uses almost all instructions from the bytecode language. It also uses the `return from anywhere' extension:
\begin{verbatim}
int p (int a0, int a1) {
  var x0 = 10;
  var x1 = 10;
  if (10 == 10)
    x0 = 10;
  else
    x0 = 11;
  a1 = a0 + 10;
  if (a0 >= 10) {}
  else 
    return 0;
  return a1 * 2;
}
\end{verbatim}
The specification is:
\\ \centerline{$pre: true$}
\\ \centerline{$post: (a_0 \geq 10 \rightarrow return == (a_0 + 10) \times 2) \wedge (a_0 < 10 \rightarrow return == 0) $}

When we verify this example, the specification is indeed proven correct: \texttt{{Q.E.D.}} When we change the postcondition to
\\ \centerline{$post: (a_0 \geq 10 \rightarrow return == (a_0 + 10) \times 3) \wedge (a_0 < 10 \rightarrow return == 0) $}
the output of the verifier becomes: 
\begin{verbatim}
Falsifiable. Counter-example:
  a0 = 10 :: SInteger
\end{verbatim}

\section{Bounded verification extension} \label{sec:bounded}

To verify programs with loops, you usually have to provide a loop invariant. This is not needed when you do bounded verification:
you only verify executions whose number of instructions $\leq$ the (upper) bound. 

\subsection{Updated WP calculation}

We added a while-statement to \texttt{ProgramAST.ag}
and added the while WP rules from the assignment \cite{assignment} to \texttt{WP.ag}. To verify all executions whose number
of instructions does not exceed the bound, we determine all paths whose number of instructions does not exceed this bound. The path
(and, consequently, number of instructions) depends on the number of iterations of each loop. So, we determine all ``loop iteration
configurations'' that do not exceed the upper bound.

To this end, we first calculates the number of loops, including inner ones, in our program. This is done by the attribute grammar
\texttt{PV3/\-Program/\-NumberOfLoops.ag}. We then pass ``configurations'' to the \texttt{WP} AG, which returns the WP corresponding
to this ``configuration''. The AG also returns the total number of instructions, which can then be compared to the bound. The implicit
\texttt{POP}s in \texttt{if} and \texttt{while} statements are counted for one instruction. 

We will demonstrate the generation of loop configurations with an example. Consider example \texttt{Bounded4}, which has two outer
loops (L1 and L2) and one inner loop (L1-L1), and a bound of 30 instructions. The first configuration (L1, L1-L1, L2) we try, is (0, 0, 0): no loop is entered and the
number of instructions is 16. This is smaller than the bound, so we need to consider this path. Then, we increase the last element in our configuration:
(0, 0, 1); loop L2 is now entered exactly once. The \texttt{WP} AG returns 28 instructions, which is still smaller than 30, so we need
to consider this path as well. To this end, we \texttt{AND} both WPs. (Note that this is not needed here, as the last WP ``incorporates'' the first WP.
As this optimisation would make our implementation more complex, we decided to skip it.) We increase the last element again: (0, 0, 2). The corresponding number
of instructions, 40, now exceeds the bound, so we will not consider this path. We also stop with increasing the last element, as the number
of instructions would only become more larger than the bound.

We now return to the original configuration (0, 0, 0) and increase the \emph{second} element: (0, 1, 0). The corresponding number of instructions, 16, is the same as
the number of instructions corresponding to the configuration (0, 0, 0); as the outer loop L1 of the inner loop L1-L1 is never entered, the inner one is not
``enabled'', so it makes no sense to increase L1-L1's iterations. Our generation algorithm remembers the ``previous'' length; if the ``new'' length is equal to
the ``previous'' one, it detects a non-enabled inner loop and stops increasing the number of iterations for this inner loop.

Consequently, we return to the original configuration (0, 0, 0) and increase the \emph{first} element: (1, 0, 0). The corresponding number of instructions, 28, is
now \emph{not} the same as the number of instructions corresponding to the configuration (0, 0, 0). It is also smaller than the bound, so we \texttt{AND} this WP with
the ones from (0, 0, 0) and (0, 0, 1). We now, again, increase the third element: (1, 0, 1). The corresponding number of instructions is now 40, larger than
the bound, so we stop increasing the third element. We then increase the second element: (1, 1, 0). The corresponding number of instructions is now
36, larger than the bound, so we stop increasing the second element. We now increase the first element: (2, 0, 0). The corresponding number of instructions is now
40, again larger than the bound, so we stop increasing the first element. We are now done; the resulting WP consists of three ``sub-WPs'' and becomes the
consequent in the VC.

The function $driver$ in \texttt{Verification.hs} implements this rather complicated algorithm.

If there is no path whose number of instructions is $\leq$ bound, we output an error.

\subsection{Examples}

\subsubsection{\texttt{Bounded}}

This example squares its first argument:
\begin{verbatim}
int p (int a0) {
  var x0 = 0;
  var x1 = 0;
  x1 = a0;
  while (x1 > 0) {
    x0 = x0 + a0;
    x1 = x1 - 1;
  }
  return x0;
}
\end{verbatim}
The specification is:
\\ \centerline{$pre: a_0 \geq 0$}
\\ \centerline{$post: return == a_0 \times a_0$} \\
Note that this multiplication is done with addition, e.g. $5 \times 5$ is calculated by doing $5+5+5+5+5$.

\pagebreak

When we verify this example, the specification is indeed proven correct: \texttt{{Q.E.D.}} When we change the precondition to $true$, the verifier gives an counterexample:
\begin{verbatim}
Falsifiable. Counter-example:
  a0 = -3 :: SInteger
\end{verbatim}
When $a_0$ is -3, the loop is never entered, so 0 is returned, which is not equal to $-3 \times -3 == 9$.

\subsubsection{\texttt{Bounded2}}

This example just returns its first argument, but uses a loop for this:
\begin{verbatim}
int p (int a0) {
  var x0 = 0;
  var x1 = 0;
  while (x1 < 1) {
    x0 = x0 + a0;
    x1 = x1 + 1;
  }
  return x0;
}
\end{verbatim}
The specification is:
\\ \centerline{$pre: true$}
\\ \centerline{$post: return == a_0$} \\
When we verify this example, the specification is indeed proven correct: \texttt{{Q.E.D.}} When we change the postcondition to
\\ \centerline{$post: return == 1$} \\
the output of the verifier becomes: 
\begin{verbatim}
Falsifiable. Counter-example:
  a0 = 2 :: SInteger
\end{verbatim}
But when we change the bound to $7 < bound < 20$ and run the verifier again, the specification is proven correct again: \texttt{{Q.E.D.}} This shows the limitations of bounded verification: 
With the ``new'' bound, the only possible configuration is (0), i.e. the loop is never entered. But no execution is possible on this path: the condition's guard evaluates (the first time)
to $0 < 1 == true$, so every execution should enter the loop at least once (and in this case, just once). As no execution is possible, the specification is ``vacuously true'': up to
20 (not including) instructions every execution satisfies the specification, as there is no such an execution... When we change the bound to $\geq 20$ again, the configuration (1) and, consequently, an execution that does not satisfy the specification, is now possible; when we change the bound to $\leq 7$, the number of instructions of no path is $\leq$ bound, so an error is given.

\subsubsection{\texttt{Bounded3}, \texttt{Bounded4}, \texttt{Bounded5}}

These examples are variations on the \texttt{Bounded} and \texttt{Bounded2} examples and consist of multiple, including inner, loops. All can be proven correct and if you change the specification
to an invalid one, you will get an counterexample. Verification may take a while, as with multiple loops, including inner ones, and a large bound, many paths are possible and need to be considered.

\bibliographystyle{abbrv}
\begin{thebibliography}{99}
\bibitem{sbv}L. Erk\"{o}k, 2013. 
\emph{sbv-2.10: SMT Based Verification: Symbolic Haskell theorem prover using SMT solving}. Retrieved April 3, 2013 from Hackage: \url{http://hackage.haskell.org/package/sbv}.
\bibitem{z3}Microsoft Research, 2013. \emph{Z3 - Home}. Retrieved April 3, 2013 from CodePlex: \url{http://z3.codeplex.com/}.
\bibitem{assignment}S.W.B. Prasetya, 2013. \emph{Project 3: Bytecode Verification Engine}. Retrieved April 3, 2013 from the `Program Verification' course page: \url{http://www.cs.uu.nl/docs/vakken/pv/1213/stuffs/PV_P3_1213.pdf}.
\bibitem{ag}Utrecht University, 2009. \emph{Attribute Grammar System}. Retrieved April 3, 2013 from cs.uu.nl's wiki: \url{http://www.cs.uu.nl/wiki/HUT/AttributeGrammarSystem}.

\end{thebibliography}

\end{document}