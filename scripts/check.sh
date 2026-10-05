#!/usr/bin/env bash
# Prints one line per prerequisite from README.md:
#   ok       this step is done
#   MISSING  you have to fix it -> the README section that says how
#   todo     not your job yet — ISSUE-0.md creates it in §4
#   skip     a key probe could not run (offline or an unexpected answer) — re-run later
# Exits non-zero if any line says MISSING. Works in Git Bash on Windows.
cd "$(dirname "$0")/.."
fail=0
ok()   { printf 'ok       %s\n' "$1"; }
miss() { printf 'MISSING  %-40s -> %s\n' "$1" "$2"; fail=1; }
todo() { printf 'todo     %-40s -> %s\n' "$1" "$2"; }

for c in git uv claude; do command -v "$c" >/dev/null 2>&1 && ok "$c" || miss "$c" "Appendix A"; done

# Both plugins come from .claude/settings.json when you accept the trust dialog.
PL=$(claude plugin list 2>/dev/null)
plugin_on() { echo "$PL" | grep -A3 -- "$1" | grep -i Status | grep -qv disabled; }
for p in langchain-skills langsmith-skills; do
  plugin_on "$p@langchain-plugins" && ok "$p plugin" \
    || miss "$p plugin" "§3 — open claude in the repo, or: claude plugin install $p@langchain-plugins"
done

# The six vars from .env.example, in the root .env. Placeholders don't count.
envset() { grep -E "^$2=.+" "$1" 2>/dev/null | grep -vqE '=\s*(sk-or-v1-\.\.\.|lsv2_pt_\.\.\.|\.\.\.)\s*$'; }
for v in OPENROUTER_API_KEY OPENROUTER_BASE_URL OPENROUTER_MODEL \
         LANGSMITH_API_KEY LANGCHAIN_TRACING_V2 LANGSMITH_PROJECT; do
  envset .env "$v" && ok ".env $v" || miss ".env $v" "§1 Keys"
done

getenv() { grep -E "^$1=" .env 2>/dev/null | head -1 | cut -d= -f2- | tr -d '\r' | sed 's/[[:space:]]*$//'; }

# Live key probes. Each one is skipped, not failed, when there is no clear answer.
envset .env OPENROUTER_API_KEY && k=$(getenv OPENROUTER_API_KEY) || k=
if [ -n "$k" ]; then
  r=$(curl -s -m 8 -w '\n%{http_code}' -H "Authorization: Bearer $k" https://openrouter.ai/api/v1/key)
  code=${r##*$'\n'}
  case "$code" in
    200) ok "OpenRouter key accepted"
         # Per-key spending limit; null means the key has none, so there is nothing to read.
         left=$(printf '%s' "${r%$'\n'*}" | tr -d ' \n' | sed -n 's/.*"limit_remaining":\([^,}]*\).*/\1/p')
         case "$left" in
           ''|null) echo "skip     OpenRouter credit (key has no spending limit to read)" ;;
           *[!0-9.eE+-]*) echo "skip     OpenRouter credit (unreadable answer)" ;;
           *) awk "BEGIN{exit !($left>0)}" && ok "OpenRouter credit (\$$left left on this key)" \
                || miss "OpenRouter credit (\$$left left on this key)" "§1 Keys — ask for a topped-up key" ;;
         esac ;;
    401|403) miss "OpenRouter key rejected ($code)" "§1 Keys — check the OpenRouter key you were given" ;;
    000)     echo "skip     OpenRouter key probe (offline)" ;;
    *)       echo "skip     OpenRouter key probe (unexpected HTTP $code — re-run later)" ;;
  esac
fi

envset .env LANGSMITH_API_KEY && l=$(getenv LANGSMITH_API_KEY) || l=
if [ -n "$l" ]; then
  ep=$(getenv LANGSMITH_ENDPOINT); ep=${ep:-https://api.smith.langchain.com}   # non-US accounts set it — §1
  code=$(curl -s -m 8 -o /dev/null -w '%{http_code}' -H "x-api-key: $l" "${ep%/}/api/v1/sessions?limit=1")
  case "$code" in
    200)     ok "LangSmith key accepted" ;;
    401|403) miss "LangSmith key rejected ($code)" "§1 Keys — new key, or the non-US note" ;;
    000)     echo "skip     LangSmith key probe (offline)" ;;
    *)       echo "skip     LangSmith key probe (unexpected HTTP $code — re-run later)" ;;
  esac
fi

# The repo ships no app code. ISSUE-0.md writes both of these — informational, never blocking.
[ -f pyproject.toml ]  && ok "uv project scaffolded"  || todo "pyproject.toml not scaffolded" "§4 ISSUE-0.md"
[ -f langgraph.json ]  && ok "langgraph.json present" || todo "langgraph.json not scaffolded" "§4 ISSUE-0.md"

[ $fail = 0 ] && echo "all set — go to §4" || echo "fix the MISSING lines, then re-run"
exit $fail
