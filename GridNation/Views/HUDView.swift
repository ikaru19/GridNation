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
    
    @State private var showDetailedStats = false
    
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
        .onTapGesture {
            showDetailedStats = true
        }
        .sheet(isPresented: $showDetailedStats) {
            DetailedStatsView(city: city, globalState: globalState)
        }
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

/// Detailed statistics popup
struct DetailedStatsView: View {
    let city: City
    let globalState: GlobalState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Economy Section
                    StatSection(title: "Economy", icon: "dollarsign.circle.fill", color: .green) {
                        StatRow(label: "Treasury", value: String(format: "$%.0f", city.money))
                        StatRow(label: "Income/Tick", value: incomePerTick)
                    }
                    
                    // Population Section
                    StatSection(title: "Population", icon: "person.3.fill", color: .blue) {
                        StatRow(label: "Citizens", value: "\(city.population)")
                        StatRow(label: "Capacity", value: "\(populationCapacity)")
                        StatRow(label: "Utilization", value: String(format: "%.1f%%", populationUtilization))
                        StatRow(label: "Growth Rate", value: growthRate)
                    }
                    
                    // Employment Section
                    StatSection(title: "Employment", icon: "briefcase.fill", color: .orange) {
                        StatRow(label: "Available Jobs", value: "\(availableJobs)")
                        StatRow(label: "Employed", value: "\(min(city.population, availableJobs))")
                        StatRow(label: "Unemployed", value: "\(max(0, city.population - availableJobs))")
                        StatRow(label: "Unemployment", value: String(format: "%.1f%%", unemploymentRate))
                    }
                    
                    // City Infrastructure
                    StatSection(title: "Infrastructure", icon: "building.2.fill", color: .purple) {
                        StatRow(label: "Residential", value: "\(city.countTiles(of: .residential))")
                        StatRow(label: "Commercial", value: "\(city.countTiles(of: .commercial))")
                        StatRow(label: "Industrial", value: "\(city.countTiles(of: .industrial))")
                        StatRow(label: "Parks", value: "\(city.countTiles(of: .park))")
                        StatRow(label: "Military", value: "\(city.countTiles(of: .military))")
                        StatRow(label: "Total Built", value: "\(totalBuiltTiles)")
                    }
                    
                    // Territory & Borders
                    StatSection(title: "Territory", icon: "map.fill", color: .cyan) {
                        StatRow(label: "Territory Size", value: "\(city.territoryBorder.count) tiles")
                        StatRow(label: "Border Perimeter", value: "\(city.calculateBorderPerimeter()) tiles")
                        StatRow(label: "Border Security", value: borderSecurityStatus)
                    }
                    
                    // Happiness & Stability
                    StatSection(title: "Happiness", icon: "heart.fill", color: .red) {
                        StatRow(label: "Stability", value: String(format: "%.1f%%", city.stability))
                        StatRow(label: "Status", value: stabilityStatus)
                    }
                    
                    // World Relations
                    StatSection(title: "World Relations", icon: "globe", color: .cyan) {
                        StatRow(label: "World Tension", value: String(format: "%.1f%%", globalState.worldTension))
                        StatRow(label: "Status", value: tensionStatus)
                    }
                    
                    // Map Info
                    StatSection(title: "Map", icon: "map.fill", color: .brown) {
                        StatRow(label: "Size", value: "\(city.gridWidth)×\(city.gridHeight)")
                        StatRow(label: "Total Tiles", value: "\(city.gridWidth * city.gridHeight)")
                        StatRow(label: "Seed", value: "\(city.seed)")
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("City Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var populationCapacity: Int {
        city.countTiles(of: .residential) * 30
    }
    
    private var availableJobs: Int {
        (city.countTiles(of: .commercial) + city.countTiles(of: .industrial)) * 20
    }
    
    private var populationUtilization: Double {
        guard populationCapacity > 0 else { return 0 }
        return Double(city.population) / Double(populationCapacity) * 100
    }
    
    private var unemploymentRate: Double {
        guard city.population > 0 else { return 0 }
        let unemployed = max(0, city.population - availableJobs)
        return Double(unemployed) / Double(city.population) * 100
    }
    
    private var incomePerTick: String {
        let commercial = city.countTiles(of: .commercial)
        let industrial = city.countTiles(of: .industrial)
        let income = commercial * 10 + industrial * 5
        return "+$\(income)"
    }
    
    private var growthRate: String {
        let residential = city.countTiles(of: .residential)
        if residential == 0 { return "No housing" }
        if city.population >= populationCapacity { return "At capacity" }
        if unemploymentRate > 50 { return "Slow (high unemployment)" }
        if city.stability < 40 { return "Slow (low stability)" }
        return "Normal"
    }
    
    private var totalBuiltTiles: Int {
        city.countTiles(of: .residential) +
        city.countTiles(of: .commercial) +
        city.countTiles(of: .industrial) +
        city.countTiles(of: .park) +
        city.countTiles(of: .military)
    }
    
    private var stabilityStatus: String {
        if city.stability > 70 { return "😊 Happy" }
        if city.stability > 40 { return "😐 Neutral" }
        return "😢 Unhappy"
    }
    
    private var tensionStatus: String {
        if globalState.worldTension < 30 { return "🕊️ Peaceful" }
        if globalState.worldTension < 60 { return "⚠️ Tense" }
        return "⚔️ Hostile"
    }
    
    private var borderSecurityStatus: String {
        let military = city.countTiles(of: .military)
        let borderPerimeter = city.calculateBorderPerimeter()
        
        guard borderPerimeter > 0 else { return "No borders yet" }
        
        let securedTiles = military * 10
        let securityPercent = (Double(securedTiles) / Double(borderPerimeter)) * 100.0
        
        if securityPercent >= 100 {
            return "🛡️ Secured (\(Int(securityPercent))%)"
        } else if securityPercent >= 70 {
            return "⚠️ Moderate (\(Int(securityPercent))%)"
        } else {
            return "❌ Vulnerable (\(Int(securityPercent))%)"
        }
    }
}

/// Section container for stats
struct StatSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 8) {
                content
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

/// Individual stat row
struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

