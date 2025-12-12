@testable import FileManagerProtocol
import Foundation
import Testing

@Suite("FileManagerProtocol Tests")
struct FileManagerProtocolTests {
    let fileManager: FileManagerProtocol = FileManager.default
    let testDirectory: URL

    init() throws {
        testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileManagerProtocolTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
    }

    func cleanup() {
        try? FileManager.default.removeItem(at: testDirectory)
    }

    @Test func currentDirectoryPath() {
        let path = fileManager.currentDirectoryPath
        #expect(!path.isEmpty)
        #expect(fileManager.fileExists(atPath: path))
    }

    @Test func temporaryDirectory() {
        let tempDir = fileManager.temporaryDirectory
        #expect(tempDir.isFileURL)
        #expect(fileManager.fileExists(atPath: tempDir.path(percentEncoded: false)))
    }

    #if os(macOS)
        @Test func homeDirectoryForCurrentUser() {
            let fm = FileManager.default as FileManagerProtocolMacOS
            let homeDir = fm.homeDirectoryForCurrentUser
            #expect(homeDir.isFileURL)
            #expect(fm.fileExists(atPath: homeDir.path(percentEncoded: false)))
        }
    #endif

    @Test func createDirectoryAtURL() throws {
        defer { cleanup() }
        let newDir = testDirectory.appendingPathComponent("newDir")
        try fileManager.createDirectory(at: newDir, withIntermediateDirectories: false, attributes: nil)
        #expect(fileManager.fileExists(atPath: newDir.path(percentEncoded: false)))
    }

    @Test func createDirectoryAtPath() throws {
        defer { cleanup() }
        let newDir = testDirectory.appendingPathComponent("newDirPath").path(percentEncoded: false)
        try fileManager.createDirectory(atPath: newDir, withIntermediateDirectories: false, attributes: nil)
        #expect(fileManager.fileExists(atPath: newDir))
    }

    @Test func createDirectoryWithIntermediates() throws {
        defer { cleanup() }
        let nestedDir = testDirectory.appendingPathComponent("a/b/c")
        try fileManager.createDirectory(at: nestedDir, withIntermediateDirectories: true, attributes: nil)
        #expect(fileManager.fileExists(atPath: nestedDir.path(percentEncoded: false)))
    }

    @Test func contentsOfDirectoryAtPath() throws {
        defer { cleanup() }
        let file1 = testDirectory.appendingPathComponent("file1.txt")
        let file2 = testDirectory.appendingPathComponent("file2.txt")
        fileManager.createFile(atPath: file1.path(percentEncoded: false), contents: Data(), attributes: nil)
        fileManager.createFile(atPath: file2.path(percentEncoded: false), contents: Data(), attributes: nil)

        let contents = try fileManager.contentsOfDirectory(atPath: testDirectory.path(percentEncoded: false))
        #expect(contents.contains("file1.txt"))
        #expect(contents.contains("file2.txt"))
    }

    @Test func contentsOfDirectoryAtURL() throws {
        defer { cleanup() }
        let file1 = testDirectory.appendingPathComponent("fileA.txt")
        let file2 = testDirectory.appendingPathComponent("fileB.txt")
        fileManager.createFile(atPath: file1.path(percentEncoded: false), contents: Data(), attributes: nil)
        fileManager.createFile(atPath: file2.path(percentEncoded: false), contents: Data(), attributes: nil)

        let contents = try fileManager.contentsOfDirectory(
            at: testDirectory,
            includingPropertiesForKeys: nil,
            options: []
        )
        let names = contents.map { $0.lastPathComponent }
        #expect(names.contains("fileA.txt"))
        #expect(names.contains("fileB.txt"))
    }

    @Test func subpathsOfDirectoryAtPath() throws {
        defer { cleanup() }
        let subDir = testDirectory.appendingPathComponent("subdir")
        try fileManager.createDirectory(at: subDir, withIntermediateDirectories: false, attributes: nil)
        let file = subDir.appendingPathComponent("nested.txt")
        fileManager.createFile(atPath: file.path(percentEncoded: false), contents: Data(), attributes: nil)

        let subpaths = try fileManager.subpathsOfDirectory(atPath: testDirectory.path(percentEncoded: false))
        #expect(subpaths.contains("subdir"))
        #expect(subpaths.contains("subdir/nested.txt"))
    }

    @Test func subpathsAtPath() throws {
        defer { cleanup() }
        let subDir = testDirectory.appendingPathComponent("sub")
        try fileManager.createDirectory(at: subDir, withIntermediateDirectories: false, attributes: nil)
        let file = subDir.appendingPathComponent("file.txt")
        fileManager.createFile(atPath: file.path(percentEncoded: false), contents: Data(), attributes: nil)

        let subpaths = fileManager.subpaths(atPath: testDirectory.path(percentEncoded: false))
        #expect(subpaths != nil)
        #expect(subpaths?.contains("sub") == true)
        #expect(subpaths?.contains("sub/file.txt") == true)
    }

    @Test func enumeratorAtPath() throws {
        defer { cleanup() }
        let file = testDirectory.appendingPathComponent("enum.txt")
        fileManager.createFile(atPath: file.path(percentEncoded: false), contents: Data(), attributes: nil)

        let enumerator = fileManager.enumerator(atPath: testDirectory.path(percentEncoded: false))
        #expect(enumerator != nil)

        var found = false
        while let item = enumerator?.nextObject() as? String {
            if item == "enum.txt" {
                found = true
            }
        }
        #expect(found)
    }

    @Test func enumeratorAtURL() throws {
        defer { cleanup() }
        let file = testDirectory.appendingPathComponent("enumURL.txt")
        fileManager.createFile(atPath: file.path(percentEncoded: false), contents: Data(), attributes: nil)

        let enumerator = fileManager.enumerator(
            at: testDirectory,
            includingPropertiesForKeys: nil,
            options: [],
            errorHandler: nil
        )
        #expect(enumerator != nil)

        var found = false
        while let url = enumerator?.nextObject() as? URL {
            if url.lastPathComponent == "enumURL.txt" {
                found = true
            }
        }
        #expect(found)
    }

    @Test func urlsForDirectory() {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        #expect(!urls.isEmpty)
    }

    @Test func urlForDirectory() throws {
        let url = try fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        #expect(url.isFileURL)
    }

    #if os(macOS)
        @Test func homeDirectoryForUser() {
            let fm = FileManager.default as FileManagerProtocolMacOS
            let homeDir = fm.homeDirectory(forUser: NSUserName())
            #expect(homeDir != nil)
            #expect(homeDir?.isFileURL == true)
        }
    #endif

    @Test func changeCurrentDirectoryPath() throws {
        let originalPath = fileManager.currentDirectoryPath
        defer {
            _ = fileManager.changeCurrentDirectoryPath(originalPath)
        }

        let result = fileManager.changeCurrentDirectoryPath(testDirectory.path(percentEncoded: false))
        #expect(result == true)
        let currentPath = URL(fileURLWithPath: fileManager.currentDirectoryPath).resolvingSymlinksInPath().path(percentEncoded: false)
        let expectedPath = testDirectory.resolvingSymlinksInPath().path(percentEncoded: false)
        #expect(currentPath == expectedPath)

        cleanup()
    }

    @Test func createFile() throws {
        defer { cleanup() }
        let file = testDirectory.appendingPathComponent("created.txt")
        let data = "Hello".data(using: .utf8)!

        let result = fileManager.createFile(atPath: file.path(percentEncoded: false), contents: data, attributes: nil)
        #expect(result == true)
        #expect(fileManager.fileExists(atPath: file.path(percentEncoded: false)))
    }

    @Test func contentsAtPath() throws {
        defer { cleanup() }
        let file = testDirectory.appendingPathComponent("contents.txt")
        let data = "Test content".data(using: .utf8)!
        fileManager.createFile(atPath: file.path(percentEncoded: false), contents: data, attributes: nil)

        let readData = fileManager.contents(atPath: file.path(percentEncoded: false))
        #expect(readData == data)
    }

    @Test func copyItemAtPath() throws {
        defer { cleanup() }
        let source = testDirectory.appendingPathComponent("source.txt")
        let dest = testDirectory.appendingPathComponent("dest.txt")
        fileManager.createFile(atPath: source.path(percentEncoded: false), contents: "Copy me".data(using: .utf8), attributes: nil)

        try fileManager.copyItem(atPath: source.path(percentEncoded: false), toPath: dest.path(percentEncoded: false))
        #expect(fileManager.fileExists(atPath: source.path(percentEncoded: false)))
        #expect(fileManager.fileExists(atPath: dest.path(percentEncoded: false)))
    }

    @Test func copyItemAtURL() throws {
        defer { cleanup() }
        let source = testDirectory.appendingPathComponent("srcURL.txt")
        let dest = testDirectory.appendingPathComponent("dstURL.txt")
        fileManager.createFile(atPath: source.path(percentEncoded: false), contents: "Copy URL".data(using: .utf8), attributes: nil)

        try fileManager.copyItem(at: source, to: dest)
        #expect(fileManager.fileExists(atPath: source.path(percentEncoded: false)))
        #expect(fileManager.fileExists(atPath: dest.path(percentEncoded: false)))
    }

    @Test func moveItemAtPath() throws {
        defer { cleanup() }
        let source = testDirectory.appendingPathComponent("moveSource.txt")
        let dest = testDirectory.appendingPathComponent("moveDest.txt")
        fileManager.createFile(atPath: source.path(percentEncoded: false), contents: "Move me".data(using: .utf8), attributes: nil)

        try fileManager.moveItem(atPath: source.path(percentEncoded: false), toPath: dest.path(percentEncoded: false))
        #expect(!fileManager.fileExists(atPath: source.path(percentEncoded: false)))
        #expect(fileManager.fileExists(atPath: dest.path(percentEncoded: false)))
    }

    @Test func moveItemAtURL() throws {
        defer { cleanup() }
        let source = testDirectory.appendingPathComponent("moveSrcURL.txt")
        let dest = testDirectory.appendingPathComponent("moveDstURL.txt")
        fileManager.createFile(atPath: source.path(percentEncoded: false), contents: "Move URL".data(using: .utf8), attributes: nil)

        try fileManager.moveItem(at: source, to: dest)
        #expect(!fileManager.fileExists(atPath: source.path(percentEncoded: false)))
        #expect(fileManager.fileExists(atPath: dest.path(percentEncoded: false)))
    }

    @Test func linkItemAtPath() throws {
        defer { cleanup() }
        let source = testDirectory.appendingPathComponent("linkSource.txt")
        let dest = testDirectory.appendingPathComponent("linkDest.txt")
        fileManager.createFile(atPath: source.path(percentEncoded: false), contents: "Link me".data(using: .utf8), attributes: nil)

        try fileManager.linkItem(atPath: source.path(percentEncoded: false), toPath: dest.path(percentEncoded: false))
        #expect(fileManager.fileExists(atPath: source.path(percentEncoded: false)))
        #expect(fileManager.fileExists(atPath: dest.path(percentEncoded: false)))
    }

    @Test func linkItemAtURL() throws {
        defer { cleanup() }
        let source = testDirectory.appendingPathComponent("linkSrcURL.txt")
        let dest = testDirectory.appendingPathComponent("linkDstURL.txt")
        fileManager.createFile(atPath: source.path(percentEncoded: false), contents: "Link URL".data(using: .utf8), attributes: nil)

        try fileManager.linkItem(at: source, to: dest)
        #expect(fileManager.fileExists(atPath: source.path(percentEncoded: false)))
        #expect(fileManager.fileExists(atPath: dest.path(percentEncoded: false)))
    }

    @Test func removeItemAtPath() throws {
        defer { cleanup() }
        let file = testDirectory.appendingPathComponent("remove.txt")
        fileManager.createFile(atPath: file.path(percentEncoded: false), contents: Data(), attributes: nil)
        #expect(fileManager.fileExists(atPath: file.path(percentEncoded: false)))

        try fileManager.removeItem(atPath: file.path(percentEncoded: false))
        #expect(!fileManager.fileExists(atPath: file.path(percentEncoded: false)))
    }

    @Test func removeItemAtURL() throws {
        defer { cleanup() }
        let file = testDirectory.appendingPathComponent("removeURL.txt")
        fileManager.createFile(atPath: file.path(percentEncoded: false), contents: Data(), attributes: nil)
        #expect(fileManager.fileExists(atPath: file.path(percentEncoded: false)))

        try fileManager.removeItem(at: file)
        #expect(!fileManager.fileExists(atPath: file.path(percentEncoded: false)))
    }

    @Test func createSymbolicLinkAtPath() throws {
        defer { cleanup() }
        let target = testDirectory.appendingPathComponent("target.txt")
        let link = testDirectory.appendingPathComponent("link.txt")
        fileManager.createFile(atPath: target.path(percentEncoded: false), contents: Data(), attributes: nil)

        try fileManager.createSymbolicLink(atPath: link.path(percentEncoded: false), withDestinationPath: target.path(percentEncoded: false))
        #expect(fileManager.fileExists(atPath: link.path(percentEncoded: false)))
    }

    @Test func createSymbolicLinkAtURL() throws {
        defer { cleanup() }
        let target = testDirectory.appendingPathComponent("targetURL.txt")
        let link = testDirectory.appendingPathComponent("linkURL.txt")
        fileManager.createFile(atPath: target.path(percentEncoded: false), contents: Data(), attributes: nil)

        try fileManager.createSymbolicLink(at: link, withDestinationURL: target)
        #expect(fileManager.fileExists(atPath: link.path(percentEncoded: false)))
    }

    @Test func destinationOfSymbolicLink() throws {
        defer { cleanup() }
        let target = testDirectory.appendingPathComponent("symlinkTarget.txt")
        let link = testDirectory.appendingPathComponent("symlinkLink.txt")
        fileManager.createFile(atPath: target.path(percentEncoded: false), contents: Data(), attributes: nil)
        try fileManager.createSymbolicLink(atPath: link.path(percentEncoded: false), withDestinationPath: target.path(percentEncoded: false))

        let destination = try fileManager.destinationOfSymbolicLink(atPath: link.path(percentEncoded: false))
        #expect(destination == target.path(percentEncoded: false))
    }

    @Test func setAttributes() throws {
        defer { cleanup() }
        let file = testDirectory.appendingPathComponent("attrs.txt")
        fileManager.createFile(atPath: file.path(percentEncoded: false), contents: Data(), attributes: nil)

        try fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: file.path(percentEncoded: false))
        let attrs = try fileManager.attributesOfItem(atPath: file.path(percentEncoded: false))
        #expect(attrs[.posixPermissions] as? Int == 0o644)
    }

    @Test func attributesOfItem() throws {
        defer { cleanup() }
        let file = testDirectory.appendingPathComponent("itemAttrs.txt")
        fileManager.createFile(atPath: file.path(percentEncoded: false), contents: "Hello".data(using: .utf8), attributes: nil)

        let attrs = try fileManager.attributesOfItem(atPath: file.path(percentEncoded: false))
        #expect(attrs[.size] != nil)
        #expect(attrs[.type] as? FileAttributeType == .typeRegular)
    }

    @Test func attributesOfFileSystem() throws {
        let attrs = try fileManager.attributesOfFileSystem(forPath: "/")
        #expect(attrs[.systemSize] != nil)
        #expect(attrs[.systemFreeSize] != nil)
    }

    @Test func fileExistsAtPath() throws {
        defer { cleanup() }
        let file = testDirectory.appendingPathComponent("exists.txt")
        #expect(!fileManager.fileExists(atPath: file.path(percentEncoded: false)))

        fileManager.createFile(atPath: file.path(percentEncoded: false), contents: Data(), attributes: nil)
        #expect(fileManager.fileExists(atPath: file.path(percentEncoded: false)))
    }

    @Test func fileExistsAtPathIsDirectory() throws {
        defer { cleanup() }
        var isDirectory: ObjCBool = false

        let file = testDirectory.appendingPathComponent("isDir.txt")
        fileManager.createFile(atPath: file.path(percentEncoded: false), contents: Data(), attributes: nil)
        #expect(fileManager.fileExists(atPath: file.path(percentEncoded: false), isDirectory: &isDirectory))
        #expect(isDirectory.boolValue == false)

        let dir = testDirectory.appendingPathComponent("isDir")
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: false, attributes: nil)
        #expect(fileManager.fileExists(atPath: dir.path(percentEncoded: false), isDirectory: &isDirectory))
        #expect(isDirectory.boolValue == true)
    }

    @Test func isReadableFile() throws {
        defer { cleanup() }
        let file = testDirectory.appendingPathComponent("readable.txt")
        fileManager.createFile(atPath: file.path(percentEncoded: false), contents: Data(), attributes: nil)

        #expect(fileManager.isReadableFile(atPath: file.path(percentEncoded: false)))
    }

    @Test func isWritableFile() throws {
        defer { cleanup() }
        let file = testDirectory.appendingPathComponent("writable.txt")
        fileManager.createFile(atPath: file.path(percentEncoded: false), contents: Data(), attributes: nil)

        #expect(fileManager.isWritableFile(atPath: file.path(percentEncoded: false)))
    }

    @Test func isExecutableFile() throws {
        defer { cleanup() }
        let file = testDirectory.appendingPathComponent("executable.sh")
        fileManager.createFile(atPath: file.path(percentEncoded: false), contents: "#!/bin/bash".data(using: .utf8), attributes: nil)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: file.path(percentEncoded: false))

        #expect(fileManager.isExecutableFile(atPath: file.path(percentEncoded: false)))
    }

    @Test func isDeletableFile() throws {
        defer { cleanup() }
        let file = testDirectory.appendingPathComponent("deletable.txt")
        fileManager.createFile(atPath: file.path(percentEncoded: false), contents: Data(), attributes: nil)

        #expect(fileManager.isDeletableFile(atPath: file.path(percentEncoded: false)))
    }

    @Test func contentsEqual() throws {
        defer { cleanup() }
        let file1 = testDirectory.appendingPathComponent("equal1.txt")
        let file2 = testDirectory.appendingPathComponent("equal2.txt")
        let file3 = testDirectory.appendingPathComponent("different.txt")

        let data = "Same content".data(using: .utf8)!
        fileManager.createFile(atPath: file1.path(percentEncoded: false), contents: data, attributes: nil)
        fileManager.createFile(atPath: file2.path(percentEncoded: false), contents: data, attributes: nil)
        fileManager.createFile(atPath: file3.path(percentEncoded: false), contents: "Different".data(using: .utf8), attributes: nil)

        #expect(fileManager.contentsEqual(atPath: file1.path(percentEncoded: false), andPath: file2.path(percentEncoded: false)))
        #expect(!fileManager.contentsEqual(atPath: file1.path(percentEncoded: false), andPath: file3.path(percentEncoded: false)))
    }

    @Test func displayName() throws {
        defer { cleanup() }
        let file = testDirectory.appendingPathComponent("displayName.txt")
        fileManager.createFile(atPath: file.path(percentEncoded: false), contents: Data(), attributes: nil)

        let name = fileManager.displayName(atPath: file.path(percentEncoded: false))
        #expect(name == "displayName.txt")
    }

    @Test func componentsToDisplay() throws {
        let components = fileManager.componentsToDisplay(forPath: "/Users")
        #expect(components != nil)
        #expect(components?.isEmpty == false)
    }

    @Test func stringWithFileSystemRepresentation() {
        let cString = "/tmp".cString(using: .utf8)!
        let path = fileManager.string(withFileSystemRepresentation: cString, length: cString.count - 1)
        #expect(path == "/tmp")
    }

    @Test func protocolConformance() {
        let fm: FileManagerProtocol = FileManager.default
        #expect(fm.fileExists(atPath: "/"))
    }

    @Test func defaultImplementationCreateDirectoryURL() throws {
        defer { cleanup() }
        let dir = testDirectory.appendingPathComponent("defaultImpl")
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        #expect(fileManager.fileExists(atPath: dir.path(percentEncoded: false)))
    }

    @Test func defaultImplementationCreateDirectoryPath() throws {
        defer { cleanup() }
        let dir = testDirectory.appendingPathComponent("defaultImplPath").path(percentEncoded: false)
        try fileManager.createDirectory(atPath: dir, withIntermediateDirectories: true)
        #expect(fileManager.fileExists(atPath: dir))
    }

    @Test func defaultImplementationCreateFile() throws {
        defer { cleanup() }
        let file = testDirectory.appendingPathComponent("defaultFile.txt")
        let result = fileManager.createFile(atPath: file.path(percentEncoded: false), contents: "Data".data(using: .utf8))
        #expect(result)
        #expect(fileManager.fileExists(atPath: file.path(percentEncoded: false)))
    }

    @Test func defaultImplementationEnumeratorAtURL() throws {
        defer { cleanup() }
        let file = testDirectory.appendingPathComponent("enumDefault.txt")
        fileManager.createFile(atPath: file.path(percentEncoded: false), contents: Data(), attributes: nil)

        let enumerator = fileManager.enumerator(at: testDirectory, includingPropertiesForKeys: nil)
        #expect(enumerator != nil)
    }

    @Test func makeTemporaryDirectory() throws {
        let tempDir = try fileManager.makeTemporaryDirectory()
        #expect(fileManager.fileExists(atPath: tempDir.path(percentEncoded: false)))

        try fileManager.removeItem(at: tempDir)
        #expect(!fileManager.fileExists(atPath: tempDir.path(percentEncoded: false)))
    }

    @Test func makeTemporaryDirectoryWithPrefix() throws {
        let tempDir = try fileManager.makeTemporaryDirectory(prefix: "TestPrefix")
        #expect(fileManager.fileExists(atPath: tempDir.path(percentEncoded: false)))
        #expect(tempDir.lastPathComponent.hasPrefix("TestPrefix-"))

        try fileManager.removeItem(at: tempDir)
    }

    @Test func runInTemporaryDirectory() async throws {
        let (result, capturedPath) = try await fileManager.runInTemporaryDirectory { tempDir -> (Int, URL) in
            #expect(fileManager.fileExists(atPath: tempDir.path(percentEncoded: false)))

            let file = tempDir.appendingPathComponent("test.txt")
            fileManager.createFile(atPath: file.path(percentEncoded: false), contents: "Hello".data(using: .utf8))
            #expect(fileManager.fileExists(atPath: file.path(percentEncoded: false)))

            return (42, tempDir)
        }

        #expect(result == 42)
        #expect(!fileManager.fileExists(atPath: capturedPath.path(percentEncoded: false)))
    }

    @Test func runInTemporaryDirectoryWithPrefix() async throws {
        let capturedPath = try await fileManager.runInTemporaryDirectory(prefix: "CustomPrefix") { tempDir -> URL in
            #expect(tempDir.lastPathComponent.hasPrefix("CustomPrefix-"))
            return tempDir
        }

        #expect(!fileManager.fileExists(atPath: capturedPath.path(percentEncoded: false)))
    }

    @Test func runInTemporaryDirectoryCleanupOnError() async throws {
        struct TestError: Error, Sendable {}

        let tempDir = try fileManager.makeTemporaryDirectory(prefix: "ErrorTest")
        #expect(fileManager.fileExists(atPath: tempDir.path(percentEncoded: false)))

        do {
            try await fileManager.runInTemporaryDirectory { dir in
                #expect(fileManager.fileExists(atPath: dir.path(percentEncoded: false)))
                throw TestError()
            }
            Issue.record("Expected error to be thrown")
        } catch is TestError {
            // Expected
        }

        try fileManager.removeItem(at: tempDir)
    }
}
