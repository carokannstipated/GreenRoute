//
//  PermissionsViewModel.swift
//  GreenRoute
//
//  Created by David Rivera on 22/04/2026.
//
// View model for the Permissions screen. Reads system authorization statuses for
// location, notifications, and motion, and exposes them as human-readable strings.

import Foundation
import UIKit
import CoreLocation
import CoreMotion
import UserNotifications

/// Fetches and exposes the current authorization status for each permission GreenRoute requires.
/// Does not request permissions — it only reads the existing system-level authorization state.
@MainActor
@Observable
final class PermissionsViewModel {

    /// Human-readable location authorization status: "Always", "While Using", "Denied", "Not Set", or "Unknown".
    var locationStatus = "Unknown"
    /// Human-readable notification authorization status: "Allowed", "Denied", "Not Set", or "Unknown".
    var notificationStatus = "Unknown"
    /// Human-readable motion & fitness authorization status: "Allowed", "Denied", "Not Set", or "Unknown".
    var motionStatus = "Unknown"

    /// Refreshes all three permission statuses from the system.
    /// Safe to call each time the Permissions view appears.
    func refreshStatuses() async {
        let locStatus = CLLocationManager().authorizationStatus
        switch locStatus {
        case .authorizedAlways:     locationStatus = "Always"
        case .authorizedWhenInUse:  locationStatus = "While Using"
        case .denied, .restricted:  locationStatus = "Denied"
        case .notDetermined:        locationStatus = "Not Set"
        @unknown default:           locationStatus = "Unknown"
        }

        let notifSettings = await UNUserNotificationCenter.current().notificationSettings()
        switch notifSettings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:    notificationStatus = "Allowed"
        case .denied:                                   notificationStatus = "Denied"
        case .notDetermined:                            notificationStatus = "Not Set"
        @unknown default:                               notificationStatus = "Unknown"
        }

        switch CMMotionActivityManager.authorizationStatus() {
        case .authorized:               motionStatus = "Allowed"
        case .denied, .restricted:      motionStatus = "Denied"
        case .notDetermined:            motionStatus = "Not Set"
        @unknown default:               motionStatus = "Unknown"
        }
    }

    /// Triggers the iOS permission prompt for Motion & Fitness by performing a one-shot activity query.
    /// The completion handler always fires (even on denial), so the caller can safely await it.
    /// After the user responds, statuses are refreshed to reflect the new state.
    func requestMotionPermission() async {
        let manager = CMMotionActivityManager()
        let now = Date()
        await withCheckedContinuation { continuation in
            manager.queryActivityStarting(from: now, to: now, to: .main) { _, _ in
                continuation.resume()
            }
        }
        await refreshStatuses()
    }

    /// Opens the app's page in the iOS Settings app so the user can change permissions manually.
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
