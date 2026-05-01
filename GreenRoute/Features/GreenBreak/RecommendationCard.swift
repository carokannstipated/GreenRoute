//
//  RecommendationCard.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//
// Card component displayed when the service determines it's a good time for a green break.
// Supports swipe-to-dismiss in addition to the explicit buttons.

import SwiftUI
import GreenRouteDomain
import GreenRouteService

/// Displays a recommendation for a nearby green area with accept and dismiss actions.
/// Dragging the card more than 120 pt in either direction triggers a dismiss with a slide-out animation.
struct RecommendationCard: View {

    let recommendation: Recommendation
    let onAccept: () -> Void
    let onDismiss: () -> Void

    /// Current horizontal drag offset, drives the card's position during a swipe gesture.
    @State private var offset: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: kindIcon)
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("Time for a green break?")
                    .font(.headline)
                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text(recommendation.target.name)
                    .font(.title3.bold())

                HStack {
                    Label("\(Int(recommendation.distance.value))m away", systemImage: "mappin")
                    Spacer()
                    Label("~\(recommendation.estimatedWalkMinutes) min walk", systemImage: "figure.walk")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button("Maybe later", action: onDismiss)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                Button("Start route", action: onAccept)
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .offset(x: offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation.width
                }
                .onEnded { value in
                    if abs(value.translation.width) > 120 {
                        // Swipe was long enough — animate the card off screen, then call dismiss.
                        withAnimation(.easeOut(duration: 0.3)) {
                            offset = value.translation.width > 0 ? 500 : -500
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDismiss()
                        }
                    } else {
                        // Swipe was too short — spring the card back to centre.
                        withAnimation(.spring) {
                            offset = 0
                        }
                    }
                }
        )
        .animation(.interactiveSpring, value: offset)
    }

    /// Maps the green area kind to an appropriate SF Symbol name.
    private var kindIcon: String {
        switch recommendation.target.kind {
        case .park:          return "tree.fill"
        case .beach:         return "water.waves"
        case .forest:        return "leaf.fill"
        case .natureReserve: return "mountain.2.fill"
        case .other:         return "mappin.circle.fill"
        }
    }
}

#Preview {
    AppCompositionRoot(service: GreenRouteServiceFactory.make())
}
