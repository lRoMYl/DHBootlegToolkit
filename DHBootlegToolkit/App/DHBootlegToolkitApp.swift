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
        }

        Settings {
            SettingsView()
                .environment(appStore)
                .environment(s3Store)
                .environment(stockTickerStore)
        }
    }
}
