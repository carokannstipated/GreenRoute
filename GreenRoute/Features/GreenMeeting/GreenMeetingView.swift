import SwiftUI

struct GreenMeetingView: View {

    @State private var viewModel: GreenMeetingViewModel
    @State private var hours = 0
    @State private var minutes = 30

    init(viewModel: GreenMeetingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            background
            VStack(spacing: 24) {
                Text("Meeting Duration")
                    .font(.largeTitle.bold())

                picker

                Spacer().frame(maxHeight: 5)

                Button {
                    Task { await viewModel.startMeeting(hours: hours, minutes: minutes) }
                } label: {
                    Group {
                        if viewModel.isSearching {
                            ProgressView()
                        } else {
                            Label("Start Green Meeting", systemImage: "figure.walk")
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: 40)
                    .font(.title3.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.horizontal)
                .disabled(viewModel.isSearching || (hours == 0 && minutes == 0))
            }
        }
        .sheet(isPresented: $viewModel.isShowingMap) {
            if let greenArea = viewModel.foundGreenArea {
                GreenMeetingMapView(
                    greenArea: greenArea,
                    origin: viewModel.currentCoordinate,
                    totalDurationMinutes: (hours * 60) + minutes,
                    routeProvider: viewModel.routeProvider
                )
            }
        }
        .alert(
            "Could not find route",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var picker: some View {
        HStack(spacing: 0) {
            Text("hrs")
                .font(.body.bold())
                .frame(width: 50, alignment: .trailing)

            Picker("Hours", selection: $hours) {
                ForEach(0..<24) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Picker("Min", selection: $minutes) {
                ForEach(0..<60) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Text("min")
                .font(.body.bold())
                .frame(width: 50, alignment: .leading)
        }
        .padding(.horizontal)
    }

    private var background: some View {
        LinearGradient(
            colors: [Color.green.opacity(0.08), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
