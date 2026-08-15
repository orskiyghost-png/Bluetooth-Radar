# Bluetooth Radar

## What it does

Bluetooth Radar is a native SwiftUI application for iOS 17+ that discovers nearby Bluetooth Low Energy advertisers and visualizes a selected device as a relative proximity signal. It shows the device name when available, stable UUID, raw and smoothed RSSI, signal level, last-seen state, and a short RSSI history graph.

## Architecture

The app uses MVVM and keeps all runtime state on the device:

`BLE advertisement → CBCentralManager → BluetoothScanner → EMA RSSI filter → normalized proximity → RadarView`

`BluetoothScanner` owns CoreBluetooth discovery and publishes devices keyed by `CBPeripheral.identifier`. `ScannerViewModel` exposes scanning state to SwiftUI. `RadarViewModel` tracks one device, applies lost-state updates, and provides a simulator-friendly Demo Radar mode. The views contain no networking or persistence layer.

## How BLE scanning works

The scanner creates a `CBCentralManager`, waits for `.poweredOn`, and calls `scanForPeripherals(withServices: nil, options:)` with `CBCentralScanOptionAllowDuplicatesKey` enabled. Duplicate advertisements are required for live RSSI updates. The app does not connect automatically to discovered peripherals; it only consumes advertisement metadata and RSSI.

The required privacy string is included in `BluetoothRadar/Resources/Info.plist`:

> Bluetooth is used to detect nearby BLE devices and measure their relative signal strength.

## RSSI and proximity

RSSI is a relative radio-signal measurement, not a precision rangefinder. Walls, reflections, antenna orientation, device power, body position, and interference can change RSSI without a corresponding change in physical distance. Bluetooth Radar maps approximately -100 dBm to 0 and -50 dBm to 1, clamps values outside that range, and uses the result only to place the target nearer or farther from the center. It does not claim a distance in meters.

An exponential moving average is used for smoother motion: `smoothed = alpha * current + (1 - alpha) * previous`. The smoothing speed is configurable as Slow, Normal, or Fast.

## Radar behavior

The radar draws five concentric rings, a phone marker at the center, and a glowing target marker. A stronger normalized RSSI moves the target toward the center; a weaker RSSI moves it toward the outer ring. This is radial proximity visualization only. The app does not infer bearing or direction from RSSI.

The radar displays current RSSI, signal classification, tracking state, selected device name, a 20-second history graph, and Stop Tracking. Demo Radar produces fluctuating synthetic RSSI values for UI and animation checks in the iOS Simulator; production scanning remains CoreBluetooth-based.

## LOST state

A selected device becomes LOST after the configured timeout, defaulting to three seconds without a new advertisement. LOST dims the target, stops its active pulse, and displays “Waiting for signal…”. A later advertisement clears LOST automatically and resumes TRACKING.

## Haptics

Haptics are optional in Settings and are intended for meaningful upward transitions only: Weak to Medium, Medium to Strong, or Strong to Very Strong. There is no continuous vibration loop.

## Installation

### A. Development through Xcode on a Mac

Clone the repository, check out `feature/bluetooth-radar`, open the Xcode project, select a signing team and a connected iPhone, then build and run. Bluetooth permissions are requested by CoreBluetooth on first use. A physical iPhone is required for real BLE discovery.

### B. Apple-supported development or sideloading method

A signed application can be installed using an Apple-supported development distribution path available to the account, such as Xcode device deployment, TestFlight, or an appropriate registered development/ad hoc profile. The signing identity, bundle identifier, provisioning profile, and Apple account determine which path is available.

### C. What can be done through Manus/GitHub

The repository, Swift source, Xcode project metadata, tests, privacy plist, and documentation can be created and maintained in GitHub. Demo Radar can be used to inspect the UI in a simulator after opening the project in Xcode.

### D. What Manus cannot do

Manus cannot physically install an unsigned IPA on an iPhone, access Bluetooth hardware through GitHub, run CoreBluetooth inside GitHub, replace Xcode signing, or turn a GitHub repository into an iOS runtime.

## Running on a real iPhone

A Mac with Xcode is the normal route. Open the project, select a valid development team under Signing & Capabilities, connect an iPhone, trust the development certificate if prompted, and run. Enable Bluetooth when asked. To test tracking, use a nearby BLE peripheral that is actively advertising; a device that is not advertising will not appear in a scan.

For a person with only an iPhone and GitHub, the repository alone is not an installable application. iOS still requires Apple signing and a compatible build/distribution path. GitHub can host the source, but it cannot compile and install CoreBluetooth as an iPhone runtime by itself.

## Troubleshooting

If the status says Bluetooth is off, enable Bluetooth in iOS Settings or Control Center. If permission was denied, enable Bluetooth access for Bluetooth Radar in Settings. If no devices appear, verify that the target is BLE and advertising, press Scan, and move closer. Classic Bluetooth devices that do not advertise through CoreBluetooth will not appear. Use Demo Radar to validate the visual layer without a peripheral.

## Limitations

The app can see BLE advertisers only. RSSI varies with orientation, obstacles, reflections, transmit power, and interference. The radar does not estimate exact distance and does not provide direction or bearing. A peripheral must be actively advertising to be discovered. iOS permission and code-signing rules still apply. The iOS Simulator cannot fully verify real BLE scanning; physical testing requires an iPhone and a BLE advertisement source.

## No server required

The app performs scanning, filtering, mapping, rendering, settings, and demo generation locally. It has no backend, account, database, WebSocket, Firebase dependency, external SDK, or internet requirement after installation.

## Verification status

The repository includes unit tests for normalization boundaries, clamping, finite output, EMA behavior, signal classification, and lost-timeout threshold logic. This environment does not provide macOS/Xcode, so a physical-device build, CoreBluetooth runtime test, signing test, and iOS Simulator test were not executed here. Static checks are documented in the delivery report.

## iPhone 11 profile

The Xcode target is configured for iPhone-only deployment with iOS 17.0 as the minimum version. The radar uses a compact, width-driven square canvas capped at 360 points, which fits the iPhone 11 6.1-inch portrait viewport while respecting the notch safe area. The screen remains scrollable for accessibility and larger text settings. The iPhone 11 uses an A13 Bionic processor and supports the iOS 17 deployment target used by this project.

The application does not need a special iPhone 11 Bluetooth implementation. CoreBluetooth provides the same BLE central-manager API on this device; the adaptation is in the target family and layout profile rather than in a replacement scanner.
