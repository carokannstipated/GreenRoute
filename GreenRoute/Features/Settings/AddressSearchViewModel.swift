//
//  AddressSearchViewModel.swift
//  GreenRoute
//
//  Created by David Rivera on 22/04/2026.
//

import MapKit
import GreenRouteDomain

@MainActor
@Observable
final class AddressSearchViewModel: NSObject, MKLocalSearchCompleterDelegate {
    var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func search(_ query: String) {
        completer.queryFragment = query
    }

    func resolve(_ completion: MKLocalSearchCompletion) async -> SavedAddress? {
        let request = MKLocalSearch.Request(completion: completion)
        let response = try? await MKLocalSearch(request: request).start()
        guard let item = response?.mapItems.first else { return nil }
        let location = item.location
        return SavedAddress(
            displayName: completion.title,
            coordinate: Coordinate(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        )
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }
}
