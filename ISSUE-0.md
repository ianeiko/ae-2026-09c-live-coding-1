Build the STAR coach Agent and score it with Jev in one LangSmith Experiment.
The repo ships no app code: `README.md`, `ISSUE-*.md`, `scripts/check.sh`,
`.env.example`, `.claude/settings.json`, `CLAUDE.md`, `CONTEXT.md` and
`docs/` are all that exist. Everything below is yours to write.

`CONTEXT.md` is the glossary. Use its words — Agent, Beat, Judge, Jev, LLM Judge,
Evaluator, Question, Noul, Choice, Score, Rubric, State, Dataset, Example,
Experiment, Feedback — in code, comments and the commit message.

Start by running `bash scripts/check.sh`. If it does not print `all set`, stop and
tell the learner which line to fix. Read the `langchain-skills` and
`langsmith-skills` skills before writing code: `create_agent` and `Client.evaluate`
both changed in v1 and the skills are the current reference.

## 1. Project

A uv project at the repo root — `pyproject.toml` beside this file, not in a
subdirectory. Python 3.12 (`.python-version` already pins it). Two importable
places: a package holding the Agent and the Questions, and an `evals/` entry point.

Dependencies, with these two pinned exactly:

- `langchain-typesafe==0.0.1a3` — the Jev adapter, alpha, pinned for the cohort
- `langchain` v1, `langchain-openai`, `langsmith`, `python-dotenv`,
  `langgraph-cli[inmem]` (for `langgraph dev`)

Load the root `.env` at import time (`load_dotenv()`), then read every value from
the environment. No default values that stand in for a missing key: if
`OPENROUTER_API_KEY`, `OPENROUTER_BASE_URL` or `OPENROUTER_MODEL` is absent, raise with the variable's name. A hidden default is
how a learner ends up debugging a 401 instead of reading a message.

Never print a key value.

## 2. The Agent

LangChain v1 `create_agent`, with `ChatOpenAI` pointed at OpenRouter: `base_url`,
`api_key` and `model` all from env. No tools.

The system prompt is the contract:

- Input is a behavioural interview question plus the learner's draft answer.
- Critique each Beat — Situation, Task, Action, Result — one short paragraph each,
  named, in that order. Say plainly when a Beat is absent rather than inventing one.
- Then a rewrite: the whole answer, improved, as the learner could say it. The
  rewrite may not invent facts the draft does not contain — above all not an
  outcome. Where a Beat is missing, the rewrite carries a marked placeholder the
  learner fills in. A fabricated metric is one the learner recites in a real
  interview.
- If the input is not an interview answer, reply with one sentence redirecting the
  person back to a behavioural question, and nothing else. No critique, no rewrite.

Export the compiled graph at module level and point `langgraph.json` at it, so
`langgraph dev` serves it and the learner can chat with the Agent in LangGraph
Studio before anything judges it. `langgraph.json` also needs the `.env` path and
the Python version.

## 3. Dataset

Name: `interview-coach-09c`. The eval script creates it **with** the Examples below
if it does not exist, and otherwise reuses it by name and leaves its Examples
alone. Write Examples only on the create path: an existing Dataset is reused as it
stands. Running the eval twice must not make a second Dataset and must not add a
single Example.

Each Example has `inputs = {"question": ..., "draft_answer": ...}` and one
reference output, `expected_behavior`: prose describing what a good Agent answer
does — notes for the Judge, not gold text to match.

Mind the two names for the one thing. On the Dataset side that field is
**`outputs`**; `create_examples` silently drops a dict keyed `reference_outputs`
and you get Examples with no expected behavior at all. `reference_outputs` is what
the *Evaluator* receives it as (§6).

Three Examples:

1. **Strong** — a complete STAR answer, all four Beats present. Expect all four
   Beats acknowledged and a `strong` verdict.
2. **Missing Result** — Situation, Task and Action, no outcome. Expect the critique
   to name the missing Result Beat and a `needs_work` verdict.
3. **Off topic** — a recipe pasted where the answer should be. Expect the
   one-sentence redirect, no critique, and an `off_topic` verdict.

## 4. State

The State every Judge sees:

```python
{"question": ..., "draft_answer": ..., "expected_behavior": ..., "agent_output": ...}
```

Grading instructions never go in State. They live in the Questions. Jev is explicit
about this: State is what happened, Questions are what to judge about it. A State
that carries "score this highly if…" will produce scores you cannot reason about.

## 5. The three Jev Questions

Their own module — ISSUE-1 edits this one file and nothing else.

- `covers_all_star` — **Noul**: does the critique address all four Beats?
- `feedback_quality` — **Score** over the ordered Rubric
  `["vague", "partial", "actionable"]`, lowest first.
- `verdict` — **Choice** over `{strong, needs_work, off_topic}`, one line of
  criteria per option.

Two wordings to get right, because both have a wrong reading that looks fine until
you see the numbers:

- Every Question judges the **critique**, not the draft answer. Say so.
  `feedback_quality` in particular must state that a precise critique of a strong
  answer and a precise critique of a weak one sit at the same level — otherwise the
  Score quietly becomes a measure of how bad the draft was.
- "Addresses a Beat" includes *saying the Beat is absent*, and includes praising a
  Beat that is already good. Without that sentence, `covers_all_star` reads as
  "flags missing Beats" and the strong Example scores near zero.

If a number surprises you, fix the Question's wording — that is the lesson. Do not
edit an Example until the number comes out the way you wanted.

One `TypeSafeClassifier` call answers all three against the same State. Jev is
reached through OpenRouter with the same `OPENROUTER_API_KEY` as the Agent — there is
no separate TypeSafe key. Model is `~typesafe/jev-latest`, the alias for
the newest Jev — it can move mid-cohort, so numbers may shift between runs. The classifier appends
`/v1/systemone` to its `base_url`, so pass the OpenRouter base URL *without* its
trailing `/v1`.

### The invocation contract — use this shape, verbatim

```python
import os

from langchain_typesafe import Choice, Noul, Score, TypeSafeClassifier

# Built with NO questions. Questions go in the invoke payload.
classifier = TypeSafeClassifier(
    model="~typesafe/jev-latest",
    base_url=os.environ["OPENROUTER_BASE_URL"].removesuffix("/v1"),  # -> https://openrouter.ai/api
    api_key=os.environ["OPENROUTER_API_KEY"],
)

response = classifier.invoke(
    {
        "state": state,                 # the dict from §4
        "questions": {
            "covers_all_star": Noul(instructions="..."),
            "feedback_quality": Score(instructions="...", criteria=["vague", "partial", "actionable"]),
            "verdict": Choice(instructions="...", criteria={"strong": "...", "needs_work": "...", "off_topic": "..."}),
        },
    }
)

response.nouls["covers_all_star"].noul            # float 0..1
response.scores["feedback_quality"].score         # float, expected level, may be fractional
response.scores["feedback_quality"].legend        # {0: "vague", 1: "partial", 2: "actionable"}
response.scores["feedback_quality"].probabilities # {0: .., 1: .., 2: ..}
response.scores["feedback_quality"].confidence    # float 0..1
response.choices["verdict"].choice                # one of the criteria keys
response.choices["verdict"].probabilities         # {"strong": .., ...}
response.choices["verdict"].confidence            # float 0..1
```

**The constructor-`questions` form is the old API. Do not use it.**
`TypeSafeClassifier(questions=...)` is the `0.0.1a2` shape that the public
jev-as-a-judge blog repo still uses; on `0.0.1a3` it raises, because the model
forbids extra fields. Questions belong in the `invoke` payload, next to `state`.

Jev returns probabilities and no rationale. There is nothing to read as an
explanation — that is what the LLM Judge is there for.

## 6. Evaluators

Four, one Feedback key each. An Evaluator has the LangSmith signature
`(inputs, outputs, reference_outputs) -> feedback`.

Three wrap the Jev Judge. Call the classifier once per Example, not once per
Evaluator — cache or compute the response for the Example and have the three
Evaluators read from it.

| Feedback key | From | `score` / `value` | `comment` |
| --- | --- | --- | --- |
| `covers_all_star` | Noul | `score` = the probability | the probability |
| `feedback_quality` | Score | `score` = the expected score | legend + per-level probabilities + confidence |
| `verdict` | Choice | `value` = the chosen option | confidence + per-option probabilities |
| `llm_covers_all_star` | LLM Judge | `score` = 1.0 or 0.0 | the reason |

Every `comment` must be non-empty — it is the only way a learner sees what a number
was derived from.

The LLM Judge is the same OpenRouter model as the Agent, with structured output
`{covers_all_star: bool, reason: str}`, judging the same axis as the `covers_all_star`
Noul. It is the contrast: a yes/no with a sentence, against a probability with none.

## 7. Running the Experiment

`evals/run.py`, run as `uv run python evals/run.py`:

```python
Client().evaluate(
    target,                       # runs the graph, returns {"agent_output": ...}
    data="interview-coach-09c",
    evaluators=[...],             # the four above
    experiment_prefix="interview-coach",
    max_concurrency=1,
)
```

`max_concurrency=1` keeps the trace readable and the shared keys unrattled. The
script's last line of output is the Experiment URL and nothing else, so the learner
can click it. Print the Dataset-scoped comparison URL — the view with one column
per Feedback key — not the tracing-project URL.

## 8. Commit

One commit, message `scaffold STAR coach agent + first jev experiment`.

## Acceptance — all six must pass

1. `bash scripts/check.sh` prints `all set`, and the two former `todo` lines now
   read `ok`.
2. `langgraph dev` starts. In Studio, a behavioural question plus a draft answer
   comes back as four named Beat critiques followed by a rewrite; a pasted recipe
   comes back as one redirect sentence and nothing else.
3. `uv run python evals/run.py` ends by printing a LangSmith Experiment URL.
4. That Experiment has the four Feedback keys `covers_all_star`,
   `feedback_quality`, `verdict`, `llm_covers_all_star`, each with a non-empty
   comment, over **every** Example in the Dataset.

   On a fresh LangSmith workspace that is the 3 Examples from §3. If
   `interview-coach-09c` already exists there from an earlier run, it is whatever
   that Dataset holds: reuse it as it stands, report the count, and do not delete
   or overwrite it to make the number come out at 3 — that orphans the Experiments
   already attached to it.
5. The off-topic Example has `verdict = off_topic` and the lowest
   `feedback_quality` of the three; the other two Examples both score above it, and
   the strong Example's `verdict` is `strong`.

   Note what this does *not* ask: that the strong Example outscore the
   missing-Result one on `feedback_quality`. That Score judges the critique, and a
   critique that names an absent Beat is usually every bit as actionable as one
   that praises four present Beats — Jev puts them within a few hundredths of each
   other. A ranking between them is not a thing this Rubric produces, and chasing
   one means editing Questions until the metric agrees with you.
6. Running `uv run python evals/run.py` a second time reuses the Dataset — same
   Example count as the first run, no second Dataset — and creates a second
   Experiment.

Stop and report on the first check that fails. Do not commit a failing check.

## Failure modes

| Symptom | Cause | Fix |
| --- | --- | --- |
| `TypeSafeClassifier` raises on extra field `questions` | constructor-`questions` form from the blog repo | §5 — Questions go in the `invoke` payload |
| `AttributeError` on `.answers[...]` / no `.nouls` | reading the raw dict instead of the typed response | use `.nouls`, `.scores`, `.choices` |
| 401 from the classifier | `api_key` not passed, so it fell back to an unset TypeSafe env var | pass `api_key=os.environ["OPENROUTER_API_KEY"]` explicitly — §5 |
| 400 or 404 from `…/v1/systemone` | model `jev-1.13.0` (TypeSafe-direct ID), or `base_url` still ends in `/v1` | §5 — `~typesafe/jev-latest`, base URL with `/v1` stripped |
| 401 from OpenRouter, or a model that does not exist | `OPENROUTER_*` missing or a bad slug | §1 — no defaults; copy the slug from `.env` exactly |
| `langgraph dev` starts but Studio shows no graph | `langgraph.json` does not point at the module-level compiled graph | §2 — export the compiled graph, not a factory |
| `langgraph: command not found` | CLI not in the project | add `langgraph-cli[inmem]`, run `uv run langgraph dev` |
| `ModuleNotFoundError` on the package `evals/run.py` imports | `uv sync` ran while the package directory was still empty, registering an empty editable install | write the package files before the first sync; to recover, `uv sync --reinstall-package <name>` |
| Examples upload but `expected_behavior` is empty in LangSmith | `create_examples` takes `outputs`; a dict keyed `reference_outputs` is silently dropped | key the Dataset field `outputs`; `reference_outputs` is the Evaluator's argument name |
| Dataset has 6 Examples after two runs | Examples added unconditionally | §3 — create only when absent |
| The Dataset already exists with someone else's Examples | the name is shared and a previous run created it | reuse it — §3 says reuse by name; don't delete it, that orphans earlier Experiments |
| A Feedback column is empty in LangSmith | Evaluator returned no `key`, or raised | one Evaluator per Feedback key, each returning its key |
