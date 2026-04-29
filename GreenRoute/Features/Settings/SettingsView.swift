//
//  SettingsView.swift
//  GreenRoute
//
//  Created by David Rivera on 14/04/2026.
//

import SwiftUI
import MapKit
import GreenRouteDomain

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

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
                    RoutePreferencesView(viewModel: viewModel)
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
    }
}


private struct PermissionsView: View {
    @State private var viewModel = PermissionsViewModel()
    @State private var showingLocationAlert = false
    @State private var showingNotificationAlert = false
    @State private var showingMotionAlert = false

    var body: some View {
        Form {
            Section {
                permissionRow(
                    icon: "location.fill",
                    iconColor: .blue,
                    title: "Location",
                    status: viewModel.locationStatus
                ) {
                    showingLocationAlert = true
                }

                permissionRow(
                    icon: "bell.fill",
                    iconColor: .orange,
                    title: "Notifications",
                    status: viewModel.notificationStatus
                ) {
                    showingNotificationAlert = true
                }

                permissionRow(
                    icon: "figure.walk.motion",
                    iconColor: .green,
                    title: "Motion & Fitness",
                    status: viewModel.motionStatus
                ) {
                    if viewModel.motionStatus == "Not Set" {
                        Task { await viewModel.requestMotionPermission() }
                    } else {
                        showingMotionAlert = true
                    }
                }
            } header: {
                Text("Device permissions")
            } footer: {
                Text("Permissions are managed in your device's Settings app.")
            }
        }
        .navigationTitle("Permissions")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.refreshStatuses() }
        .alert("Location Access", isPresented: $showingLocationAlert) {
            Button("Open Settings") { viewModel.openSettings() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To change location permissions, go to Settings > GreenRoute > Location.")
        }
        .alert("Notification Access", isPresented: $showingNotificationAlert) {
            Button("Open Settings") { viewModel.openSettings() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To change notification permissions, go to Settings > GreenRoute > Notifications.")
        }
        .alert("Motion & Fitness Access", isPresented: $showingMotionAlert) {
            Button("Open Settings") { viewModel.openSettings() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To change motion permissions, go to Settings > Privacy & Security > Motion & Fitness > GreenRoute.")
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
}


private struct RoutePreferencesView: View {
    var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Stepper(
                    value: Binding(
                        get: { viewModel.maxRouteDuration },
                        set: { viewModel.setMaxRouteDuration($0) }
                    ),
                    in: 5...60,
                    step: 5
                ) {
                    HStack {
                        settingsIcon(systemName: "clock.fill", color: .green)
                        Text("Max Duration")
                        Spacer()
                        Text("\(viewModel.maxRouteDuration) min")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Green Break Preferences")
            } footer: {
                Text("Setting this duration does not affect Green Meeting duration.")
            }

            Section {
                NavigationLink {
                    AddressPickerView(current: viewModel.homeAddress) { viewModel.setHomeAddress($0) }
                } label: {
                    HStack {
                        settingsIcon(systemName: "house.fill", color: .blue)
                        Text("Home")
                        Spacer()
                        Text(viewModel.homeAddress?.displayName ?? "Not set")
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                NavigationLink {
                    AddressPickerView(current: viewModel.workAddress) { viewModel.setWorkAddress($0) }
                } label: {
                    HStack {
                        settingsIcon(systemName: "briefcase.fill", color: .orange)
                        Text("Work")
                        Spacer()
                        Text(viewModel.workAddress?.displayName ?? "Not set")
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            } header: {
                Text("Saved Addresses")
            } footer: {
                Text("Used to calculate routes from familiar locations.")
            }
        }
        .navigationTitle("Route Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.reload() }
    }
}


private struct AddressPickerView: View {
    let current: SavedAddress?
    let onSelect: (SavedAddress?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var viewModel = AddressSearchViewModel()
    @State private var keyboardVisible = false


    var body: some View {
        List {
            if searchText.isEmpty {
                ContentUnavailableView(
                    "Search for an address",
                    systemImage: "magnifyingglass",
                    description: Text("Start typing to see suggestions.")
                )
                .listRowBackground(Color.clear)
            } else if viewModel.results.isEmpty {
                ContentUnavailableView(
                    "No results",
                    systemImage: "mappin.slash",
                    description: Text("Try a different search term.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.results, id: \.self) { result in
                    Button {
                        Task {
                            if let saved = await viewModel.resolve(result) {
                                onSelect(saved)
                                dismiss()
                            }
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(result.title)
                            if !result.subtitle.isEmpty {
                                Text(result.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search address")
        .onChange(of: searchText) { viewModel.search(searchText) }
        .navigationTitle("Choose Address")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .overlay(alignment: .bottom) {
        
            if current != nil && !keyboardVisible {
                Button(role: .destructive) {
                    onSelect(nil)
                    dismiss()
                } label: {
                    Label("Remove Address", systemImage: "trash")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .glassEffect()
                }
                .padding(.bottom, 16)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            keyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardVisible = false
        }
    }
}


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
}


private extension View {
    func settingsIcon(systemName: String, color: Color) -> some View {
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
        SettingsView(viewModel: SettingsViewModel(repository: PreviewSettingsRepository()))
    }
}
