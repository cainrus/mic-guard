// Keeps the default INPUT off Bluetooth: when macOS picks a headset's mic, the
// headset drops to mono 16 kHz hands-free mode for output too. On every change of
// the default input to a Bluetooth device, switch it back to the built-in mic.
// Output is never touched. Changing the default device needs no TCC permission.
import CoreAudio
import Foundation

let system = AudioObjectID(kAudioObjectSystemObject)

func address(_ selector: AudioObjectPropertySelector,
             _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> AudioObjectPropertyAddress {
  AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
}

func log(_ message: String) {
  print("\(ISO8601DateFormatter().string(from: Date())) \(message)")
  fflush(stdout)
}

func defaultInput() -> AudioDeviceID? {
  var addr = address(kAudioHardwarePropertyDefaultInputDevice)
  var id = AudioDeviceID(0)
  var size = UInt32(MemoryLayout<AudioDeviceID>.size)
  let status = AudioObjectGetPropertyData(system, &addr, 0, nil, &size, &id)
  return status == noErr && id != 0 ? id : nil
}

func transport(_ id: AudioDeviceID) -> UInt32 {
  var addr = address(kAudioDevicePropertyTransportType)
  var value = UInt32(0)
  var size = UInt32(MemoryLayout<UInt32>.size)
  AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &value)
  return value
}

func name(_ id: AudioDeviceID) -> String {
  var addr = address(kAudioObjectPropertyName)
  var value: Unmanaged<CFString>?
  var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
  guard AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &value) == noErr, let cf = value else { return "device \(id)" }
  return cf.takeRetainedValue() as String
}

func hasInput(_ id: AudioDeviceID) -> Bool {
  var addr = address(kAudioDevicePropertyStreams, kAudioObjectPropertyScopeInput)
  var size = UInt32(0)
  return AudioObjectGetPropertyDataSize(id, &addr, 0, nil, &size) == noErr && size > 0
}

func builtInInput() -> AudioDeviceID? {
  var addr = address(kAudioHardwarePropertyDevices)
  var size = UInt32(0)
  guard AudioObjectGetPropertyDataSize(system, &addr, 0, nil, &size) == noErr else { return nil }
  var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
  guard AudioObjectGetPropertyData(system, &addr, 0, nil, &size, &ids) == noErr else { return nil }
  return ids.first { transport($0) == kAudioDeviceTransportTypeBuiltIn && hasInput($0) }
}

func isBluetooth(_ id: AudioDeviceID) -> Bool {
  let t = transport(id)
  return t == kAudioDeviceTransportTypeBluetooth || t == kAudioDeviceTransportTypeBluetoothLE
}

func enforce() {
  guard let current = defaultInput(), isBluetooth(current) else { return }
  guard let target = builtInInput() else {
    log("default input is \(name(current)) (Bluetooth), no built-in mic found")
    return
  }
  var addr = address(kAudioHardwarePropertyDefaultInputDevice)
  var id = target
  let status = AudioObjectSetPropertyData(system, &addr, 0, nil, UInt32(MemoryLayout<AudioDeviceID>.size), &id)
  log(status == noErr
    ? "default input \(name(current)) -> \(name(target))"
    : "failed to switch input from \(name(current)): OSStatus \(status)")
}

var watched = address(kAudioHardwarePropertyDefaultInputDevice)
let queue = DispatchQueue(label: "mic-guard")
AudioObjectAddPropertyListenerBlock(system, &watched, queue) { _, _ in enforce() }
log("watching default input")
queue.async { enforce() }
dispatchMain()
