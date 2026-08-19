//
//  StandardGradingView.swift
//  OranGo
//
//  Created by Johanna Angel on 17/08/26.
//

import SwiftUI

struct StandardGradingView: View {
    /// Every modal on this screen goes through one `.sheet`, so the dialogs and the editor
    /// cannot fight over the presentation slot.
    private enum Sheet: Identifiable {
        case add
        case edit(RetailGrade)
        case deleteBlocked
        case deleteBlockedByHistory(name: String, batches: [String])
        case deleteConfirm(RetailGrade)
        case editBlocked
        case deactivateBlocked
        case activateBlocked
        case failure(String)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let standard): return "edit-\(standard.id)"
            case .deleteBlocked: return "delete-blocked"
            case .deleteBlockedByHistory(let name, _): return "delete-blocked-history-\(name)"
            case .deleteConfirm(let standard): return "delete-confirm-\(standard.id)"
            case .editBlocked: return "edit-blocked"
            case .deactivateBlocked: return "deactivate-blocked"
            case .activateBlocked: return "activate-blocked"
            case .failure(let message): return "failure-\(message)"
            }
        }
    }

    @Environment(SortingStore.self) private var store

    @State private var viewModel = StandardGradingViewModel()
    @State private var activeSheet: Sheet?
    @State private var toast: OranGoToast.Content?

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.retailGrades.isEmpty {
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

            } else if viewModel.retailGrades.isEmpty {
                emptyState

            } else {
                standardsList
            }

            // MARK: - Add Button
            if !viewModel.retailGrades.isEmpty {
                Button {
                    activeSheet = .add
                } label: {
                    Label("Tambah Standar Grading", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.orangoBrandOrange)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .oranGoToast($toast)
        .task {
            await viewModel.loadAll()
        }
        .sheet(item: $activeSheet, onDismiss: {
            Task {
                await viewModel.loadAll()
            }
        }) { sheet in
            sheetContent(for: sheet)
        }
    }

    // MARK: - Sheets

    @ViewBuilder
    private func sheetContent(for sheet: Sheet) -> some View {
        switch sheet {
        case .add:
            StandardGradingEditView(standard: nil, viewModel: viewModel) { name in
                toast = OranGoToast.Content(
                    title: "Standar Grading Disimpan!",
                    message: "\"\(name)\" berhasil ditambahkan"
                )
            }

        case .edit(let standard):
            StandardGradingEditView(standard: standard, viewModel: viewModel) { name in
                toast = OranGoToast.Content(
                    title: "Standar Grading Disimpan!",
                    message: "\"\(name)\" berhasil diperbarui"
                )
            }

        case .deleteBlocked:
            OranGoDialog(
                emblem: .badge(systemName: "trash.slash.fill", color: Color.orangoDangerRed),
                title: "Tidak Dapat Menghapus Standar Grading",
                message: """
                Standar grading yang sedang aktif tidak dapat dihapus selama proses sorting berlangsung.
                Silahkan tunggu hingga proses selesai untuk melakukan perubahan.
                """
            )

        case .deleteBlockedByHistory(let name, let batches):
            OranGoDialog(
                emblem: .badge(systemName: "trash.slash.fill", color: Color.orangoDangerRed),
                title: "Tidak Dapat Menghapus Standar Grading",
                message: Self.historyReason(name: name, batches: batches)
            )

        case .deleteConfirm(let standard):
            OranGoDialog(
                emblem: .badge(systemName: "exclamationmark", color: Color.orangoDangerRed),
                title: "Hapus Standar Grading Secara Permanen?",
                message: "Semua data akan dihapus secara permanen. Pastikan anda sudah benar-benar yakin.",
                confirmTitle: "Hapus",
                cancelTitle: "Batal",
                onConfirm: { delete(standard) }
            )

        case .editBlocked:
            OranGoDialog(
                emblem: .glyph(systemName: "pencil.slash", color: Color.orangoBrandOrange),
                title: "Tidak Dapat Mengubah Standar Grading",
                message: """
                Standar grading yang sedang aktif tidak dapat diedit selama proses sorting berlangsung.
                Silahkan tunggu hingga proses selesai untuk melakukan perubahan.
                """
            )

        case .deactivateBlocked:
            OranGoDialog(
                emblem: .glyph(systemName: "pencil.slash", color: Color.orangoBrandOrange),
                title: "Tidak Dapat Mengubah Standar Grading",
                message: """
                Standar grading yang sedang aktif tidak dapat dinonaktifkan selama proses sorting berlangsung.
                Silahkan tunggu hingga proses selesai untuk melakukan perubahan.
                """
            )

        case .activateBlocked:
            OranGoDialog(
                emblem: .glyph(systemName: "exclamationmark.triangle.fill", color: Color.orangoBrandOrange),
                title: "Tidak Dapat Mengaktifkan Standar Grading",
                message: "Non-aktifkan standar grading yang sedang aktif terlebih dahulu sebelum mengaktifkan standar ini."
            )

        case .failure(let message):
            OranGoDialog(
                emblem: .glyph(systemName: "exclamationmark.triangle.fill", color: Color.orangoBrandOrange),
                title: "Tidak Dapat Dilakukan",
                message: message
            )
        }
    }

    // MARK: - List

    private var standardsList: some View {
        List {
            ForEach(viewModel.sortedRetailGrades) { standard in
                let item = makeItem(from: standard)

                StandardGradingCard(
                    item: item,
                    onEdit: { _item in
                        editStandard(standard)
                    },
                    onToggleActive: { isActive in
                        setActive(standard, isActive: isActive)
                    }
                )
                .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                // Deliberately not `role: .destructive`, and not full-swipe: both make the List
                // animate the row away on its own the moment the button is tapped. This action
                // only opens a dialog, so the row would vanish while the data still held it —
                // and the next delete would crash on the row-count mismatch. The tint keeps
                // the destructive look without the destructive behaviour.
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        deleteStandard(standard)
                    } label: {
                        Label("Hapus", systemImage: "trash")
                    }
                    .tint(Color.orangoDangerRed)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        // Lets the newly activated standard visibly slide up rather than jump.
        .animation(.snappy(duration: 0.25), value: viewModel.sortedRetailGrades.map(\.id))
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
            .tint(Color.orangoBrandOrange)
            .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Mapping

    private func makeItem(from standard: RetailGrade) -> StandardGradingItem {
        StandardGradingItem(
            id: standard.id,
            retailName: standard.retailName,
            isActive: standard.aktif ?? false,
            gradeName: "Grade",
            diameterMin: standard.diameterMin,
            diameterMax: standard.diameterMaks,
            weightMin: standard.beratMin,
            weightMax: standard.beratMaks,
            orangeColorMin: standard.warnaOranye,
            lastUpdated: "Data dari database"
        )
    }

    /// Names the batches actually holding the standard, so the dialog gives a reason the user
    /// can check rather than a rule they have to take on faith.
    private static func historyReason(name: String, batches: [String]) -> String {
        let shown = batches.prefix(3).joined(separator: ", ")
        let rest = batches.count - min(batches.count, 3)
        let list = rest > 0 ? "\(shown), dan \(rest) lainnya" : shown

        return """
        "\(name)" sudah dipakai oleh \(batches.count) batch: \(list).

        Riwayat sortir batch tersebut hanya menyimpan acuan ke standar ini, bukan salinan ambangnya. Bila standar dihapus, hasil grading batch itu kehilangan dasar ukurnya dan tidak bisa ditafsirkan lagi.

        Nonaktifkan saja bila standar ini tidak ingin dipakai lagi — data lama tetap utuh.
        """
    }

    /// A standard an unfinished batch is still sorting against must not move under it.
    private func isSorting(_ standard: RetailGrade) -> Bool {
        store.retailGradeIDsInUse.contains(standard.id)
    }

    // MARK: - Edit

    private func editStandard(_ standard: RetailGrade) {
        guard !isSorting(standard) else {
            activeSheet = .editBlocked
            return
        }

        activeSheet = .edit(standard)
    }

    // MARK: - Activate
    private func setActive(_ standard: RetailGrade, isActive: Bool) {
        if !isActive {
            // Turning a standard off used to run without any check at all, which is how a
            // standard could be deactivated mid-batch.
            guard !isSorting(standard) else {
                activeSheet = .deactivateBlocked
                return
            }

            Task {
                await updateActiveState(for: standard.id, isActive: false)
            }
            return
        }

        Task {
            do {
                // Validate against the latest server state, not the previous card snapshot.
                try await viewModel.refreshRetailGrades()

                guard let retail = viewModel.retailGrades.first(where: {
                    $0.id == standard.id
                }) else {
                    activeSheet = .failure("Data retail tidak ditemukan.")
                    return
                }

                guard !retail.isActive else { return }

                let hasOtherActiveStandard = viewModel.retailGrades.contains {
                    $0.isActive && $0.id != retail.id
                }

                guard !hasOtherActiveStandard else {
                    activeSheet = .activateBlocked
                    return
                }

                await updateActiveState(for: retail.id, isActive: true)
            } catch {
                activeSheet = .failure(error.localizedDescription)
            }
        }
    }

    private func updateActiveState(for retailGradeId: Int, isActive: Bool) async {
        do {
            try await viewModel.setRetailGradeActive(id: retailGradeId, isActive: isActive)
        } catch {
            activeSheet = .failure(error.localizedDescription)
        }
    }

    // MARK: - Delete

    private func deleteStandard(_ standard: RetailGrade) {
        guard !isSorting(standard) else {
            activeSheet = .deleteBlocked
            return
        }

        // Checked before offering to delete, so the server's rejection never has to be the
        // thing that tells the user.
        let holdingBatches = store.batchCodes(usingRetailGradeID: standard.id)

        guard holdingBatches.isEmpty else {
            activeSheet = .deleteBlockedByHistory(
                name: standard.retailName,
                batches: holdingBatches
            )
            return
        }

        activeSheet = .deleteConfirm(standard)
    }

    private func delete(_ standard: RetailGrade) {
        Task {
            do {
                try await viewModel.deleteRetailGrade(id: standard.id)

                toast = OranGoToast.Content(
                    title: "Standar Grading Dihapus!",
                    message: "\"\(standard.retailName)\" berhasil dihapus"
                )
            } catch {
                await present(.failure(error.localizedDescription))
            }
        }
    }

    /// SwiftUI drops a sheet presented while the previous one is still animating away. The
    /// binding then holds a sheet that is not on screen, and because it is no longer `nil`
    /// nothing else can be presented either — which is what left the delete dialog stuck.
    private func present(_ sheet: Sheet) async {
        activeSheet = nil
        try? await Task.sleep(for: .milliseconds(450))
        activeSheet = sheet
    }
}

#Preview {
    StandardGradingView()
        .environment(SortingStore())
}
