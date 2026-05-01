// View model for the address search picker. Wraps MKLocalSearchCompleter to provide
// live autocomplete suggestions and resolves a chosen suggestion into a SavedAddress with coordinates.

import MapKit
import GreenRouteDomain

/// Drives the address picker UI by managing a MapKit autocomplete session.
/// Exposes completion suggestions reactively and resolves the selected suggestion to a coordinate.
@MainActor
@Observable
final class AddressSearchViewModel: NSObject, MKLocalSearchCompleterDelegate {

    /// Current list of autocomplete suggestions from MapKit, updated as the user types.
    var results: [MKLocalSearchCompletion] = []

    /// Underlying MapKit completer. Configured to return address-type results only.
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        // Restrict suggestions to addresses — excludes points of interest.
        completer.resultTypes = .address
    }

    /// Updates the completer's query fragment, triggering a new round of autocomplete suggestions.
    /// - Parameter query: The current text from the search field.
    func search(_ query: String) {
        completer.queryFragment = query
    }

    /// Resolves an autocomplete suggestion into a SavedAddress by performing a full MKLocalSearch.
    /// Returns nil if the search fails or returns no map items.
    /// - Parameter completion: The suggestion selected by the user.
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

    /// Called by MKLocalSearchCompleter when new suggestions are available.
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    /// Called when the completer encounters an error. Clears results to avoid showing stale suggestions.
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }
}
