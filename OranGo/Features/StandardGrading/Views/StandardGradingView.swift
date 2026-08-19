//
//  StandardGradingView.swift
//  OranGo
//
//  Created by Johanna Angel on 17/08/26.
//

import SwiftUI

struct StandardGradingView: View {
    private enum Sheet: Identifiable {
        case add
        case edit(ThresholdRule)

        var id: String {
            switch self {
            case .add:
                return "add"
            case .edit(let rule):
                return "edit-\(rule.id)"
            }
        }
    }

    @State private var viewModel = StandardGradingViewModel()
    @State private var activeSheet: Sheet?
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 0) {
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

            // MARK: - Add Button
            if !viewModel.thresholdRules.isEmpty {
                Button {
                    activeSheet = .add
                } label: {
                    Label("Tambah Standar Grading", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .task {
            await viewModel.loadAll()
        }
        .sheet(item: $activeSheet, onDismiss: {
            Task {
                await viewModel.loadAll()
            }
        }) { sheet in
            switch sheet {
            case .add:
                StandardGradingEditView(rule: nil, viewModel: viewModel)
            case .edit(let rule):
                StandardGradingEditView(rule: rule, viewModel: viewModel)
            }
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
                    onEdit: { _item in
                        editStandard(rule)
                    },
                    onToggleActive: { isActive in
                        setActive(rule, isActive: isActive)
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
                activeSheet = .add
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
            isActive: retail?.aktif ?? false,
            gradeName: "Grade",
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

        activeSheet = .edit(rule)
    }

    // MARK: - Activate
    private func setActive(_ rule: ThresholdRule, isActive: Bool) {
        if !isActive {
            Task {
                await updateActiveState(for: rule.retailGradeId, isActive: false)
            }
            return
        }

        Task {
            do {
                // Validate against the latest server state, not the previous card snapshot.
                try await viewModel.refreshRetailGrades()

                guard let retail = viewModel.retailGrades.first(where: {
                    $0.id == rule.retailGradeId
                }) else {
                    alertMessage = "Data retail tidak ditemukan."
                    showingAlert = true
                    return
                }

                guard !(retail.aktif ?? false) else {
                    return
                }

                let hasOtherActiveStandard = viewModel.retailGrades.contains {
                    ($0.aktif ?? false) && $0.id != retail.id
                }

                guard !hasOtherActiveStandard else {
                    alertMessage = """
                    Hanya satu standar grading yang dapat aktif pada satu waktu.

                    Nonaktifkan standar yang sedang aktif terlebih dahulu sebelum mengaktifkan standar ini.
                    """
                    showingAlert = true
                    return
                }

                await updateActiveState(for: retail.id, isActive: true)
            } catch {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }

    private func updateActiveState(for retailGradeId: Int, isActive: Bool) async {
        do {
            try await viewModel.setRetailGradeActive(id: retailGradeId, isActive: isActive)
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
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

#Preview {
    StandardGradingView()
}
