# Nurse Vault

A private, offline-capable reference vault for nursing practice — available on
**iPhone, iPad, Mac, and Apple Watch**, with everything you store synced
securely across all of your devices via **iCloud (CloudKit private database)**.

No third-party servers, no accounts, no subscriptions. Your data is only ever
accessible by your own Apple ID.

## Main menu sections

The app ships with four sections and a **+** button to add unlimited more:

| Section | Icon | Typical use |
|---|---|---|
| Code Blue | cross.vial | ACL/Code Blue flows, resuscitation checklists |
| Lab Values | test tubes | Normal lab ranges, critical values |
| Drugs | pills | Dose tables, drug references |
| Other | folder | Anything else |

Sections can be renamed, reordered (drag), or deleted at any time.

## What you can store

- **Files** — PDFs (in-app viewer), images (in-app viewer), text/RTF, and any
  other file up to **48 MB** each (shared via the context menu).
  Import with **Add → Import Files…**, **Add → Import Photos…**, or just
  **drag & drop** files into a list (Mac/iPad).
- **Notes** — pure text references (**Add → New Note**).
- Every document can carry a title, notes, and be moved between sections.

## How sync works

- Documents live in a Core Data store on each device and are mirrored to your
  **private** CloudKit database (`iCloud.<your bundle ID>`).
- The private database is only readable/writable by your Apple ID — no one else
  can see or touch it, and it never leaves Apple's infrastructure.
- Everything works **offline**: changes are saved locally and sync
  automatically when a connection is available. The sync badge in the toolbar
  shows the current state (Synced / Offline / iCloud sign-in needed).
- Remote edits made on one device appear on the others when the app next
  connects (and automatically while an app is open).

## First-time setup (one-time)

1. Open `NurseVault.xcodeproj` in Xcode (16+ required; 27 tested).
2. You'll be prompted to pick a **team** — choose your Apple ID (personal team
   is fine for personal use).
3. The two targets are **NurseVault** (iPhone/iPad/Mac) and **NurseVault
   Watch**. Each has an iCloud capability with the container
   `iCloud.com.josephwoods.nursevault` preconfigured.
   - If you want your own bundle IDs, change them under
     **Signing & Capabilities** on each target, and update the
     `icloud-container-identifiers` entry in the corresponding `.entitlements`
     file to match the new bundle ID (the container must be
     `iCloud.<bundle-id>`).
4. **To test without a device:** run the iPhone simulator and sign in to iCloud
   there (tap the app's "iCloud Sign-In Needed" badge for a reminder: open
   the simulator's **Settings → sign in with an Apple ID**). Sign in on the
   Mac too (System Settings → Apple Account → iCloud) and on the Watch
   (Watch app → Settings → Apple ID). Once every device is signed in with the
   **same Apple ID**, everything syncs between them.

> **Note on real devices & the App Store:** installing on a physical device or
> submitting to the App Store requires a **paid Apple Developer account**
> ($99/yr). Simulators work without one.
>
> ⚠️ **Free (personal) Apple ID accounts do not support the iCloud capability**
> at all — Xcode will show a "processing" state that never finishes and will
> not create provisioning profiles for a device build. This is an Apple
> restriction, not a bug, and waiting or retrying will not help. You can still
> do full development and sync testing in simulators (see below); a paid
> account is only needed to run on physical devices.

### App Store Connect (only if you publish)

If you eventually want the app in the App Store, create an app record in
[App Store Connect](https://appstoreconnect.apple.com) matching your bundle ID
(`com.josephwoods.nursevault` and `…watchkitapp`), then in Xcode choose
**Product → Archive** for each target and distribute. No repositories or
external services are required — the CloudKit container is created
automatically in your CloudKit dashboard when you sign.

## Project layout

```
App/                        Main app sources (iPhone, iPad, Mac)
  NurseVaultApp.swift       App entry point
  RootView.swift            Sidebar (sections) + section management
  DocListView.swift         Document list, import menu, drag & drop, sync badge
  DocDetailView.swift       Preview (PDF/image/text) + editing
  ImportView.swift          File / photo / note import flows
  NurseVault.entitlements   iCloud + sandbox (main app)
Watch/                      Apple Watch app (read-only reference)
  NurseVaultWatchApp.swift  Entry point + section/document views
  WatchEntitlements.entitlements
Packages/NurseVaultCore/    Shared Swift package:
  VaultModels.swift         Core Data model (Section / Doc)
  Library.swift             Store + CloudKit sync engine + offline status
  FileSupport.swift         File import helpers, size limits, doc kinds
  VaultViews.swift          Cross-platform PDF + image viewers
```

### Testing sync right now (free, no waiting)

1. Run the app in the **iPhone or iPad simulator** (it needs no provisioning
   profile). If Xcode shows the simulator in **Device Hub**, use that; pick
   the running iPhone there.
2. In the simulator: **Settings → tap your name/Sign in** → sign in with your
   Apple ID.
3. On your Mac: **System Settings → Apple Account → iCloud** → sign in with
   the **same** Apple ID.
4. Open Nurse Vault on both — add a document on one, and it appears on the
   other. The sync badge should read **Synced**.
5. Watch: run the watch simulator paired with your iPhone simulator; it
   inherits the same iCloud sign-in.

## Practical notes

- The **watch app is read-only**: browse sections, open PDFs/images/notes.
  Import from the phone, iPad, or Mac — it appears on the watch automatically.
- Files larger than 48 MB can't be synced (a CloudKit per-record limit);
  the app tells you when a file is too big.
- Deleting a section deletes its documents (with confirmation). Deleting a
  document from any device removes it everywhere.
- Everything is encrypted in transit and at rest by iCloud; data stays on
  Apple's servers, never third parties.
