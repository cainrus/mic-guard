# mic-guard

Keeps the macOS default input off Bluetooth.

When macOS makes a Bluetooth headset's mic the default input, the headset
switches to its hands-free profile: output drops to mono 16 kHz along with the
mic, and dictation or voice notes record near-silence. mic-guard listens for
changes of the default input through CoreAudio and switches it back to the
built-in mic whenever a Bluetooth device takes over.

- Output is never touched: the headset stays your speaker.
- No microphone permission is needed. Changing the default device is not a
  TCC-protected action, and mic-guard never opens an input stream.
- No polling. It sleeps on a CoreAudio property listener and wakes only when the
  default input changes.

## Requirements

- macOS on a Mac with a built-in mic
- Xcode Command Line Tools (`xcode-select --install`), for `swiftc`
- Node.js 22 or newer: the wrapper is TypeScript run with
  `--experimental-strip-types`, with no build step and no dependencies

## How it works

- `native/mic-guard.swift` is the listener (about 80 lines). On start and on
  every change of `kAudioHardwarePropertyDefaultInputDevice`, it checks the
  device's transport type. If it is Bluetooth or Bluetooth LE, it sets the first
  built-in device that has input streams as the default input.
- `src/bin.ts` compiles the Swift file into `~/.cache/mic-guard/mic-guard`
  whenever the source is newer than the binary, then runs the binary in the
  foreground and forwards SIGTERM and SIGINT to it.

## Run

```sh
node --experimental-strip-types src/bin.ts
```

Each switch is logged with a timestamp:

```
2026-10-21T16:40:12Z default input AirPods Pro -> MacBook Pro Microphone
```

## Run at login (launchd)

`launchd/mic-guard.plist` is an example agent. Replace the `/Users/YOU` paths
and the node path with your own absolute paths, then:

```sh
cp launchd/mic-guard.plist ~/Library/LaunchAgents/local.mic-guard.plist
launchctl bootstrap gui/$UID ~/Library/LaunchAgents/local.mic-guard.plist
```

To use the headset mic for a call, stop the agent first and start it again after:

```sh
launchctl bootout gui/$UID/local.mic-guard
launchctl bootstrap gui/$UID ~/Library/LaunchAgents/local.mic-guard.plist
```

## Test

```sh
npm test
```

## License

MIT
