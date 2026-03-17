//
//  GreenRouteServiceFacade.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 03/03/2026.
//

import Foundation

public protocol GreenRouteService: Sendable {
    var events: AsyncStream<ServiceEvent> { get }
    func start() async
    func stop() async
}

public final class GreenRouteServiceFacade: GreenRouteService, @unchecked Sendable {

    private let container: DependencyContainer

    private let stream: AsyncStream<ServiceEvent>
    private let continuation: AsyncStream<ServiceEvent>.Continuation

    public var events: AsyncStream<ServiceEvent> { stream }

    // internal init (DependencyContainer is internal)
    init(container: DependencyContainer) {
        self.container = container

        var localContinuation: AsyncStream<ServiceEvent>.Continuation!
        self.stream = AsyncStream { continuation in
            localContinuation = continuation
        }
        self.continuation = localContinuation

        // Important: do NOT capture `self` in the sink closure (Swift 6 sendability).
        let continuation = self.continuation
        Task {
            await container.bindEventSink { event in
                continuation.yield(event)
            }
        }
    }

    public func start() async {
        await container.start()
    }

    public func stop() async {
        continuation.finish()
        await container.stop()
    }

}
