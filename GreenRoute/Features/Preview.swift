//
//  Preview.swift
//  GreenRoute
//
//  Created by David Rivera on 21/04/2026.
//
// Full-app preview that boots a real GreenRouteService instance so Xcode canvas
// shows the complete tab bar experience without mocks.

import SwiftUI
import GreenRouteService

#Preview {
    AppCompositionRoot(service: GreenRouteServiceFactory.make())
}
