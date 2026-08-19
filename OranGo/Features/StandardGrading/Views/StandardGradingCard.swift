//
//  StandardGradingCard.swift
//  OranGo
//
//  Created by Johanna Angel on 17/08/26.

import SwiftUI

struct StandardGradingItem: Identifiable {
    let id: Int
    let retailName: String
    let isActive: Bool
    let gradeName: String
    let diameterMin: Double?
    let diameterMax: Double?
    let weightMin: Double?
    let weightMax: Double?
    let orangeColorMin: Double?
    let lastUpdated: String
}

struct StandardGradingCard: View {
    let item: StandardGradingItem
    var onEdit: (StandardGradingItem) -> Void
    var onToggleActive: (Bool) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            if isExpanded {
                expandedContent
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .shadow(color: .black.opacity(0.07), radius: 6, y: 3)
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.green)
                
                Image(systemName: "cart.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("\(item.retailName)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.isActive ? "Aktif" : "Tidak Aktif")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(item.isActive ? .white : .primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(item.isActive ? Color.green : Color.gray.opacity(0.3))
                    .clipShape(Capsule())
                
                Text(item.lastUpdated)
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
    
    // MARK: - Expanded Content
    
    private var expandedContent: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.horizontal, 14)
            
            HStack(alignment: .top, spacing: 0) {
                thresholdColumn(
                    title: "Diameter",
                    value: rangeText(min: item.diameterMin, max: item.diameterMax),
                    unit: "cm"
                )
                
                thresholdColumn(
                    title: "Berat",
                    value: rangeText(min: item.weightMin, max: item.weightMax),
                    unit: "gr"
                )
                
                thresholdColumn(
                    title: "Min. Permukaan Oranye",
                    value: format(item.orangeColorMin),
                    unit: "%"
                )
                
                Spacer()
                
                VStack(spacing: 5) {
                    Text("Aktif")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    
                    Toggle("", isOn: activeBinding)
                        .labelsHidden()
                        .tint(Color.green)
                        .scaleEffect(0.8)
                }
                .frame(width: 70)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            
            HStack {
                Button {
                    onEdit(item)
                    
                } label: {
                    Text("Edit")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 65, height: 28)
                        .background(Color(red: 0.98, green: 0.43, blue: 0.00))
                        .clipShape(Capsule())
                }
                .buttonStyle(.borderless)
                .disabled(item.isActive)
                .opacity(item.isActive ? 0.45 : 1)
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 14)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Toggle
    
    private var activeBinding: Binding<Bool> {
        Binding(
            get: {
                item.isActive
            },
            set: { newValue in
                if newValue != item.isActive {
                    onToggleActive(newValue)
                }
            }
        )
    }

    // MARK: - Threshold Column

    private func thresholdColumn(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 12, weight: .semibold))

                Text(unit)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Formatting

    private func rangeText(min: Double?, max: Double?) -> String {
        guard let min, let max else {
            return "-"
        }

        return "\(format(min)) - \(format(max))"
    }

    private func format(_ value: Double?) -> String {
        guard let value else {
            return "-"
        }

        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }

        return String(format: "%.1f", value)
    }
}

// MARK: - Preview
#Preview("Standard Grading Card") {
    ScrollView {
        VStack(spacing: 12) {
            StandardGradingCard(
                item: StandardGradingItem(
                    id: 1,
                    retailName: "Superindo",
                    isActive: true,
                    gradeName: "Grade A",
                    diameterMin: 6,
                    diameterMax: 9,
                    weightMin: 130,
                    weightMax: 160,
                    orangeColorMin: 90,
                    lastUpdated: "30 detik yang lalu"
                ),
                onEdit: { item in
                    print("Edit \(item.retailName) dengan ID: \(item.id)")
                },
                onToggleActive: {_ in 
                    print("Activate Superindo")
                }
            )

            StandardGradingCard(
                item: StandardGradingItem(
                    id: 2,
                    retailName: "Ranch Market",
                    isActive: false,
                    gradeName: "Grade B",
                    diameterMin: 6,
                    diameterMax: 9,
                    weightMin: 130,
                    weightMax: 160,
                    orangeColorMin: 90,
                    lastUpdated: "1 menit yang lalu"
                ),
                onEdit: { item in
                    print("Edit \(item.retailName) dengan ID: \(item.id)")
                },
                onToggleActive: {_ in 
                    print("Activate Ranch Market")
                }
            )
        }
        .padding(20)
    }
    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
}
