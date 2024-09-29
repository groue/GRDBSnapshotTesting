import GRDB
import SQLite3

/// A GRDB dump format suited for snapshot testing, that prints one line
/// per database value, formatting values as SQL literals.
///
/// This format is used by default when you write snapshot tests:
///
/// ```swift
/// let dbQueue: DatabaseQueue
///
/// // Default dump format is `SnapshotDumpFormat`
/// assertSnapshot(of: dbQueue, as: .dumpContent())
/// ```
///
/// You can use other formats as well, but not all of them give good reports
/// when tests fail due to snapshots mismatch.
///
/// ```swift
/// // Custom dump format
/// assertSnapshot(of: dbQueue, as: .dumpContent(format: .json()))
/// ```
///
/// See [`GRDB.DumpFormat`](https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/dumpformat)
/// for more information.
public struct SnapshotDumpFormat {
    var firstRow = true
    
    public init() { }
}

extension SnapshotDumpFormat: DumpFormat {
    public mutating func writeRow(_ db: Database, statement: Statement, to stream: inout DumpStream) throws {
        firstRow = false
        
        let sqliteStatement = statement.sqliteStatement
        var first = true
        for index in 0..<sqlite3_column_count(sqliteStatement) {
            // Don't log GRDB columns
            let column = String(cString: sqlite3_column_name(sqliteStatement, index))
            if column.starts(with: "grdb_") { continue }
            
            if first {
                first = false
                stream.write("- ")
            } else {
                stream.write("  ")
            }
            stream.write(column)
            stream.write(": ")
            try stream.write(formattedValue(db, sqliteStatement: sqliteStatement, index: index))
            stream.write("\n")
        }
    }
    
    public mutating func finalize(_ db: Database, statement: Statement, to stream: inout DumpStream) {
        if firstRow {
            firstRow = false
        } else {
            stream.margin()
        }
    }
    
    private func formattedValue(_ db: Database, sqliteStatement: SQLiteStatement, index: CInt) 
    throws -> String
    {
        let dbValue = DatabaseValue(sqliteStatement: sqliteStatement, index: index)
        let quoteStmt = try db.cachedStatement(sql: "SELECT QUOTE(?)")
        return try String.fetchOne(quoteStmt, arguments: [dbValue])!
    }
}

extension DumpFormat where Self == SnapshotDumpFormat {
    /// A GRDB dump format suited for snapshot testing, that prints one line
    /// per database value, formatting values as SQL literals.
    public static var snapshot: Self { SnapshotDumpFormat() }
}
