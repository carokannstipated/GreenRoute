//
//  GreenRouteServiceFactory.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 03/03/2026.
//

import Foundation

public enum GreenRouteServiceFactory {
    public static func make() -> any GreenRouteService {
        let (container, providers) = DependencyContainer.production()
        return GreenRouteServiceFacade(
            container: container,
            notificationScheduler: providers.notificationScheduler,
            greenAreaProvider: providers.greenAreaProvider,
            routeProvider: providers.routeProvider,
            inactivityChecker: providers.inactivityChecker
        )
    }
}
