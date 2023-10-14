import GRDB

/// A GRDB dump format suited for snapshot testing.
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
    /// A GRDB dump format suited for snapshot testing.
    public static var snapshot: Self { SnapshotDumpFormat() }
}
