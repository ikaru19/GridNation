//
//  HUDView.swift
//  GridNation
//
//  Displays game statistics (money, population, stability, tension)
//

import SwiftUI

struct HUDView: View {
    let city: City
    let globalState: GlobalState
    
    var body: some View {
        VStack(spacing: 8) {
            // Money
            CompactStatLabel(
                icon: "dollarsign.circle.fill",
                value: String(format: "$%.0f", city.money),
                color: .green
            )
            
            // Population
            CompactStatLabel(
                icon: "person.3.fill",
                value: "\(city.population)/\(populationCapacity)",
                color: populationColor
            )
            
            // Stability
            CompactStatLabel(
                icon: "heart.fill",
                value: String(format: "%.0f%%", city.stability),
                color: stabilityColor(city.stability)
            )
            
            // Jobs
            CompactStatLabel(
                icon: "briefcase.fill",
                value: "\(availableJobs)",
                color: employmentColor
            )
            
            // Tension
            CompactStatLabel(
                icon: "exclamationmark.triangle.fill",
                value: String(format: "%.0f%%", globalState.worldTension),
                color: tensionColor(globalState.worldTension)
            )
            
            // Seed (even smaller)
            Text("\(city.seed)")
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(10)
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
    }
    
    private var populationCapacity: Int {
        let residential = city.countTiles(of: .residential)
        return residential * 30
    }
    
    private var availableJobs: Int {
        let commercial = city.countTiles(of: .commercial)
        let industrial = city.countTiles(of: .industrial)
        return (commercial + industrial) * 20
    }
    
    private var populationColor: Color {
        let capacity = populationCapacity
        if capacity == 0 { return .gray }
        let percentage = Double(city.population) / Double(capacity)
        if percentage < 0.7 { return .green }
        if percentage < 0.95 { return .orange }
        return .red
    }
    
    private var employmentColor: Color {
        let jobs = availableJobs
        if jobs == 0 && city.population > 0 { return .red }
        if jobs < city.population { return .orange }
        return .green
    }
    
    private func stabilityColor(_ value: Double) -> Color {
        if value > 70 { return .green }
        if value > 40 { return .orange }
        return .red
    }
    
    private func tensionColor(_ value: Double) -> Color {
        if value < 30 { return .green }
        if value < 60 { return .orange }
        return .red
    }
}

/// Compact stat display for mobile
struct CompactStatLabel: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    HUDView(city: City(), globalState: GlobalState())
        .padding()
        .background(Color.gray)
}

