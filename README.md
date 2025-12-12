# FileManagerProtocol

A Swift protocol that abstracts `FileManager` operations for improved testability and flexibility.

## Requirements

- Swift 6.0+
- macOS 13.0+ / iOS 16.0+ / tvOS 16.0+ / watchOS 9.0+ / visionOS 1.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/user/FileManagerProtocol.git", from: "0.1.0")
]
```

## Usage

`FileManager` conforms to `FileManagerProtocol` out of the box:

```swift
import FileManagerProtocol

func saveData(_ data: Data, using fileManager: FileManagerProtocol = FileManager.default) throws {
    let url = fileManager.temporaryDirectory.appendingPathComponent("file.txt")
    fileManager.createFile(atPath: url.path, contents: data)
}
```

### Temporary Directory

```swift
// Automatic cleanup after closure
let result = try await fileManager.runInTemporaryDirectory { tempDir in
    let file = tempDir.appendingPathComponent("data.json")
    try data.write(to: file)
    return try processFile(at: file)
}

// Manual management
let tempDir = try fileManager.makeTemporaryDirectory(prefix: "MyApp")
defer { try? fileManager.removeItem(at: tempDir) }
```

## License

MIT License
