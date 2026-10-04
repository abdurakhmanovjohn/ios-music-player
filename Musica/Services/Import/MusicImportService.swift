import AVFoundation
import Foundation
import SwiftData
import UniformTypeIdentifiers

enum MusicImportError: LocalizedError {
    case unsupportedFormat(String)
    case noSupportedFiles

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let fileName):
            return "\(fileName) is not a supported audio file."
        case .noSupportedFiles:
            return "No supported audio files were selected."
        }
    }
}

final class MusicImportService {
    static let shared = MusicImportService()

    static let supportedContentTypes: [UTType] = {
        var types: [UTType] = [.audio, .mp3, .mpeg4Audio, .wav]

        if let aac = UTType(filenameExtension: "aac") {
            types.append(aac)
        }

        if let m4a = UTType(filenameExtension: "m4a") {
            types.append(m4a)
        }

        return types
    }()

    private let supportedExtensions: Set<String> = ["mp3", "m4a", "aac", "wav"]

    private init() {}

    func importFiles(from urls: [URL], modelContext: ModelContext) throws -> [Song] {
        let musicDirectory = try localMusicDirectory()
        var importedSongs: [Song] = []
        var sawUnsupportedFile = false

        for sourceURL in urls {
            guard supportedExtensions.contains(sourceURL.pathExtension.lowercased()) else {
                sawUnsupportedFile = true
                continue
            }

            let hasSecurityAccess = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if hasSecurityAccess {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            let destinationURL = uniqueDestinationURL(for: sourceURL, in: musicDirectory)
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

            let metadata = metadata(for: destinationURL)
            let song = Song(
                title: metadata.title ?? sourceURL.deletingPathExtension().lastPathComponent,
                artist: metadata.artist ?? "Unknown Artist",
                album: metadata.album ?? "Unknown Album",
                duration: metadata.duration,
                artworkData: metadata.artworkData,
                localFileURL: destinationURL
            )

            modelContext.insert(song)
            importedSongs.append(song)
        }

        if importedSongs.isEmpty {
            if sawUnsupportedFile {
                throw MusicImportError.noSupportedFiles
            }
            return []
        }

        try modelContext.save()
        return importedSongs
    }

    private func localMusicDirectory() throws -> URL {
        let documentsDirectory = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let musicDirectory = documentsDirectory.appendingPathComponent("Music", isDirectory: true)

        if !FileManager.default.fileExists(atPath: musicDirectory.path) {
            try FileManager.default.createDirectory(at: musicDirectory, withIntermediateDirectories: true)
        }

        return musicDirectory
    }

    private func uniqueDestinationURL(for sourceURL: URL, in directory: URL) -> URL {
        let baseName = sourceURL.deletingPathExtension().lastPathComponent.sanitizedMusicFileName
        let fileExtension = sourceURL.pathExtension.lowercased()
        let initialName = fileExtension.isEmpty ? baseName : "\(baseName).\(fileExtension)"
        var candidateURL = directory.appendingPathComponent(initialName)
        var copyIndex = 1

        while FileManager.default.fileExists(atPath: candidateURL.path) {
            let numberedName = fileExtension.isEmpty
                ? "\(baseName) \(copyIndex)"
                : "\(baseName) \(copyIndex).\(fileExtension)"
            candidateURL = directory.appendingPathComponent(numberedName)
            copyIndex += 1
        }

        return candidateURL
    }

    private func metadata(for url: URL) -> ImportedAudioMetadata {
        let asset = AVURLAsset(url: url)
        let durationSeconds = CMTimeGetSeconds(asset.duration)
        var metadata = ImportedAudioMetadata(
            duration: durationSeconds.isFinite && durationSeconds > 0 ? durationSeconds : 0
        )

        for item in asset.commonMetadata {
            switch item.commonKey?.rawValue {
            case "title":
                metadata.title = item.stringValue?.nonEmptyMusicText
            case "artist":
                metadata.artist = item.stringValue?.nonEmptyMusicText
            case "albumName":
                metadata.album = item.stringValue?.nonEmptyMusicText
            case "artwork":
                metadata.artworkData = item.dataValue
            default:
                continue
            }
        }

        return metadata
    }
}

private struct ImportedAudioMetadata {
    var title: String?
    var artist: String?
    var album: String?
    var duration: TimeInterval = 0
    var artworkData: Data?
}

private extension String {
    var sanitizedMusicFileName: String {
        let illegalCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let cleaned = components(separatedBy: illegalCharacters).joined(separator: "-")
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Imported Song" : trimmed
    }

    var nonEmptyMusicText: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
