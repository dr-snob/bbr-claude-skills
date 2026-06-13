#!/bin/bash
# Context Sentinel - Pressure Check
# Combines tool call count + transcript size for accurate context pressure estimation
#
# Usage: Run via hook or manually
# Output: Writes pressure level to /tmp/claude-pressure-{session}
# Also outputs warnings to stderr for hook integration

SESSION_ID="${CLAUDE_SESSION_ID:-${PPID:-default}}"
COUNTER_FILE="/tmp/claude-tool-count-${SESSION_ID}"
PRESSURE_FILE="/tmp/claude-pressure-${SESSION_ID}"

# --- Signal 1: Tool call count ---
if [ -f "$COUNTER_FILE" ]; then
  TOOL_COUNT=$(cat "$COUNTER_FILE")
  TOOL_COUNT=$((TOOL_COUNT + 1))
  echo "$TOOL_COUNT" > "$COUNTER_FILE"
else
  echo "1" > "$COUNTER_FILE"
  TOOL_COUNT=1
fi

# --- Signal 2: Transcript file size ---
# Find the most recent .jsonl transcript for this project
PROJECT_DIR=$(pwd)
TRANSCRIPT=$(ls -t ~/.claude/projects/*/*.jsonl 2>/dev/null | head -1)
TRANSCRIPT_KB=0
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  TRANSCRIPT_BYTES=$(wc -c < "$TRANSCRIPT" 2>/dev/null | tr -d ' ')
  TRANSCRIPT_KB=$((TRANSCRIPT_BYTES / 1024))
fi

# --- Combined Pressure Calculation ---
# Weight: 60% transcript size, 40% tool count
# Normalize to 0-100 scale
# Transcript: 0KB=0%, 500KB=50%, 1000KB=80%, 1500KB+=100%
# Tools: 0=0%, 25=25%, 50=50%, 75=75%, 100+=100%

if [ "$TRANSCRIPT_KB" -lt 500 ]; then
  SIZE_SCORE=$((TRANSCRIPT_KB * 50 / 500))
elif [ "$TRANSCRIPT_KB" -lt 1000 ]; then
  SIZE_SCORE=$((50 + (TRANSCRIPT_KB - 500) * 30 / 500))
elif [ "$TRANSCRIPT_KB" -lt 1500 ]; then
  SIZE_SCORE=$((80 + (TRANSCRIPT_KB - 1000) * 20 / 500))
else
  SIZE_SCORE=100
fi

if [ "$TOOL_COUNT" -lt 100 ]; then
  TOOL_SCORE=$((TOOL_COUNT))
else
  TOOL_SCORE=100
fi

# Weighted average
PRESSURE=$(( (SIZE_SCORE * 60 + TOOL_SCORE * 40) / 100 ))

# Determine level
if [ "$PRESSURE" -lt 40 ]; then
  LEVEL="GREEN"
elif [ "$PRESSURE" -lt 65 ]; then
  LEVEL="YELLOW"
elif [ "$PRESSURE" -lt 85 ]; then
  LEVEL="RED"
else
  LEVEL="EMERGENCY"
fi

# Write state
echo "${LEVEL}|${PRESSURE}|${TOOL_COUNT}|${TRANSCRIPT_KB}" > "$PRESSURE_FILE"

# --- Hook Output (stderr ONLY — human terminal visibility) ---
# DELIBERATELY stderr-only. The MODEL has accurate native context awareness; this
# script's pressure number is a CRUDE PROXY (tool count + largest-jsonl-across-all-
# projects file size, thresholds calibrated for a small window, not a 1M context).
# Injecting it into the model's context (stdout additionalContext) made a bad proxy
# OVERRIDE good native judgment and caused a false-EMERGENCY mid-session abort
# (2026-06-06). So: NO stdout/additionalContext. stderr = Gerald's terminal only;
# the /tmp state file above is for the context-sentinel skill. Do not re-add a
# model-facing channel unless it reads a REAL context measurement.
LAST_LEVEL=""
LAST_LEVEL_FILE="/tmp/claude-last-level-${SESSION_ID}"
if [ -f "$LAST_LEVEL_FILE" ]; then
  LAST_LEVEL=$(cat "$LAST_LEVEL_FILE")
fi
echo "$LEVEL" > "$LAST_LEVEL_FILE"

# Warn on level transitions
if [ "$LEVEL" != "$LAST_LEVEL" ] && [ "$LEVEL" != "GREEN" ]; then
  echo "[ContextSentinel] Pressure: ${LEVEL} (${PRESSURE}%) — ${TOOL_COUNT} tools, ${TRANSCRIPT_KB}KB transcript" >&2
  if [ "$LEVEL" = "YELLOW" ]; then
    echo "[ContextSentinel] Consider checkpointing progress to session-live.md" >&2
  elif [ "$LEVEL" = "RED" ]; then
    echo "[ContextSentinel] CHECKPOINT NOW — context pressure critical" >&2
  elif [ "$LEVEL" = "EMERGENCY" ]; then
    echo "[ContextSentinel] EMERGENCY — save all progress and recommend session restart" >&2
  fi
fi

# Periodic reminders at YELLOW+
if [ "$LEVEL" != "GREEN" ] && [ $((TOOL_COUNT % 10)) -eq 0 ]; then
  echo "[ContextSentinel] Pressure: ${LEVEL} (${PRESSURE}%) — ${TOOL_COUNT} tools, ${TRANSCRIPT_KB}KB" >&2
fi
