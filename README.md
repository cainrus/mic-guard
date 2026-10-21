# mic-guard

When macOS picks a Bluetooth headset's mic as the default input, the headset
drops to mono 16 kHz hands-free mode for output too, and dictation records
near-silence. mic-guard listens for changes of the default input (CoreAudio)
and switches it back to the built-in mic whenever it becomes a Bluetooth
device. Output is never touched; no microphone permission is needed.

- `native/mic-guard.swift` - the listener.
- `src/bin.ts` - rebuilds the Swift binary into `~/.cache/mic-guard/` when the
  source is newer, then runs it in the foreground.

Runs as the launchd agent `com.starassov.mic-guard`
(`~/dotfiles/claude/launchd/com.starassov.mic-guard.plist`) and is toggled from
the dashboard `/agents` page. Stop it for a call that needs the headset mic.

Test: `npm test`. Log: `~/.claude-home/logs/mic-guard.out.log`.
