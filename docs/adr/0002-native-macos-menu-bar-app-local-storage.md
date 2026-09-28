# Native macOS menu-bar app with local storage only

Pomopomo is a native Swift/SwiftUI menu-bar app (`MenuBarExtra`) for macOS only. It stores everything on the Mac, with no accounts and no syncing. Native gives us the smallest app, a proper menu-bar feel, system notifications, and reliable sleep/wake events. We need those events because a Running Pomodoro pauses automatically when the Mac sleeps, and a new Day has to be noticed after waking.

## Considered Options

- **Offline browser app**: rejected because browsers slow down timers in background tabs and give no reliable sleep/wake signal.
- **Tauri / Electron (cross-platform)**: rejected because the app is for one person on a Mac, and Electron is too heavy for something that sits in the menu bar.
- **iCloud sync (SwiftData + CloudKit)**: left out because two Macs could each have a Pomodoro Running, which breaks the rule of at most one unfinished Pomodoro per Day. SwiftData keeps the door open to adding it later.
