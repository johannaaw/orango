//import SwiftUI
//
//struct StandardGradingPreview: View {
//    @State private var items: [StandardGradingItem] = [
//        StandardGradingItem(
//            id: 1,
//            retailName: "Superindo",
//            isActive: true,
//            gradeName: "Grade A",
//            diameterMin: 6.0,
//            diameterMax: 9.0,
//            weightMin: 130.0,
//            weightMax: 160.0,
//            orangeColorMin: 90.0,
//            lastUpdated: "30 detik yang lalu"
//        ),
//        StandardGradingItem(
//            id: 2,
//            retailName: "Ranch Market",
//            isActive: false,
//            gradeName: "Grade B",
//            diameterMin: 6.0,
//            diameterMax: 9.0,
//            weightMin: 130.0,
//            weightMax: 160.0,
//            orangeColorMin: 90.0,
//            lastUpdated: "1 menit yang lalu"
//        ),
//        StandardGradingItem(
//            id: 3,
//            retailName: "AEON",
//            isActive: false,
//            gradeName: "Grade C",
//            diameterMin: 5.0,
//            diameterMax: 7.0,
//            weightMin: 100.0,
//            weightMax: 129.0,
//            orangeColorMin: 70.0,
//            lastUpdated: "15 menit yang lalu"
//        )
//    ]
//
//    var body: some View {
//        HStack(spacing: 0) {
//            sidebar
//
//            ZStack(alignment: .top) {
//                Color(red: 0.96, green: 0.96, blue: 0.96)
//                    .ignoresSafeArea()
//
//                VStack(alignment: .leading, spacing: 0) {
//                    header
//
//                    ScrollView {
//                        LazyVStack(spacing: 10) {
//                            ForEach(items) { item in
//                                StandardGradingCard(
//                                    item: item,
//                                    onEdit: {
//                                        print("Edit \(item.retailName)")
//                                    },
//                                    onActivate: {
//                                        print("Activate \(item.retailName)")
//                                    }
//                                )
//                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                                    Button(role: .destructive) {
//                                        deleteItem(item)
//                                    } label: {
//                                        Label("Hapus", systemImage: "trash")
//                                    }
//                                }
//                            }
//                        }
//                        .padding(.horizontal, 20)
//                        .padding(.top, 10)
//                        .padding(.bottom, 10)
//                    }
//
//                    Button {
//                        print("Tambah Standar Grading")
//                    } label: {
//                        Text("Tambah Standar Grading")
//                            .font(.system(size: 12, weight: .semibold))
//                            .foregroundStyle(.white)
//                            .frame(maxWidth: .infinity)
//                            .frame(height: 34)
//                            .background(Color(red: 0.98, green: 0.43, blue: 0.00))
//                            .clipShape(Capsule())
//                    }
//                    .buttonStyle(.plain)
//                    .padding(.horizontal, 20)
//                    .padding(.bottom, 20)
//                }
//
////                toast
////                    .padding(.top, 12)
////                    .padding(.trailing, 20)
////                    .frame(maxWidth: .infinity, alignment: .trailing)
//            }
//        }
//        .background(Color(red: 0.96, green: 0.96, blue: 0.96))
//    }
//
//    // MARK: - Sidebar
//
//    private var sidebar: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            HStack {
//                Text("OranGo")
//                    .font(.system(size: 13, weight: .medium))
//
//                Spacer()
//
//                Image(systemName: "rectangle.split.3x1")
//                    .font(.system(size: 14))
//            }
//            .padding(.horizontal, 16)
//            .padding(.top, 12)
//
//            Spacer()
//                .frame(height: 28)
//
//            sidebarItem(
//                title: "Dashboard",
//                icon: "chart.bar.fill",
//                selected: false
//            )
//
//            sidebarItem(
//                title: "Standar Grading",
//                icon: "slider.vertical.3",
//                selected: true
//            )
//
//            Spacer()
//        }
//        .frame(width: 220)
//        .frame(maxHeight: .infinity)
//        .background(Color.white)
//        .clipShape(RoundedRectangle(cornerRadius: 12))
//        .padding(.leading, 7)
//        .padding(.vertical, 7)
//    }
//
//    private func sidebarItem(title: String, icon: String, selected: Bool) -> some View {
//        HStack(spacing: 9) {
//            Image(systemName: icon)
//                .font(.system(size: 12))
//
//            Text(title)
//                .font(.system(size: 11, weight: selected ? .medium : .regular))
//
//            Spacer()
//        }
//        .foregroundStyle(selected ? Color.blue : Color.primary)
//        .padding(.horizontal, 12)
//        .frame(height: 30)
//        .background(selected ? Color.gray.opacity(0.12) : Color.clear)
//        .clipShape(Capsule())
//        .padding(.horizontal, 8)
//    }
//
//    // MARK: - Header
//
//    private var header: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text("Standar Grading")
//                .font(.system(size: 26, weight: .bold))
//
//            Text("Kelola standar grading untuk setiap retail, lihat standar yang digunakan sesuai kebutuhan.")
//                .font(.system(size: 11))
//                .foregroundStyle(.secondary)
//        }
//        .padding(.top, 20)
//        .padding(.horizontal, 20)
//    }
//
//    // MARK: - Toast
//
////    private var toast: some View {
////        HStack(spacing: 10) {
////            Image(systemName: "checkmark.circle.fill")
////                .foregroundStyle(.green)
////                .font(.system(size: 17))
////
////            VStack(alignment: .leading, spacing: 2) {
////                Text("Standar Grading Disimpan!")
////                    .font(.system(size: 10, weight: .semibold))
////
////                Text("“AEON - Jeruk medan” berhasil disimpan.")
////                    .font(.system(size: 9))
////
////                Text("Standar belum diaktifkan")
////                    .font(.system(size: 9))
////            }
////
////            Spacer()
////
////            Button {
////                print("Close toast")
////            } label: {
////                Image(systemName: "xmark")
////                    .font(.system(size: 9, weight: .semibold))
////                    .foregroundStyle(.secondary)
////            }
////            .buttonStyle(.plain)
////        }
////        .padding(.horizontal, 12)
////        .padding(.vertical, 9)
////        .frame(width: 250)
////        .background(.white)
////        .overlay(
////            RoundedRectangle(cornerRadius: 12)
////                .stroke(Color.green.opacity(0.25), lineWidth: 1)
////        )
////        .clipShape(RoundedRectangle(cornerRadius: 12))
////        .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
////    }
//
//    // MARK: - Delete
//
//    private func deleteItem(_ item: StandardGradingItem) {
//        guard !item.isActive else {
//            print("Cannot delete active standard")
//            return
//        }
//
//        withAnimation {
//            items.removeAll { $0.id == item.id }
//        }
//    }
//}
//
//#Preview{
//    StandardGradingPreview()
//        .previewInterfaceOrientation(.landscapeLeft)
//}
