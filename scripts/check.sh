#!/usr/bin/env bash
# Prints one line per prerequisite from README.md:
#   ok       this step is done
#   MISSING  you have to fix it -> the README section that says how
#   todo     not your job yet — ISSUE-0.md creates it in §4
# Exits non-zero if any line says MISSING. Works in Git Bash on Windows.
cd "$(dirname "$0")/.."
fail=0
PY=$(command -v python3 || command -v python)   # python3 on macOS, often just python on Windows
ok()   { printf 'ok       %s\n' "$1"; }
miss() { printf 'MISSING  %-40s -> %s\n' "$1" "$2"; fail=1; }
todo() { printf 'todo     %-40s -> %s\n' "$1" "$2"; }

for c in git uv claude; do command -v "$c" >/dev/null 2>&1 && ok "$c" || miss "$c" "Appendix A"; done
[ -n "$PY" ] && ok "python ($PY)" || miss "python3 or python" "Appendix A"

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
online() { curl -s -m 5 -o /dev/null "$1" 2>/dev/null; }   # any HTTP answer means the net is up

# Live key probes. Each one is skipped, not failed, when the host is unreachable.
k=$(getenv OPENROUTER_API_KEY)
if [ -n "$k" ]; then
  code=$(curl -s -m 8 -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $k" https://openrouter.ai/api/v1/auth/key)
  case "$code" in
    200) ok "OpenRouter key accepted"
         bal=$(curl -s -m 8 -H "Authorization: Bearer $k" https://openrouter.ai/api/v1/credits \
               | "$PY" -c 'import json,sys;d=json.load(sys.stdin)["data"];print(f"{d["total_credits"]-d["total_usage"]:.2f}")' 2>/dev/null)
         if [ -n "$bal" ]; then
           "$PY" -c "import sys;sys.exit(0 if $bal>0 else 1)" && ok "OpenRouter credit (\$$bal left)" \
             || miss "OpenRouter credit (\$$bal left)" "§1 Keys — ask for a topped-up key"
         fi ;;
    401|403) miss "OpenRouter key rejected ($code)" "§1 Keys — check the OpenRouter key you were given" ;;
    *)       online https://openrouter.ai/api/v1/auth/key \
               && ok "OpenRouter reachable (HTTP $code, key not checked)" \
               || echo "skip     OpenRouter key probe (offline)" ;;
  esac
fi

l=$(getenv LANGSMITH_API_KEY)
if [ -n "$l" ]; then
  code=$(curl -s -m 8 -o /dev/null -w '%{http_code}' -H "x-api-key: $l" 'https://api.smith.langchain.com/api/v1/sessions?limit=1')
  case "$code" in
    200)     ok "LangSmith key accepted" ;;
    401|403) miss "LangSmith key rejected ($code)" "§1 Keys — make a new key in LangSmith Settings" ;;
    *)       online 'https://api.smith.langchain.com/api/v1/sessions?limit=1' \
               && ok "LangSmith reachable (HTTP $code, key not checked)" \
               || echo "skip     LangSmith key probe (offline)" ;;
  esac
fi

# The repo ships no app code. ISSUE-0.md writes both of these — informational, never blocking.
[ -f pyproject.toml ]  && ok "uv project scaffolded"  || todo "pyproject.toml not scaffolded" "§4 ISSUE-0.md"
[ -f langgraph.json ]  && ok "langgraph.json present" || todo "langgraph.json not scaffolded" "§4 ISSUE-0.md"

[ $fail = 0 ] && echo "all set — go to §4" || echo "fix the MISSING lines, then re-run"
exit $fail
