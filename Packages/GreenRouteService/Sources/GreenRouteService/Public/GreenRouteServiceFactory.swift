//
//  GreenRouteServiceFactory.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 03/03/2026.
//

import Foundation

public enum GreenRouteServiceFactory {
    public static func make() -> GreenRouteService {
        GreenRouteServiceFacade(container: .production())
    }
}
