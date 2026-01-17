import SwiftUI
import AppKit
import DHBootlegToolkitCore

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// MARK: - App

@main
struct DHBootlegToolkitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appStore = AppStore()
    @State private var s3Store = S3Store()
    @State private var stockTickerStore = StockTickerStore()
    @State private var showResetConfirmation = false

    var body: some Scene {
        WindowGroup("DH Bootleg Toolkit") {
            MainSplitView()
                .environment(appStore)
                .environment(s3Store)
                .environment(stockTickerStore)
                .frame(minWidth: 1000, minHeight: 600)
                .onAppear {
                    Task {
                        await AppLogger.shared.timedGroup("App Startup") { ctx in
                            AppLogger.shared.info("App started")

                            // Start stock monitoring
                            await ctx.time("Start stock monitoring") {
                                await stockTickerStore.startMonitoring()
                            }

                            // Restore last localization repository on launch
                            if let savedURL = UserDefaults.standard.url(forKey: "lastRepositoryURL") {
                                await ctx.time("Restore localization repository") {
                                    await appStore.selectRepository(savedURL, showAlertOnError: false)
                                }
                            }

                            // Restore last S3 repository on launch
                            if let savedS3URL = UserDefaults.standard.url(forKey: "lastS3RepositoryURL") {
                                await ctx.time("Restore S3 repository") {
                                    await s3Store.loadRepository(at: savedS3URL)
                                }
                            }
                        }
                    }
                }
                .onChange(of: appStore.repositoryURL) { _, newURL in
                    // Save localization repository URL when changed
                    if let url = newURL {
                        UserDefaults.standard.set(url, forKey: "lastRepositoryURL")
                    }
                }
                .onChange(of: s3Store.s3RepositoryURL) { _, newURL in
                    // Save S3 repository URL when changed
                    if let url = newURL {
                        UserDefaults.standard.set(url, forKey: "lastS3RepositoryURL")
                    }
                }
                .alert("Reset All Settings", isPresented: $showResetConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Reset", role: .destructive) {
                        resetAllSettings()
                    }
                } message: {
                    Text("This will clear all cached data and settings. The app will restart.")
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Translation Key") {
                    appStore.createNewKey()
                }
                .keyboardShortcut("n", modifiers: [.command])

                Divider()

                Button("Open Repository...") {
                    appStore.showRepositoryPicker()
                }
                .keyboardShortcut("o", modifiers: [.command])
            }

            CommandGroup(after: .saveItem) {
                Button("Save") {
                    Task {
                        do {
                            try await appStore.saveCurrentFile()
                        } catch let error as FileOperationError {
                            if error.canForceOverwrite {
                                // For external modification from keyboard shortcut,
                                // route through the store's external change conflict dialog
                                appStore.showExternalChangeConflict = true
                            } else {
                                appStore.publishErrorMessage = error.localizedDescription
                                appStore.showPublishError = true
                            }
                        } catch {
                            appStore.publishErrorMessage = error.localizedDescription
                            appStore.showPublishError = true
                        }
                    }
                }
                .keyboardShortcut("s", modifiers: [.command])
                .disabled(!appStore.hasChanges)
            }

            CommandGroup(after: .appSettings) {
                Divider()

                Menu("Reset...") {
                    Button("Clear Stock Cache") {
                        clearStockCache()
                        stockTickerStore.clearCache()
                    }

                    Button("Clear Repository Settings") {
                        clearRepositorySettings()
                    }

                    Divider()

                    Button("Reset All Settings...") {
                        showResetConfirmation = true
                    }
                }
            }
        }

        Settings {
            SettingsView()
                .environment(appStore)
                .environment(s3Store)
                .environment(stockTickerStore)
        }
    }

    // MARK: - Reset Functions

    private func clearStockCache() {
        let defaults = UserDefaults.standard
        // Clear stock data cache
        for symbol in ["DHER.DE", "TALABAT.AE"] {
            defaults.removeObject(forKey: "stock_\(symbol)")
            defaults.removeObject(forKey: "sentiment_\(symbol)")
        }
        defaults.removeObject(forKey: "selectedChartRange")
    }

    private func clearRepositorySettings() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "lastRepositoryURL")
        defaults.removeObject(forKey: "lastS3RepositoryURL")
    }

    private func resetAllSettings() {
        let defaults = UserDefaults.standard
        // Clear all known keys
        clearStockCache()
        clearRepositorySettings()
        defaults.removeObject(forKey: "selectedSidebarTab")

        // Restart the app
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()

        NSApplication.shared.terminate(nil)
    }
}
