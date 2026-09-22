Now the Rubric is yours. ISSUE-0 shipped `feedback_quality` as a three-level Score
you did not write; here you replace it with four levels of your own, add an Example
you expect to score at the bottom of them, and rerun. You end with two Experiments
in LangSmith and a reason for every difference between them.

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

## 2. The failing Example

Add a fourth Example to the `interview-coach-09c` Dataset: a draft answer that is
all Situation — scene-setting, no Task, no Action, no Result. Its
`expected_behavior` says the Agent should flag three missing Beats, and that the
critique this produces should land at the **lowest** level of the new Rubric.

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
each ran under. If that table is not in the README, add it under §4 in the same
shape the README already uses.

## 5. Commit

One commit, message `custom rubric + failing example`.

## Acceptance — all five must pass

1. The second Experiment has 4 Examples.
2. Its `feedback_quality` legend shows 4 levels, in the learner's order.
3. The new all-Situation Example has the lowest `feedback_quality` score of the four.
4. `git diff` between the ISSUE-0 commit and this one touches only the Questions
   module, the Examples, and `README.md` — the Agent source is byte-identical.
5. The README §4 table holds both Experiment URLs.

Stop and report on the first check that fails. If check 3 fails — the Example you
predicted would score lowest did not — say so plainly rather than editing the
Example until it does. A Rubric that disagrees with your prediction is the most
interesting result this tutorial can produce; tell the learner what Jev's
probabilities say instead.

## Failure modes

| Symptom | Cause | Fix |
| --- | --- | --- |
| Validation error on `Score.criteria` | fewer than 2 or more than 10 levels | §1 — four ordered levels |
| Dataset has 7 Examples | Examples recreated instead of appended | §2 — add one to the existing Dataset |
| A second Dataset appears in LangSmith | created under a new name | the name stays `interview-coach-09c` |
| The legend still shows 3 levels | the Experiment ran against the old Questions module | rerun `uv run python evals/run.py` after the edit |
| No §4 table in the README | ISSUE-0 ran before the README existed | §4 — add the table |
| `git diff` also touches the Agent | the prompt was "improved" along the way | §3 — revert the Agent, rerun |
