//
//  SettingsView.swift
//  GreenRoute
//
//  Created by David Rivera on 14/04/2026.
//

import SwiftUI
import CoreLocation
import UserNotifications
import GreenRouteDomain

struct SettingsView: View {
    let settingsRepository: SettingsRepository
    @State private var maxRouteDuration = 15

    var body: some View {
        Form {
            Section("General") {
                NavigationLink {
                    PermissionsView()
                } label: {
                    HStack {
                        settingsIcon(systemName: "lock.shield.fill", color: .blue)
                        Text("Permissions")
                    }
                }

                NavigationLink {
                    RoutePreferencesView(maxRouteDuration: $maxRouteDuration)
                } label: {
                    HStack {
                        settingsIcon(systemName: "map.fill", color: .green)
                        Text("Route Preferences")
                    }
                }

                NavigationLink {
                    AboutView()
                } label: {
                    HStack {
                        settingsIcon(systemName: "info.circle.fill", color: .blue)
                        Text("About")
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            maxRouteDuration = settingsRepository.load().maxRouteDurationMinutes
        }
        .onChange(of: maxRouteDuration) {
            var settings = settingsRepository.load()
            settings.maxRouteDurationMinutes = maxRouteDuration
            settingsRepository.save(settings)
        }
    }

    private func settingsIcon(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.body)
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(color, in: RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - General (Permissions)

private struct PermissionsView: View {
    @State private var locationStatus: String = "Unknown"
    @State private var notificationStatus: String = "Unknown"
    @State private var showingLocationAlert = false
    @State private var showingNotificationAlert = false

    var body: some View {
        Form {
            Section {
                permissionRow(
                    icon: "location.fill",
                    iconColor: .blue,
                    title: "Location",
                    status: locationStatus
                ) {
                    showingLocationAlert = true
                }

                permissionRow(
                    icon: "bell.fill",
                    iconColor: .orange,
                    title: "Notifications",
                    status: notificationStatus
                ) {
                    showingNotificationAlert = true
                }
            } header: {
                Color.clear.frame(height: 20)
            } footer: {
                Text("Permissions are managed in your device's Settings app.")
            }
        }
        .navigationTitle("Permissions")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshStatuses() }
        .alert("Location Access", isPresented: $showingLocationAlert) {
            Button("Open Settings") { openSettings() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To change location permissions, go to Settings > GreenRoute > Location.")
        }
        .alert("Notification Access", isPresented: $showingNotificationAlert) {
            Button("Open Settings") { openSettings() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To change notification permissions, go to Settings > GreenRoute > Notifications.")
        }
    }

    private func refreshStatuses() async {
        // Location
        let locStatus = CLLocationManager().authorizationStatus
        switch locStatus {
        case .authorizedAlways:
            locationStatus = "Always"
        case .authorizedWhenInUse:
            locationStatus = "While Using"
        case .denied, .restricted:
            locationStatus = "Denied"
        case .notDetermined:
            locationStatus = "Not Set"
        @unknown default:
            locationStatus = "Unknown"
        }

        // Notifications
        let notifSettings = await UNUserNotificationCenter.current().notificationSettings()
        switch notifSettings.authorizationStatus {
        case .authorized, .provisional:
            notificationStatus = "Allowed"
        case .denied:
            notificationStatus = "Denied"
        case .notDetermined:
            notificationStatus = "Not Set"
        case .ephemeral:
            notificationStatus = "Allowed"
        @unknown default:
            notificationStatus = "Unknown"
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func permissionRow(icon: String, iconColor: Color, title: String, status: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                settingsIcon(systemName: icon, color: iconColor)
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Text(status)
                    .foregroundColor(status == "Denied" || status == "Not Set" || status == "Unknown" ? .secondary : .green)
                    .font(.subheadline)
            }
        }
    }

    private func settingsIcon(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.body)
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(color, in: RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Route Preferences

private struct RoutePreferencesView: View {
    @Binding var maxRouteDuration: Int

    var body: some View {
        Form {
            Section {
                Stepper(value: $maxRouteDuration, in: 5...60, step: 5) {
                    HStack {
                        settingsIcon(systemName: "clock.fill", color: .green)
                        Text("Max Duration")
                        Spacer()
                        Text("\(maxRouteDuration) min")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Route Preferences")
        .navigationBarTitleDisplayMode(.inline)

    }

    private func settingsIcon(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.body)
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(color, in: RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - About

private struct AboutView: View {
    var body: some View {
        Form {
            Section {
                HStack {
                    settingsIcon(systemName: "info.circle.fill", color: .gray)
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)

    }

    private func settingsIcon(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.body)
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(color, in: RoundedRectangle(cornerRadius: 6))
    }
}

private final class PreviewSettingsRepository: SettingsRepository, @unchecked Sendable {
    private var settings = AppSettings.default
    func load() -> AppSettings { settings }
    func save(_ settings: AppSettings) { self.settings = settings }
}

#Preview {
    NavigationStack {
        SettingsView(settingsRepository: PreviewSettingsRepository())
    }
}
