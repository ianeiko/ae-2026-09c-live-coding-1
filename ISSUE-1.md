Now the Rubric is yours. ISSUE-0 shipped `feedback_quality` as a three-level Score
you did not write; here you replace it with four levels of your own, add a fourth
Example, predict where it will land, and rerun. You end with two Experiments in
LangSmith and a reason for every difference between them — including the difference
between what you predicted and what Jev said.

Same glossary as before: `CONTEXT.md`.

## 0. Prerequisite

ISSUE-0 must be committed. Check that the commit
`scaffold STAR coach agent + first jev experiment` is in `git log` and that
`bash scripts/check.sh` prints `all set` with no `todo` lines.

If either fails, **stop and say so**. Do not scaffold anything — that is ISSUE-0's
job, and doing it here would make two competing Agents.

## 1. The Rubric

`feedback_quality` is a Score, so its Rubric is an ordered list of levels, lowest
first. Jev accepts 2 to 10 of them. ISSUE-0's was
`["vague", "partial", "actionable"]`.

Ask the learner for four levels. If they would rather you proposed them, propose
four — ordered, each a short description of what critique at that level looks like,
not a bare adjective — and **confirm with the learner before editing anything**. The
Rubric is the Judge's instructions; a learner who did not choose it learns nothing
from the column it produces.

Then edit the Questions module — only the `feedback_quality` criteria list, and its
`instructions` if the new levels need different framing.

## 2. The Example, and a prediction

Add a fourth Example to the `interview-coach-09c` Dataset: a draft answer that is
all Situation — scene-setting, no Task, no Action, no Result. Its
`expected_behavior` says the Agent should flag three missing Beats.

Before running anything, have the learner **write down which level of their Rubric
they expect this Example to land on, and why**. One sentence. It goes in the README
table in §4.

Then watch the category error, because it catches nearly everyone: the Rubric rates
the **critique**, not the draft. A draft missing three Beats hands the Agent three
obvious, concrete things to say — so a deliberately bad draft usually produces a
critique that scores *high*, not low. The learner's prediction is very likely to be
wrong, and that being wrong is the thing this issue teaches. Do not warn them out of
it beforehand; let the Experiment say it.

Adding, not recreating: the Dataset already exists and already holds three
Examples. The eval script must end with four, not seven, and not a second Dataset.

## 3. What must not change

The Agent's system prompt, its model, and the graph. The whole point of the second
Experiment is that the only moving parts are the Rubric and the Dataset. If the
Agent changes too, neither Experiment explains the other.

The diff of this commit touches the Questions module, the Examples, and
`README.md`. Nothing else.

## 4. Rerun and record

`uv run python evals/run.py`. Then put both Experiment URLs in the README's §4
table — the ISSUE-0 one and this one, labelled so a reader can tell which Rubric
each ran under, plus the §2 prediction and the level Jev actually returned for the
new Example. If that table is not in the README, add it under §4 in the same shape
the README already uses.

## 5. Commit

One commit, message `custom rubric + failing example`.

## Acceptance — all five must pass

1. The second Experiment has 4 Examples.
2. Its `feedback_quality` legend shows 4 levels, in the learner's order.
3. The learner's prediction from §2 and the level Jev actually returned are both in
   the README table, with Jev's per-level probabilities and confidence for that
   Example. **This check passes whether or not they match** — it asks that the
   comparison exists, not that the prediction was right. If they differ, say in one
   or two sentences what the probabilities suggest the Rubric rewarded instead.
4. `git diff` between the ISSUE-0 commit and this one touches only the Questions
   module, the Examples, and `README.md` — the Agent source is byte-identical.
5. The README §4 table holds both Experiment URLs.

Stop and report on the first check that fails. Never edit the Example, the Rubric
or a Question to move a number after seeing it — that is the one way to fail this
issue completely. A Rubric that disagrees with the prediction is the most
interesting result this tutorial can produce; report what Jev's probabilities say
instead.

## Failure modes

| Symptom | Cause | Fix |
| --- | --- | --- |
| Validation error on `Score.criteria` | fewer than 2 or more than 10 levels | §1 — four ordered levels |
| The "failing" Example scores near the top | the Rubric rates the critique; a weak draft is easy to critique precisely | §2 — this is the expected result, report it |
| The new Example has no `expected_behavior` | `create_examples` takes `outputs`; a dict keyed `reference_outputs` is silently dropped | key it `outputs`; `reference_outputs` is the Evaluator's argument name, not the Dataset field |
| Dataset has 7 Examples | Examples recreated instead of appended | §2 — add one to the existing Dataset |
| A second Dataset appears in LangSmith | created under a new name | the name stays `interview-coach-09c` |
| The legend still shows 3 levels | the Experiment ran against the old Questions module | rerun `uv run python evals/run.py` after the edit |
| No §4 table in the README | ISSUE-0 ran before the README existed | §4 — add the table |
| `git diff` also touches the Agent | the prompt was "improved" along the way | §3 — revert the Agent, rerun |
