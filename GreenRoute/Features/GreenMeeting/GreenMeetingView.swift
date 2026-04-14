//
//  GreenMeetingView.swift
//  GreenRoute
//
//  Created by David Rivera on 26/03/2026.
//

import SwiftUI

struct GreenMeetingView: View {
    @State private var hours = 0
    @State private var minutes = 30
    
    var body: some View {
        ZStack {
            background
            VStack(spacing: 24) {
                Text("Meeting Duration")
                    .font(.largeTitle.bold())
                
                picker
                Spacer().frame(maxHeight:5)
                Button {
                    print("⏱ Duration: \(hours)h \(minutes)m")
                } label: {
                    Label("Start Green Meeting", systemImage: "")
                        .frame(maxWidth: .infinity, maxHeight: 40)
                        .font(.title3.bold())
                        
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.horizontal)
            }
        }
        }
    
    private var picker: some View {
        HStack(spacing: 0) {
            Text("hours")
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



#Preview {
    GreenMeetingView()
}
