//
//  ExportService.swift
//  OranGo
//
//  Renders a dashboard or batch view to a file the user can find in the Files app.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Export Format

enum ExportFormat: String, CaseIterable, Identifiable {
    case pdf = "PDF"
    case csv = "CSV"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .csv: return "csv"
        }
    }

    var confirmationTitle: String {
        "Export sebagai \(rawValue)"
    }

    var iconName: String {
        switch self {
        case .pdf: return "doc.richtext"
        case .csv: return "tablecells"
        }
    }
}

// MARK: - Export Payload

struct ExportPayload {
    let fileBaseName: String

    let documentView: AnyView

    let csvRows: [[String]]

    init(fileBaseName: String, csvRows: [[String]], @ViewBuilder documentView: () -> some View) {
        self.fileBaseName = fileBaseName
        self.csvRows = csvRows
        self.documentView = AnyView(documentView())
    }
}

// MARK: - Export Service

@MainActor
enum ExportService {
    enum ExportError: LocalizedError {
        case pdfContextUnavailable

        var errorDescription: String? {
            switch self {
            case .pdfContextUnavailable:
                return "Tidak bisa menyiapkan dokumen PDF."
            }
        }
    }

    static let documentWidth: CGFloat = 900

    static func export(_ payload: ExportPayload, as format: ExportFormat) throws -> URL {
        switch format {
        case .pdf: return try writePDF(payload)
        case .csv: return try writeCSV(payload)
        }
    }

    static func previewImage(of payload: ExportPayload) -> Image? {
        let renderer = ImageRenderer(content: documentBody(payload))
        renderer.scale = 2
        guard let uiImage = renderer.uiImage else { return nil }
        return Image(uiImage: uiImage)
    }

    // MARK: - Writers

    private static func writePDF(_ payload: ExportPayload) throws -> URL {
        let url = fileURL(baseName: payload.fileBaseName, ext: ExportFormat.pdf.fileExtension)

        let renderer = ImageRenderer(content: documentBody(payload))
        renderer.scale = 1

        var mediaBox = CGRect(x: 0, y: 0, width: documentWidth, height: 1273)

        guard let consumer = CGDataConsumer(url: url as CFURL),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw ExportError.pdfContextUnavailable
        }

        renderer.render { size, renderInContext in
            var pageBox = CGRect(origin: .zero, size: size)
            context.beginPage(mediaBox: &pageBox)
            renderInContext(context)
            context.endPage()
        }
        context.closePDF()

        return url
    }

    private static func writeCSV(_ payload: ExportPayload) throws -> URL {
        let url = fileURL(baseName: payload.fileBaseName, ext: ExportFormat.csv.fileExtension)
        let text = payload.csvRows
            .map { row in row.map(escapeCSVField).joined(separator: ",") }
            .joined(separator: "\r\n")

        var data = Data([0xEF, 0xBB, 0xBF])
        data.append(Data(text.utf8))
        try data.write(to: url, options: .atomic)

        return url
    }

    // MARK: - Helpers

    private static func documentBody(_ payload: ExportPayload) -> some View {
        payload.documentView
            .frame(width: documentWidth)
            .background(Color.orangoPageBackground)
    }

    private static func fileURL(baseName: String, ext: String) -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent(sanitize(baseName)).appendingPathExtension(ext)
    }

    private static func sanitize(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        let cleaned = name.components(separatedBy: invalid).joined(separator: "-")
        return cleaned.isEmpty ? "OranGo Export" : cleaned
    }

    private static func escapeCSVField(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else {
            return field
        }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

// MARK: - CSV Row Building

extension ExportPayload {
    static func gradeCSVRows(
        title: String,
        totalWeightKg: Double,
        totalCount: Int,
        gradingStandard: String,
        results: [GradeResult]
    ) -> [[String]] {
        var rows: [[String]] = [
            [title],
            ["Standar Grading", gradingStandard],
            [],
            ["Grade", "Berat (kg)", "Jumlah (buah)", "Persentase (%)"],
        ]

        for result in results {
            rows.append([
                result.gradeType.displayName,
                String(format: "%.1f", result.weightKg),
                "\(result.count)",
                String(format: "%.1f", result.percentage),
            ])
        }

        rows.append([
            "Total",
            String(format: "%.1f", totalWeightKg),
            "\(totalCount)",
            "100.0",
        ])

        return rows
    }
}
