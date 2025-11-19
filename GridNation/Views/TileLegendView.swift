//
//  TileLegendView.swift
//  GridNation
//
//  Shows a legend of all tile types and their colors
//

import SwiftUI

struct TileLegendView: View {
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                    if !isExpanded {
                        Text("?")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .padding(12)
                .background(Color.black.opacity(0.8))
                .cornerRadius(25)
            }
            
            if isExpanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        // Buildable tiles section
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Buildable:")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            ForEach(TileType.buildableTypes, id: \.self) { type in
                                HStack(spacing: 8) {
                                    Rectangle()
                                        .fill(type.color)
                                        .frame(width: 20, height: 20)
                                        .cornerRadius(3)
                                    
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(type.displayName)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                        
                                        // Add capacity/job info
                                        if type == .residential {
                                            Text("30 pop/tile")
                                                .font(.system(size: 9))
                                                .foregroundColor(.white.opacity(0.5))
                                        } else if type == .commercial || type == .industrial {
                                            Text("20 jobs/tile")
                                                .font(.system(size: 9))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                    }
                                }
                            }
                        }
                    
                        Divider()
                            .background(Color.white.opacity(0.3))
                            .padding(.vertical, 4)
                        
                        // Terrain section
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Terrain:")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            ForEach([TileType.water, TileType.mountain], id: \.self) { type in
                                HStack(spacing: 8) {
                                    Rectangle()
                                        .fill(type.color)
                                        .frame(width: 20, height: 20)
                                        .cornerRadius(3)
                                    Text(type.displayName)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                        
                        Text("💡 Jobs + Stability = Growth")
                            .font(.system(size: 9))
                            .foregroundColor(.yellow.opacity(0.8))
                            .padding(.top, 4)
                    }
                    .padding(12)
                }
                .frame(maxHeight: 300)
                .background(Color.black.opacity(0.9))
                .cornerRadius(12)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        TileLegendView()
            .padding()
    }
}

