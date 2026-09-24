# LLM-as-a-Judge with Jev

A tiny STAR interview-answer coach, scored by two Judges side by side: **Jev**,
TypeSafe's System One decision model, which returns typed probabilities and no
prose, and an ordinary **LLM Judge** on the same axis. You write no code by hand:
fill in two keys, run one check script, paste two prompts. You end on a LangSmith
Experiment page with Jev's scores next to the LLM's.

`CONTEXT.md` is the glossary — Agent, Judge, Question, Noul, Choice, Score, Rubric,
Dataset, Example, Experiment, Feedback. It is worth two minutes before you start.

## TL;DR

1. **Keys** (§1) — two handed to you, one from your own LangSmith account.
2. **Clone** (§2) — clone this repo. No fork.
3. **Tools** (§3) — paste one prompt into Claude, or run the commands.
   `bash scripts/check.sh` tells you when you're done.
4. **Hand off** (§4) — paste two prompts. Claude does the rest.

## 1. Keys

Two keys, six variables, one file: `.env` at the repo root. Copy
`.env.example` to `.env` and fill it in. `.env` is gitignored — never commit it,
and never paste a key value into a Claude chat.

| Key | Where it comes from | Goes in `.env` as |
| --- | --- | --- |
| OpenRouter | handed to you, already topped up — pays for the Agent, the LLM Judge and Jev | `OPENROUTER_API_KEY` |
| LangSmith | your own account: https://smith.langchain.com → Settings → **API keys** (free) | `LANGSMITH_API_KEY` |

The other four are already filled in for you and should be left alone:
`OPENROUTER_BASE_URL`, `OPENROUTER_MODEL` (`anthropic/claude-haiku-4.5` — any slug
from https://openrouter.ai/models works, copied exactly), `LANGCHAIN_TRACING_V2`
(`true`, so your Agent runs and Jev calls show up as traces) and
`LANGSMITH_PROJECT` (`interview-coach-09c`, the same for everyone).

If `scripts/check.sh` says a key was **rejected**, it is this section you come back
to: the key is wrong or expired, not the code.

## 2. Clone

No fork. Everything you produce stays on your machine and in your own LangSmith
project.

```bash
git clone https://github.com/ianeiko/ae-2026-09c-live-coding-1 && cd ae-2026-09c-live-coding-1
```

## 3. Tools

Open `claude` in the repo and accept the trust dialog. That reads the repo's
`.claude/settings.json` and offers the two plugins that make Claude write current
LangChain code: `langchain-skills` and `langsmith-skills`, both from the
`langchain-plugins` marketplace. Say yes. `scripts/check.sh` fails until both are
enabled — without them Claude writes the pre-v1 `create_agent` shape from its
training data.

Then pick one of the two paths. Commands are macOS — on Windows use Appendix C.

### The lazy way

Paste this into Claude:

> Set this machine up for this repo. Run `bash scripts/check.sh` and fix every MISSING line until it prints `all set`; README §1 and §3 and Appendix A say what each step is. Install tools yourself (Homebrew, uv) and the two plugins (`langchain-skills@langchain-plugins`, `langsmith-skills@langchain-plugins`). Logins and anything that asks for a password are mine: give me the command, I'll run it in another terminal and say "done". Copy `.env.example` to `.env` and tell me which three values to paste where — never ask me to paste a key into this chat, and never print one. `todo` lines about the app are expected, leave them. Don't scaffold or write any app code yet, that's §4. Re-run the check after each fix.

### The manual way

```bash
brew install git uv                                                      # Windows: Appendix C
curl -fsSL https://claude.ai/install.sh | bash                           # Claude Code
claude plugin marketplace add langchain-ai/langchain-plugins             # skip these three if the
claude plugin install langchain-skills@langchain-plugins                 # trust dialog already did it
claude plugin install langsmith-skills@langchain-plugins
cp .env.example .env                                                     # paste the two keys from §1
```

Either way, finish with:

```bash
bash scripts/check.sh      # all set — go to §4
```

The two `todo` lines about `pyproject.toml` and `langgraph.json` are expected here:
this repo ships **no app code**, and §4 is what creates it. Only `MISSING` lines
block you. A `skip` line means you're offline — the key probes were not run.

## 4. Hand off to Claude

Open `claude` in the repo. Prompt zero — the Agent and the first Experiment:

> Read ISSUE-0.md and implement it. Work through its sections in order. Stop and tell me if one of its six acceptance checks fails; commit when they all pass.

That gives you a running Agent (Appendix B: `uv run langgraph dev`, then chat with
it in LangGraph Studio) and a first Experiment URL.

Prompt one — your own Rubric, a fourth Example, and a prediction about it:

> Read ISSUE-1.md and implement it. Ask me for the four Rubric levels, and for my prediction, before you edit anything. Stop and tell me if one of its five acceptance checks fails; commit when they all pass.

Claude records both Experiment URLs here when ISSUE-1 is done:

| Experiment | `feedback_quality` Rubric | Examples | URL |
| --- | --- | --- | --- |
| first (ISSUE-0) | vague / partial / actionable | 3 | _(filled in by ISSUE-0)_ |
| second (ISSUE-1) | your four levels | 4 | _(filled in by ISSUE-1)_ |

And your prediction for the Example you added, against what Jev said:

| Your fourth Example | You predicted | Jev returned | Probabilities / confidence |
| --- | --- | --- | --- |
| all-Situation draft | _(filled in by ISSUE-1)_ | _(filled in by ISSUE-1)_ | _(filled in by ISSUE-1)_ |

Open both Experiments in LangSmith and compare the `feedback_quality` column. That
comparison is the point of the session — and if your prediction was wrong, that row
is the most useful thing on this page. A Rubric that rates *critiques* does not rate
*answers*: a bad draft is an easy draft to critique well.

## Appendix A — what should be on your machine

The lazy prompt installs these; the manual way assumes them. Windows equivalents
are in Appendix C.

| Tool | Install (macOS) |
| --- | --- |
| Homebrew | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` |
| git, uv | `brew install git uv` |
| Python 3.12 | uv installs it from `.python-version`; nothing to do |
| Claude Code | `curl -fsSL https://claude.ai/install.sh \| bash` |
| Claude plugins | `claude plugin marketplace add langchain-ai/langchain-plugins`, then `claude plugin install langchain-skills@langchain-plugins` and `langsmith-skills@langchain-plugins` — `claude plugin list` shows both enabled |

## Appendix B — run it locally

Nothing here exists until ISSUE-0 has run.

```bash
uv run langgraph dev                 # LangGraph Studio — chat with the Agent
uv run python evals/run.py           # runs the Experiment, prints its URL last
```

Jev returns **probabilities and no rationale** — there is no explanation to open,
by design. The only free text in the Experiment is the LLM Judge's `reason`. Its
package, `langchain-typesafe`, is alpha and pinned to `0.0.1a3` on purpose: it
already changed its API once. Don't upgrade it mid-session.

| What you see | Cause | Fix |
| --- | --- | --- |
| 401 from OpenRouter or LangSmith | key wrong or not loaded from `.env` | §1 Keys, then `bash scripts/check.sh` |
| `TypeSafeClassifier` rejects a `questions` argument | the old `0.0.1a2` constructor form | Questions go in the `invoke` payload — ISSUE-0.md §5 |
| `langgraph dev` starts, Studio shows no graph | `langgraph.json` doesn't point at the compiled graph | ISSUE-0.md §2 |
| `langgraph: command not found` | CLI missing from the project | `uv run langgraph dev` |
| Experiment page is empty / has no Feedback columns | an Evaluator raised, so nothing was written | rerun; the traceback is in the terminal and in the LangSmith trace |
| The Dataset has 6 or 7 Examples | it was recreated instead of reused | ISSUE-0.md §3 |

## Appendix C — Windows

Everything here assumes a **bash** shell, so get one first: install
[Git for Windows](https://git-scm.com/download/win) and use **Git Bash** for every
command in this README (or use WSL and follow the macOS path inside it). PowerShell
and `cmd` won't run `scripts/check.sh`.

Install the tools (PowerShell, once — `winget` ships with Windows 10/11):

| Tool | Install (Windows) |
| --- | --- |
| git (+ Git Bash) | `winget install Git.Git` |
| uv | `winget install astral-sh.uv` |
| Claude Code | `irm https://claude.ai/install.ps1 \| iex` |

The two plugins install the same way on Windows, from Git Bash — Appendix A.

Then reopen Git Bash (so the new tools are on `PATH`) and continue with §3. Every
`cp` / `uv` / `bash scripts/check.sh` line works there unchanged; the only
replacement is the `brew install` line of the manual way.

| What you see | Fix |
| --- | --- |
| `bash: scripts/check.sh: No such file` | you're in PowerShell or `cmd` — reopen Git Bash |
| `uv: command not found` in Git Bash | reopen Git Bash after installing; if it persists, restart Windows |
| `python3: command not found` | check.sh falls back to `python`; only the OpenRouter credit line needs it |
| CRLF warnings from git | harmless — `git config core.autocrlf input` quiets them |
