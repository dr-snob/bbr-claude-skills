---
name: voice-input
description: Oraculum voice daemon control. Activates the local streaming STT daemon (push-to-talk). When invoked, starts the daemon if not running, or shows status if already active. 100% local — mlx-whisper on Metal GPU, Silero VAD, no cloud APIs.
---

# Voice Input — Oraculum Daemon Control

## When This Skill Is Invoked

1. Check if the daemon is already running:
   ```bash
   PID=$(cat /tmp/voice-daemon.pid 2>/dev/null)
   if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
     echo "Daemon running (PID $PID), state: $(cat /tmp/voice-daemon.state 2>/dev/null)"
   else
     echo "Daemon not running"
   fi
   ```

2. **If not running** — start it:
   ```bash
   /Users/gerald/Developer/Tools/voice-daemon.sh &
   ```
   Then confirm: "Voice daemon started. Press **F5** to toggle listening."

3. **If already running** — report status and remind user:
   - `idle` → "Daemon ready. Press **F5** to start listening."
   - `listening` → "Daemon is actively listening. Press **F5** to send and stop."
   - `muted` → "Daemon is muted (TTS protection). Will unmute automatically."

## Architecture

```
Mic (sounddevice) → Silero VAD → Streaming mlx-whisper (Metal GPU)
  → LocalAgreement-2 confirmation → Accumulate text
  → F5 toggle → Paste to terminal (Escape + Cmd+V + Enter)
```

All local. Zero cloud. Zero latency from network.

## How It Works

- **Push-to-talk:** F5 toggles `idle ↔ listening` via Karabiner → `voice-toggle.sh` → SIGUSR1
- **Streaming STT:** Speech is transcribed incrementally every ~2s as you speak (LocalAgreement-2 algorithm)
- **Manual send:** Pauses don't split utterances. Text accumulates until you press F5 to send
- **Interrupt:** Sends Escape before paste, interrupting Claude mid-response if needed

## States

| State | Meaning | F5 Action |
|-------|---------|-----------|
| `idle` | Mic off, waiting | → `listening` |
| `listening` | Mic hot, transcribing | → `idle` (sends text) |
| `muted` | TTS protection pause | → `listening` |

## Key Files

| File | Purpose |
|------|---------|
| `~/Developer/Oraculum/stt_daemon.py` | Main daemon: mic → VAD → streaming STT → paste |
| `~/Developer/Oraculum/streaming_asr.py` | LocalAgreement-2 streaming processor |
| `~/Developer/Tools/voice-daemon.sh` | Thin launcher (exec into stt_daemon.py) |
| `~/Developer/Tools/voice-toggle.sh` | SIGUSR1 toggle (called by Karabiner on F5) |

## Stack

| Layer | Tool | Runtime |
|-------|------|---------|
| STT | mlx-whisper `large-v3-turbo-8bit` (874MB) | MLX Metal GPU |
| VAD | silero-vad-lite (ONNX C++) | CPU |
| TTS | Kokoro ONNX fp16 (169MB) | CPU (currently disabled) |
| Hotkey | F5 via Karabiner Elements | — |

## State Files

| File | Purpose |
|------|---------|
| `/tmp/voice-daemon.pid` | Daemon process ID |
| `/tmp/voice-daemon.state` | `idle`, `listening`, or `muted` |

## Shell Aliases

```bash
alias vt="/Users/gerald/Developer/Tools/voice-toggle.sh"
alias voice-claude="/Users/gerald/Developer/Tools/voice-claude.sh"
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Daemon not starting | Check venv: `ls ~/Developer/Oraculum/.venv-pocket/bin/python` |
| F5 not toggling | Verify Karabiner rule is active in Karabiner-Elements preferences |
| Text not appearing | Grant Accessibility permission to terminal app |
| No mic input | Grant Microphone permission to terminal app |
| Kill everything | `pkill -f stt_daemon` |
| Check logs | `log show --predicate 'process == "python3"' --last 5m` |

## vs Claude Code /voice

| | Oraculum /voice-input | Claude /voice |
|---|---|---|
| STT | Local mlx-whisper (Metal GPU) | Cloud-based |
| TTS | Local Kokoro (disabled) | None |
| Privacy | 100% on-device | Anthropic servers |
| Availability | Always (your machine) | 5% rollout |
| Trigger | F5 push-to-talk | Hold spacebar |
