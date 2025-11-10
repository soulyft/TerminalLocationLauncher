# TerminalLocationLauncher

TerminalLocationLauncher is a small macOS utility that helps you create custom helper apps that instantly open Terminal in a folder you choose. Each helper app is ad-hoc signed and ready to be stored in places like `~/Applications`, `/Users/Shared`, or your Downloads folder so you can double-click it whenever you want a terminal session rooted in that directory.

## Requirements

- macOS 13 Ventura or later (tested with modern macOS versions)
- Xcode 15 or later to build the project
- Access to the `osacompile` tool (ships with macOS)

## Building the App

1. Clone or download this repository.
2. Open `TerminalLocationLauncher.xcodeproj` in Xcode.
3. Select the **My Mac** destination.
4. Press **Run** (`⌘R`) to build and launch the app.

The app is entirely sandbox-free, so you can also archive and notarize it if you want to distribute it.

## Using TerminalLocationLauncher

1. Launch the TerminalLocationLauncher app.
2. Click **Pick Folder** and choose the directory you want the helper to open.
3. Provide a descriptive name for the helper app (e.g., `Open Terminal at ProjectX`).
4. (Optional) Click **Change…** to pick the destination for the helper bundle. The defaults point to your `~/Downloads` folder; use the quick buttons for `~/Applications` or `/Users/Shared` if you prefer.
5. Press **Create App**.
6. When creation succeeds the status panel shows signing details, and Finder reveals the generated `.app` bundle. Double-click it to open Terminal directly in the folder you selected.

### Privacy & Security hint

The helper apps are ad-hoc signed. The first time you launch one, Gatekeeper may block it. If this happens:

1. In TerminalLocationLauncher, click **Open Privacy & Security** (or manually open **System Settings → Privacy & Security**).
2. Scroll down to the **Security** section and click **Open Anyway** next to the blocked helper.
3. Launch the helper again. macOS will prompt you once more; choose **Open** to trust it permanently.

Alternatively, you can right-click the helper in Finder, choose **Open**, and confirm.

## Troubleshooting

- If you see a message about saving inside the sandbox (`/Library/Containers/...`), use **Change…** and pick a destination such as `~/Applications`, `~/Downloads`, or `/Users/Shared`.
- If `osacompile` fails, try saving the helper to a different destination first, then move it wherever you need once it is created.
- Use the **Copy** button in the status panel to grab full log details (including `spctl` and `codesign` output) when sharing reports.

## License

No license information is currently provided. Please reach out to the project maintainers if you plan to use or distribute this code.
