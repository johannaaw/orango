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

    /// A4 landscape in points, matching the dashboard's wide, column-based layout.
    static let pageSize = CGSize(width: 841.8, height: 595.2)
    static let pageMargin: CGFloat = 28

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

        var mediaBox = CGRect(origin: .zero, size: pageSize)

        guard let consumer = CGDataConsumer(url: url as CFURL),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw ExportError.pdfContextUnavailable
        }

        let contentWidth = pageSize.width - pageMargin * 2
        let contentHeight = pageSize.height - pageMargin * 2

        renderer.render { size, renderInContext in
            // The document is laid out at `documentWidth`; shrink it to the page width
            // and slice the result into page-height bands.
            let scale = contentWidth / size.width
            let scaledHeight = size.height * scale
            let pageCount = max(1, Int(ceil(scaledHeight / contentHeight)))

            for page in 0 ..< pageCount {
                var pageBox = CGRect(origin: .zero, size: pageSize)
                context.beginPage(mediaBox: &pageBox)
                context.saveGState()

                context.clip(to: CGRect(
                    x: pageMargin,
                    y: pageMargin,
                    width: contentWidth,
                    height: contentHeight
                ))

                // PDF space is y-up: line the document's top edge up with the top of
                // the page, then push it down one page-height per sheet.
                context.translateBy(
                    x: pageMargin,
                    y: pageSize.height - pageMargin - scaledHeight + CGFloat(page) * contentHeight
                )
                context.scaleBy(x: scale, y: scale)

                renderInContext(context)

                context.restoreGState()
                context.endPage()
            }
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

    /// Written to the temporary directory: the share sheet copies it wherever the
    /// user chooses, so the app keeps no duplicate of its own.
    private static func fileURL(baseName: String, ext: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(sanitize(baseName))
            .appendingPathExtension(ext)
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
