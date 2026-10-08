import AppKit

enum MuralResource {
    static let fileName = "chinox-2016"
    static let fileExtension = "jpg"

    static func image() -> NSImage? {
        guard let url = imageURL() else { return nil }
        return NSImage(contentsOf: url)
    }

    static func imageURL() -> URL? {
        var found: [URL] = []
        var seen = Set<String>()

        func append(_ url: URL?) {
            guard let url else { return }
            let path = url.path
            guard FileManager.default.fileExists(atPath: path), !seen.contains(path) else { return }
            seen.insert(path)
            found.append(url)
        }

        append(Bundle.main.url(forResource: fileName, withExtension: fileExtension))
        append(Bundle.main.url(forResource: fileName, withExtension: fileExtension, subdirectory: "Graffiti"))
        append(Bundle.main.url(forResource: fileName, withExtension: fileExtension, subdirectory: "Resources"))
        append(Bundle.main.url(forResource: fileName, withExtension: fileExtension, subdirectory: "Resources/Graffiti"))

        if let resources = Bundle.main.resourceURL {
            append(resources.appendingPathComponent("\(fileName).\(fileExtension)"))
            append(resources.appendingPathComponent("Graffiti/\(fileName).\(fileExtension)"))
        }

        let bundleNames = ["MetricsWidget_MetricsWidget.bundle", "MetricsWidget.bundle"]
        var searchRoots: [URL] = []
        if let execDir = Bundle.main.executableURL?.deletingLastPathComponent() {
            searchRoots.append(execDir)
            searchRoots.append(execDir.deletingLastPathComponent().appendingPathComponent("Resources"))
        }
        if let resourceURL = Bundle.main.resourceURL {
            searchRoots.append(resourceURL)
        }

        for root in searchRoots {
            append(root.appendingPathComponent("\(fileName).\(fileExtension)"))
            append(root.appendingPathComponent("Graffiti/\(fileName).\(fileExtension)"))
            for name in bundleNames {
                if let bundle = Bundle(url: root.appendingPathComponent(name)) {
                    append(bundle.url(forResource: fileName, withExtension: fileExtension))
                    append(bundle.url(forResource: fileName, withExtension: fileExtension, subdirectory: "Graffiti"))
                }
            }
        }

        return found.first
    }
}
