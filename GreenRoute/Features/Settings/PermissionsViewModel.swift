//
//  PermissionsViewModel.swift
//  GreenRoute
//
//  Created by David Rivera on 22/04/2026.
//

import Foundation
import UIKit
import CoreLocation
import UserNotifications

@MainActor
@Observable
final class PermissionsViewModel {
    var locationStatus = "Unknown"
    var notificationStatus = "Unknown"

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
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
