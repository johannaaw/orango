//
//  StandardGradingView.swift
//  OranGo
//
//  Created by Johanna Angel on 17/08/26.
//

import SwiftUI

struct StandardGradingView: View {
    @State private var viewModel = StandardGradingViewModel()
    @State private var selectedRule: ThresholdRule?
    @State private var showingEditView = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            if viewModel.isLoading && viewModel.thresholdRules.isEmpty {
                ProgressView("Memuat standar grading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Text(error)
                        .multilineTextAlignment(.center)

                    Button("Coba Lagi") {
                        Task {
                            await viewModel.loadAll()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else if viewModel.thresholdRules.isEmpty {
                emptyState
            } else {
                standardsList
            }
        }
        .task {
            await viewModel.loadAll()
        }
        .sheet(isPresented: $showingEditView) {
            StandardGradingEditView(
                rule: selectedRule,
                viewModel: viewModel
            )
        }
        .alert("Tidak Dapat Dilakukan", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - List

    private var standardsList: some View {
        List {
            ForEach(viewModel.thresholdRules) { rule in
                let item = makeItem(from: rule)

                StandardGradingCard(
                    item: item,
                    onEdit: {
                        editStandard(rule)
                    },
                    onActivate: {
                        activateStandard(rule)
                    }
                )
                .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteStandard(rule)
                    } label: {
                        Label("Hapus", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "tray.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Belum ada data threshold")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tambahkan standar grading untuk mulai melihat dashboard penuh.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button {
                selectedRule = nil
                showingEditView = true
            } label: {
                Label("Tambah Standar Grading", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Mapping

    private func makeItem(from rule: ThresholdRule) -> StandardGradingItem {
        let retail = viewModel.retailGrades.first { $0.id == rule.retailGradeId }

        return StandardGradingItem(
            id: rule.id,
            retailName: retail?.retailName ?? "Retail #\(rule.retailGradeId)",
            fruitName: "Jeruk medan",
            isActive: retail?.aktif ?? false,
            gradeName: viewModel.gradeNameById[rule.gradeId] ?? "Grade #\(rule.gradeId)",
            diameterMin: rule.diameterMin,
            diameterMax: rule.diameterMaks,
            weightMin: rule.beratMin,
            weightMax: rule.beratMaks,
            orangeColorMin: rule.warnaOranye,
            lastUpdated: "Data dari database"
        )
    }

    // MARK: - Edit

    private func editStandard(_ rule: ThresholdRule) {
        let item = makeItem(from: rule)

        guard !item.isActive else {
            alertMessage = "Standar grading yang sedang aktif tidak dapat diedit."
            showingAlert = true
            return
        }

        selectedRule = rule
        showingEditView = true
    }

    // MARK: - Activate

    private func activateStandard(_ rule: ThresholdRule) {
        let retail = viewModel.retailGrades.first { $0.id == rule.retailGradeId }

        guard let retail else {
            alertMessage = "Data retail tidak ditemukan."
            showingAlert = true
            return
        }

        guard !retail.aktif else {
            return
        }

        Task {
            do {
                try await viewModel.activateRetailGrade(id: retail.id)
            } catch {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }

    // MARK: - Delete

    private func deleteStandard(_ rule: ThresholdRule) {
        let item = makeItem(from: rule)

        guard !item.isActive else {
            alertMessage = "Standar grading yang sedang aktif tidak dapat dihapus."
            showingAlert = true
            return
        }

        Task {
            do {
                try await viewModel.deleteThresholdRule(id: rule.id)
            } catch {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
}

