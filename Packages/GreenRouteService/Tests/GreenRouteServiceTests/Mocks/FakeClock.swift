//
//  FakeClock.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 03/03/2026.
//

import Foundation
@testable import GreenRouteService

final class FakeClock: Clock, @unchecked Sendable {
    var current: Date
    init(current: Date) { self.current = current }
    func now() -> Date { current }
}
