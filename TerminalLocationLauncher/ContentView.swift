//
//  ContentView.swift
//  TerminalLocationLauncher
//
//  Created by Corey Lofthus on 10/23/25.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var pickedFolderURL: URL?
    @State private var appName: String = ""
    @State private var destinationURL: URL = URL(fileURLWithPath: "/Users/\(NSUserName())/Downloads", isDirectory: true)
    @State private var status: String = "Pick a folder, name the helper, then Create."

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create “Open Terminal at …” App")
                .font(.title2).bold()

            GroupBox {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Folder to open in Terminal:")
                            .font(.headline)
                        Text(pickedFolderURL?.path ?? "None selected")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .textSelection(.enabled)
                    }
                    Spacer()
                    Button("Pick Folder") { pickFolder() }
                }
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Helper App Name:")
                        .font(.headline)
                    TextField("Open Terminal at MyProject", text: $appName)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Destination:")
                                .font(.headline)
                            Text(destinationURL.path)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .textSelection(.enabled)
                        }
                        Spacer()
                        Button("Change…") { pickDestination() }
                    }
                    if destinationURL.path.contains("/Library/Containers/") {
                        Text("Warning: You’re saving inside the app’s sandbox. Choose “~/Applications” (your user Applications), “~/Downloads”, or “/Users/Shared” via Change… → Go to Folder.")
                            .font(.footnote)
                            .foregroundStyle(.yellow)
                            .padding(.top, 4)
                        HStack(spacing: 8) {
                            Button("Use ~/Downloads") {
                                destinationURL = URL(fileURLWithPath: "/Users/\(NSUserName())/Downloads", isDirectory: true)
                                try? FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
                            }
                            Button("Use ~/Applications") {
                                destinationURL = URL(fileURLWithPath: "/Users/\(NSUserName())/Applications", isDirectory: true)
                                try? FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
                            }
                            Button("Use /Users/Shared") {
                                destinationURL = URL(fileURLWithPath: "/Users/Shared", isDirectory: true)
                                try? FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
                            }
                        }
                    }
                }
            }

            HStack {
                Button("Create App") { createHelper() }
                    .buttonStyle(.borderedProminent)
                    .disabled(pickedFolderURL == nil || appName.trimmingCharacters(in: .whitespaces).isEmpty)
                Button("Reveal Destination") { revealDestination() }
                Spacer()
            }

            Divider()
            VStack(alignment: .leading) {
                HStack {
                    Text("Status").font(.headline)
                    Spacer()
                    Button("Open Privacy & Security") { openPrivacySecurityPane() }
                    Button("Copy") { copyStatus() }
                }
                TextEditor(text: $status)
                    .font(.system(.footnote, design: .monospaced))
                    .frame(minHeight: 100)
            }

            Spacer()
        }
        .padding(16)
        .onChange(of: pickedFolderURL) { _, newValue in
            if let url = newValue, appName.trimmingCharacters(in: .whitespaces).isEmpty {
                appName = "Open Terminal at \(url.lastPathComponent)"
            }
        }
    }

    // MARK: - UI Helpers

    private func pickFolder() {
        let p = NSOpenPanel()
        p.title = "Choose a folder to open in Terminal"
        p.canChooseFiles = false
        p.canChooseDirectories = true
        p.allowsMultipleSelection = false
        p.canCreateDirectories = false
        p.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        if p.runModal() == .OK {
            pickedFolderURL = p.url
        }
    }

    private func pickDestination() {
        let p = NSOpenPanel()
        p.title = "Choose where to save the helper app"
        p.canChooseFiles = false
        p.canChooseDirectories = true
        p.allowsMultipleSelection = false
        p.canCreateDirectories = true
        p.directoryURL = destinationURL
        if p.runModal() == .OK, let url = p.url {
            destinationURL = url
        }
    }

    private func revealDestination() {
        NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
    }

    private func copyStatus() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(status, forType: .string)
    }

    private func openPrivacySecurityPane() {
        // Try to open the Security & Privacy (General) pane directly
        let candidates = [
            "x-apple.systempreferences:com.apple.preference.security?General",
            "x-apple.systempreferences:com.apple.preference.security",
            "x-apple.systempreferences:"
        ]
        for s in candidates {
            if let url = URL(string: s), NSWorkspace.shared.open(url) {
                return
            }
        }
        // Fallback: open System Settings app
        let settingsApp = URL(fileURLWithPath: "/System/Applications/System Settings.app")
        _ = try? NSWorkspace.shared.openApplication(at: settingsApp, configuration: NSWorkspace.OpenConfiguration())
    }

    // MARK: - Core: create the helper via `osacompile`

    private func createHelper() {
        guard let folder = pickedFolderURL else {
            status = "Please pick a folder first."
            return
        }
        let trimmedName = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            status = "Please enter an app name."
            return
        }

        let outApp = destinationURL.appendingPathComponent("\(trimmedName).app", isDirectory: true)
        if destinationURL.path.contains("/Library/Containers/") {
            status = """
            Destination is inside the app’s sandbox:
            \(destinationURL.path)
            
            Please click “Change…” and select a real location like:
            • ~/Applications   (your user Applications)
            • /Users/Shared    (visible to all users)
            
            Tip: Use “Go to Folder…” in the panel and paste one of the paths above.
            """
            return
        }
        let fm = FileManager.default
        let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let tmpOutApp = tmpDir.appendingPathComponent("\(UUID().uuidString)-\(trimmedName).app", isDirectory: true)

        // Absolute POSIX path to embed into the AppleScript
        let absPath = folder.path

        let escapedPathForAS = absPath
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        // AppleScript droplet: handles both Run (no doc) and Open (folder dropped/launched)
        // This version does not use Apple Events and instead creates a .command file and opens it with Terminal.
        let appleScriptSource = """
        -- Generated by TerminalLocationLauncher (no Apple Events)
        on open theItems
          set targetPOSIX to "\(escapedPathForAS)"
          my openTerminalAt(targetPOSIX)
        end open

        on run
          set targetPOSIX to "\(escapedPathForAS)"
          my openTerminalAt(targetPOSIX)
        end run

        on openTerminalAt(targetPOSIX)
          -- Build a one-off .command script in /tmp that cd's into the target and launches a login shell
          set scriptPath to "/tmp/open-term-" & (do shell script "uuidgen") & ".command"
          set fileText to "#!/bin/zsh" & linefeed & "cd " & quoted form of targetPOSIX & linefeed & "exec /bin/zsh -l" & linefeed
          do shell script "/bin/echo " & quoted form of fileText & " > " & quoted form of scriptPath
          do shell script "/bin/chmod +x " & quoted form of scriptPath
          -- Open that .command with Terminal via Launch Services (no Automation permission needed)
          do shell script "/usr/bin/open -a " & quoted form of "/System/Applications/Utilities/Terminal.app" & " " & quoted form of scriptPath
        end openTerminalAt
        """

        do {
            try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
            try? fm.removeItem(at: tmpOutApp)

            let tmpAS = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("OpenTerminalHere-\(UUID().uuidString).applescript")
            try appleScriptSource.write(to: tmpAS, atomically: true, encoding: .utf8)

            // Use /usr/bin/osacompile to build the applet bundle to temporary location
            let compileResult = try runTool(
                "/usr/bin/osacompile",
                args: ["-o", tmpOutApp.path, tmpAS.path]
            )

            if compileResult.exitCode != 0 {
                status = """
                osacompile failed
                exit code: \(compileResult.exitCode)
                stderr:
                \(compileResult.stderr)

                Tip: If you chose a protected folder, pick a different destination (e.g., ~/Applications or /Users/Shared) via “Change…”.
                """
                return
            }

            try? FileManager.default.removeItem(at: tmpAS)

            // Replace destination atomically to avoid half-written bundles
            if fm.fileExists(atPath: outApp.path) {
                try? fm.removeItem(at: outApp)
            }
            do {
                try fm.copyItem(at: tmpOutApp, to: outApp)
                try? fm.removeItem(at: tmpOutApp)
            } catch {
                status = "Failed to move compiled app to destination: \(error.localizedDescription)"
                return
            }

            // Post-fix: ad-hoc sign, clear quarantine, ensure executable bit
            _ = try? runTool("/usr/bin/codesign", args: ["--force","--deep","-s","-","--options=runtime", outApp.path])
            _ = try? runTool("/usr/bin/xattr", args: ["-dr","com.apple.quarantine", outApp.path])
            _ = try? runTool("/bin/chmod", args: ["+x", outApp.appendingPathComponent("Contents/MacOS/applet").path])
            
            // Optional: show assessment info in status for debugging
            let assess = try? runTool("/usr/sbin/spctl", args: ["--assess","--type","execute","--verbose=4", outApp.path])
            let csInfo = try? runTool("/usr/bin/codesign", args: ["-dv","--verbose=4", outApp.path])

            let assessOut = assess?.stdout ?? ""
            let assessErr = assess?.stderr ?? ""
            let csOut = csInfo?.stdout ?? ""
            let csErr = csInfo?.stderr ?? ""
            status = """
            Created: \(outApp.path)
            
            If Finder blocks the app the first time, click “Open Privacy & Security”, then press **Open Anyway** for this app. After that, launches will work normally. You can also Right‑click → Open → Open once.
            
            spctl:
            \(assessOut)\(assessErr)
            
            codesign -dv:
            \(csOut)\(csErr)
            """
            // Reveal the app
            NSWorkspace.shared.activateFileViewerSelecting([outApp])
        } catch {
            status = "Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Shell runner

    private struct ToolResult {
        let exitCode: Int32
        let stdout: String
        let stderr: String
    }

    @discardableResult
    private func runTool(_ path: String, args: [String]) throws -> ToolResult {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let outPipe = Pipe()
        let errPipe = Pipe()
        p.standardOutput = outPipe
        p.standardError = errPipe
        try p.run()
        p.waitUntilExit()
        let out = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return ToolResult(exitCode: p.terminationStatus, stdout: out, stderr: err)
    }
}
