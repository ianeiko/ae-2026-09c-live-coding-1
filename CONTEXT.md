# LLM-as-a-Judge with Jev

Tutorial repo: learners build one tiny LangChain agent, then score its answers with
Jev through LangSmith. This glossary fixes the words the README, ISSUE files and code use.

## Language

**Agent**:
The STAR answer coach under test: takes a behavioural interview question plus a draft answer, returns a per-beat critique and a rewrite. It is what gets judged, never what judges.
_Avoid_: app, bot, coach, model (the Agent *uses* a model)

**Beat**:
One of the four parts of a STAR answer: Situation, Task, Action, Result. The Agent critiques each Beat.
_Avoid_: section, step, component

**Judge**:
Whatever scores an Agent's answer. Two kinds here: the Jev Judge and the LLM Judge.
_Avoid_: grader, scorer, critic

**Jev**:
TypeSafe AI's System One decision model, reached through OpenRouter (`~typesafe/jev-latest`).
Returns typed probabilities, no text.
_Avoid_: jev LLM, TypeSafe model, judge model

**LLM Judge**:
A chat model (via OpenRouter) prompted to score the same criteria as Jev, for contrast.
_Avoid_: baseline, GPT judge

**Evaluator**:
The LangSmith-side function `(inputs, outputs, reference_outputs) -> feedback` that wraps a Judge. One Evaluator per Judge.
_Avoid_: metric, scorer, judge (a Judge is what an Evaluator calls)

**Question**:
One atomic thing Jev is asked about a State. Comes in three primitives: Noul, Choice, Score.
_Avoid_: criterion, check, prompt

**Noul**:
A Question answered with the probability that a yes/no statement is true.
_Avoid_: boolean, flag, pass/fail (pass/fail is derived by thresholding a Noul)

**Choice**:
A Question answered by picking one option from a named set, with probabilities and confidence.
_Avoid_: category, label, class

**Score**:
A Question answered against an ordered rubric of levels, low to high, with probabilities and confidence.
_Avoid_: rating, grade

**Rubric**:
The ordered list of levels a Score is judged against. Written by the learner in ISSUE-1.
_Avoid_: scale, criteria list

**State**:
The bundle the Judge sees: user input, Agent output, expected behavior. Contains no grading instructions; those live in Questions.
_Avoid_: context, payload, prompt

**Dataset**:
The LangSmith collection of Examples the Agent is run against.
_Avoid_: test set, eval set, fixtures

**Example**:
One Dataset row: an input for the Agent plus the expected behavior the Judge compares against.
_Avoid_: test case, sample, item

**Experiment**:
One LangSmith run of the Agent over the Dataset with all Evaluators attached. The URL learners open at the end.
_Avoid_: eval run, evaluation, test run

**Feedback**:
The per-Example result an Evaluator writes back to LangSmith: a key plus a score or value.
_Avoid_: result, verdict, grade
