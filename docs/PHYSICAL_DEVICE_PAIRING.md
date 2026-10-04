# OncoSense physical iPhone ↔ Apple Watch verification

## What the app considers a healthy connection

OncoSense separates four states:

1. **Apple Watch paired** — the iPhone has an active paired Watch.
2. **OncoSense Watch app installed** — the OncoSense watchOS app is installed on the active Watch.
3. **WatchConnectivity active** — both sides have activated their `WCSession`.
4. **Live channel reachable** — the Watch app is currently available for immediate messaging.

The fourth state is optional. `isReachable == false` does **not** mean that the iPhone and Watch are unpaired. Health snapshots use `updateApplicationContext`, and queued requests use `transferUserInfo`, so the product does not depend on a permanently live channel.

## Final physical-device test

Use a real paired iPhone and Apple Watch. Simulator testing is not enough for the complete WatchConnectivity path.

### 1. Regenerate the project

```bash
brew install xcodegen
xcodegen generate
open OncoSense.xcodeproj
```

The project spec embeds `OncoSenseWatch` into the iPhone app. The `postGenCommand` in `project.yml` is intentional for modern Xcode versions: XcodeGen can otherwise place a watchOS app in the old `Watch` directory instead of the required `PlugIns` directory.

### 2. Verify the two targets

The project must contain:

- `OncoSense` — iOS companion app
- `OncoSenseWatch` — watchOS app

The watch target must keep:

- bundle identifier: `com.hackerdlj.oncosense.watchkitapp`
- companion bundle identifier: `com.hackerdlj.oncosense`
- HealthKit capability

### 3. Pair the physical devices with Xcode

In Xcode, open **Device Hub / Manage Devices**.

For wireless pairing, the iPhone and Mac must be on the same Wi-Fi network. For an Apple Watch, Apple requires Developer Mode on both the companion iPhone and the Watch during the pairing process. If wireless pairing is unstable, connect the iPhone to the Mac with a cable and pair the Watch through the iPhone first.

### 4. Install the iPhone app

Run the `OncoSense` scheme on the physical iPhone.

Then check the iPhone's **Care → Apple Watch** connection screen. The important state is:

```text
Apple Watch paired       ✓
OncoSense Watch app       ✓
WatchConnectivity         ✓
Live channel              optional
```

If the screen says **OncoSense Watch app not installed**, the iPhone/Watch pairing itself is not the problem. The watchOS product has not been installed on the active Watch yet.

### 5. Install/run the Watch app

Select the `OncoSenseWatch` scheme and choose the physical Apple Watch as the run destination. Build and run it once.

After installation, return to the iPhone connection screen. `isWatchAppInstalled` should become true after WatchConnectivity activation.

### 6. Verify the actual data path

On the Watch:

1. Grant HealthKit permissions.
2. Tap **Refresh & Sync**.
3. Confirm that a real HealthKit snapshot is shown.

On the iPhone:

1. Open **Care → Apple Watch**.
2. Confirm the Watch app is installed.
3. Confirm the session is active.
4. Tap **Sync latest health snapshot** if needed.
5. Confirm **Last received** changes after the Watch sends data.

## If Xcode reports `RemotePairingError Code 1001`

An error such as:

```text
Timed out while attempting to establish tunnel using negotiated network parameters
```

is a Mac ↔ physical-device transport problem, not a WatchConnectivity API problem inside OncoSense.

Use this order:

1. Unlock the iPhone and Watch.
2. Make sure Wi-Fi is enabled on the Mac and iPhone.
3. Put the Mac and iPhone on the same Wi-Fi network.
4. Keep the iPhone connected to the Mac by cable while establishing the Watch pairing if wireless tunneling is failing.
5. Open Xcode → Device Hub and make sure both devices appear as paired/available.
6. If the devices are stuck in a bad state, unpair and pair them again in Device Hub.
7. Restart the iPhone and Watch if the trust/pairing prompt was dismissed.
8. Run the iPhone target first, then the Watch target.

Do not treat a successful iPhone build as proof that the Watch app is installed. The physical Watch target must be installed and activated too.

## Interpreting the important logs

### `WCSession counterpart app not installed`

The active counterpart app is not installed. On iPhone this normally means `isWatchAppInstalled == false`. Install/run `OncoSenseWatch` on the active physical Watch.

### `WCSession has not been activated`

The session was queried or used before asynchronous activation completed. OncoSense now avoids reading pairing/install state until activation completes and publishes the activation error separately.

### `isReachable == false`

This only means the counterpart app is not available for live messaging at that moment. It is not, by itself, a pairing failure.

### `sendMessage` timeout

New health synchronization should not rely on `sendMessage`. OncoSense uses durable application context and queued user-info transfers instead.

## Submission acceptance criterion

The physical verification is complete only when all of these are true:

- iPhone app launches on the real iPhone.
- Watch app launches on the real Apple Watch.
- iPhone reports the Watch app as installed.
- WatchConnectivity activates on both sides.
- A Watch HealthKit snapshot reaches the iPhone.
- A request from the iPhone can reach the Watch through queued transfer.
- Temporary `isReachable == false` does not break background synchronization.
- No repeated `sendMessage` timeout spam appears in the normal health-sync path.
