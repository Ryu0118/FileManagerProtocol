import Foundation

/// A protocol that abstracts FileManager operations for testability and flexibility.
public protocol FileManagerProtocol: Sendable {
    /// The path to the current directory.
    var currentDirectoryPath: String { get }

    /// The URL of the temporary directory for the current user.
    var temporaryDirectory: URL { get }

    /// Creates a directory at the specified URL.
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws

    /// Creates a directory with the given attributes at the specified path.
    func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws

    /// Returns the contents of the directory at the specified path.
    func contentsOfDirectory(atPath path: String) throws -> [String]

    /// Returns an array of URLs for the items in the specified directory.
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL]

    /// Performs a deep enumeration of the specified directory.
    func subpathsOfDirectory(atPath path: String) throws -> [String]

    /// Returns an array of paths of all the items in the directory.
    func subpaths(atPath path: String) -> [String]?

    /// Returns a directory enumerator object for the specified path.
    func enumerator(atPath path: String) -> FileManager.DirectoryEnumerator?

    /// Returns a directory enumerator object for the specified URL.
    func enumerator(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions, errorHandler handler: ((URL, Error) -> Bool)?) -> FileManager.DirectoryEnumerator?

    /// Returns an array of URLs for the specified common directory in the requested domains.
    func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL]

    /// Locates and optionally creates the specified common directory in a domain.
    func url(for directory: FileManager.SearchPathDirectory, in domain: FileManager.SearchPathDomainMask, appropriateFor url: URL?, create shouldCreate: Bool) throws -> URL

    /// Changes the current directory to the specified path.
    @discardableResult
    func changeCurrentDirectoryPath(_ path: String) -> Bool

    /// Creates a file with the specified content and attributes at the given location.
    @discardableResult
    func createFile(atPath path: String, contents data: Data?, attributes attr: [FileAttributeKey: Any]?) -> Bool

    /// Returns the contents of the file at the specified path.
    func contents(atPath path: String) -> Data?

    /// Copies the item at the specified path to a new location.
    func copyItem(atPath srcPath: String, toPath dstPath: String) throws

    /// Copies the item at the specified URL to a new location.
    func copyItem(at srcURL: URL, to dstURL: URL) throws

    /// Moves the item at the specified path to a new location.
    func moveItem(atPath srcPath: String, toPath dstPath: String) throws

    /// Moves the item at the specified URL to a new location.
    func moveItem(at srcURL: URL, to dstURL: URL) throws

    /// Creates a hard link between the items at the specified paths.
    func linkItem(atPath srcPath: String, toPath dstPath: String) throws

    /// Creates a hard link between the items at the specified URLs.
    func linkItem(at srcURL: URL, to dstURL: URL) throws

    /// Removes the file or directory at the specified path.
    func removeItem(atPath path: String) throws

    /// Removes the file or directory at the specified URL.
    func removeItem(at URL: URL) throws

    /// Creates a symbolic link at the specified path that points to an item at the given path.
    func createSymbolicLink(atPath path: String, withDestinationPath destPath: String) throws

    /// Creates a symbolic link at the specified URL that points to an item at the given URL.
    func createSymbolicLink(at url: URL, withDestinationURL destURL: URL) throws

    /// Returns the path of the item pointed to by a symbolic link.
    func destinationOfSymbolicLink(atPath path: String) throws -> String

    /// Sets the attributes of the specified file or directory.
    func setAttributes(_ attributes: [FileAttributeKey: Any], ofItemAtPath path: String) throws

    /// Returns the attributes of the item at the specified path.
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]

    /// Returns the attributes of the file system at the specified path.
    func attributesOfFileSystem(forPath path: String) throws -> [FileAttributeKey: Any]

    /// Returns a Boolean value indicating whether a file or directory exists at a specified path.
    func fileExists(atPath path: String) -> Bool

    /// Returns a Boolean value indicating whether a file or directory exists at a specified path.
    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool

    /// Returns a Boolean value indicating whether the file or directory at the specified path is readable.
    func isReadableFile(atPath path: String) -> Bool

    /// Returns a Boolean value indicating whether the file or directory at the specified path is writable.
    func isWritableFile(atPath path: String) -> Bool

    /// Returns a Boolean value indicating whether the file at the specified path is executable.
    func isExecutableFile(atPath path: String) -> Bool

    /// Returns a Boolean value indicating whether the file or directory at the specified path can be deleted.
    func isDeletableFile(atPath path: String) -> Bool

    /// Returns a Boolean value indicating whether the files or directories at the specified paths have the same contents.
    func contentsEqual(atPath path1: String, andPath path2: String) -> Bool

    /// Returns the display name of the file or directory at the specified path.
    func displayName(atPath path: String) -> String

    /// Returns an array of strings representing the user-visible components of a given path.
    func componentsToDisplay(forPath path: String) -> [String]?

    /// Returns a string representation of a file system path.
    func string(withFileSystemRepresentation str: UnsafePointer<CChar>, length len: Int) -> String
}

#if os(macOS)
    /// macOS-specific extensions for FileManagerProtocol.
    public protocol FileManagerProtocolMacOS: FileManagerProtocol {
        /// The home directory for the current user.
        var homeDirectoryForCurrentUser: URL { get }

        /// Returns the home directory for the specified user.
        func homeDirectory(forUser userName: String) -> URL?
    }

    extension FileManager: FileManagerProtocolMacOS {}
#else
    extension FileManager: FileManagerProtocol {}
#endif

public extension FileManagerProtocol {
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool) throws {
        try createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: nil)
    }

    func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool) throws {
        try createDirectory(atPath: path, withIntermediateDirectories: createIntermediates, attributes: nil)
    }

    @discardableResult
    func createFile(atPath path: String, contents data: Data?) -> Bool {
        createFile(atPath: path, contents: data, attributes: nil)
    }

    func enumerator(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?) -> FileManager.DirectoryEnumerator? {
        enumerator(at: url, includingPropertiesForKeys: keys, options: [], errorHandler: nil)
    }

    /// Executes an action within a temporary directory, then cleans up.
    func runInTemporaryDirectory<T>(
        _ action: @Sendable (_ temporaryDirectory: URL) async throws -> T
    ) async throws -> T {
        try await runInTemporaryDirectory(prefix: UUID().uuidString, action)
    }

    /// Executes an action within a temporary directory with a custom prefix, then cleans up.
    func runInTemporaryDirectory<T>(
        prefix: String,
        _ action: @Sendable (_ temporaryDirectory: URL) async throws -> T
    ) async throws -> T {
        let temporaryDirectory = try makeTemporaryDirectory(prefix: prefix)
        do {
            let result = try await action(temporaryDirectory)
            try? removeItem(at: temporaryDirectory)
            return result
        } catch {
            try? removeItem(at: temporaryDirectory)
            throw error
        }
    }

    /// Creates a unique temporary directory with the specified prefix.
    func makeTemporaryDirectory(prefix: String) throws -> URL {
        var systemTemporaryDirectory = temporaryDirectory.path(percentEncoded: false)
        #if os(macOS)
            if systemTemporaryDirectory.hasPrefix("/var/") {
                systemTemporaryDirectory = "/private\(systemTemporaryDirectory)"
            }
        #endif
        let directory = URL(fileURLWithPath: systemTemporaryDirectory)
            .appendingPathComponent("\(prefix)-\(UUID().uuidString)")
        try createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// Creates a unique temporary directory.
    func makeTemporaryDirectory() throws -> URL {
        try makeTemporaryDirectory(prefix: UUID().uuidString)
    }
}
