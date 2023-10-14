import Foundation
import GRDB

extension DatabaseQueue {
    /// Returns an in-memory copy of the database at `path`.
    ///
    /// For example:
    ///
    /// ```swift
    /// let path = "/path/to/database.sqlite"
    /// let dbQueue = try DatabaseQueue.inMemoryCopy(fromPath: path)
    /// ```
    public static func inMemoryCopy(fromPath path: String, configuration: Configuration = Configuration()) throws -> DatabaseQueue {
        var sourceConfig = configuration
        sourceConfig.readonly = true
        let source = try DatabaseQueue(path: path, configuration: sourceConfig)
        
        var copyConfig = configuration
        copyConfig.readonly = false
        let result = try DatabaseQueue(configuration: copyConfig)
        
        try source.backup(to: result)
        
        if configuration.readonly {
            // SQLITE_OPEN_READONLY has no effect on in-memory databases,
            // so let's use a pragma instead.
            try result.inDatabase { db in
                try db.execute(sql: "PRAGMA query_only=1")
            }
        }
        
        return result
    }
}
