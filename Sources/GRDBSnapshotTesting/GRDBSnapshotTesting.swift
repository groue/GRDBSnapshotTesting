import GRDB
import SnapshotTesting

extension Snapshotting {
    /// A snapshot strategy for comparing the database schema and the
    /// content of all database tables.
    ///
    /// For example:
    ///
    /// ```swift
    /// let dbQueue: DatabaseQueue
    /// assertSnapshot(of: dbQueue, as: .dump())
    /// ```
    ///
    /// Records:
    ///
    /// ```
    /// sqlite_master
    /// CREATE TABLE player (
    ///   id INTEGER PRIMARY KEY,
    ///   name TEXT NOT NULL,
    ///   score INTEGER NOT NULL);
    ///
    /// player
    /// - id: 1
    ///   name: 'Arthur'
    ///   score: 500
    /// - id: 2
    ///   name: 'Barbara'
    ///   score: 1000
    /// ```
    ///
    /// > Note: Internal SQLite and GRDB schema objects are not recorded
    /// > (those with a name that starts with "sqlite_" or "grdb_").
    ///
    /// - parameter format: The output format (a `GRDB.DumpFormat`).
    public static func dumpContent(format: some DumpFormat = .snapshot) -> Snapshotting
    where Value: DatabaseReader, Format == String
    {
        SimplySnapshotting.lines.pullback { (reader: Value) in
            let stream = SnapshotStream()
            try! reader.dumpContent(format: format, to: stream)
            return stream.output
        }
    }
    
    /// A snapshot strategy for comparing the content of database tables
    /// and views.
    ///
    /// For example:
    ///
    /// ```swift
    /// let dbQueue: DatabaseQueue
    /// assertSnapshot(of: dbQueue, as: .dumpTables(["player", "team"])
    /// ```
    ///
    /// Records:
    ///
    /// ```
    /// player
    /// - id: 1
    ///   name: 'Arthur'
    ///   score: 500
    /// - id: 2
    ///   name: 'Barbara'
    ///   score: 1000
    ///
    /// team
    /// - id: 1
    ///   color: 'red'
    /// - id: 2
    ///   color: 'blue'
    /// ```
    ///
    /// - parameter tables: The table names.
    /// - parameter format: The output format (a `GRDB.DumpFormat`).
    public static func dumpTables(_ tables: [String], format: some DumpFormat = .snapshot) -> Snapshotting
    where Value: DatabaseReader, Format == String
    {
        SimplySnapshotting.lines.pullback { (reader: Value) in
            let stream = SnapshotStream()
            try! reader.dumpTables(tables, format: format, tableHeader: .always, stableOrder: true, to: stream)
            return stream.output
        }
    }
    
    /// A snapshot strategy for comparing the results of the
    /// database request.
    ///
    /// For example:
    ///
    /// ```swift
    /// let dbQueue: DatabaseQueue
    /// try dbQueue.read { db in
    ///     assertSnapshot(
    ///         of: SQLRequest(literal: "SELECT * FROM player ORDER BY id"),
    ///         as: .dump(db))
    /// }
    /// ```
    ///
    /// Records:
    ///
    /// ```
    /// - id: 1
    ///   name: 'Arthur'
    ///   score: 500
    /// - id: 2
    ///   name: 'Barbara'
    ///   score: 1000
    /// ```
    ///
    /// - parameter db: A `GRDB.Database` database connection.
    /// - parameter format: The output format (a `GRDB.DumpFormat`).
    public static func dump(_ db: Database, format: some DumpFormat = .snapshot) -> Snapshotting
    where Value: FetchRequest, Format == String
    {
        SimplySnapshotting.lines.pullback { (request: Value) in
            let stream = SnapshotStream()
            try! db.dumpRequest(request, format: format, to: stream)
            return stream.output
        }
    }
    
    /// A snapshot strategy for comparing the results of the
    /// database request.
    ///
    /// For example:
    ///
    /// ```swift
    /// let dbQueue: DatabaseQueue
    /// try dbQueue.read { db in
    ///     assertSnapshot(of: Player.all(), as: .dump(db))
    /// }
    /// ```
    ///
    /// Records:
    ///
    /// ```
    /// - id: 1
    ///   name: 'Arthur'
    ///   score: 500
    /// - id: 2
    ///   name: 'Barbara'
    ///   score: 1000
    /// ```
    ///
    /// - parameter db: A `GRDB.Database` database connection.
    /// - parameter format: The output format (a `GRDB.DumpFormat`).
    public static func dump(_ db: Database, format: some DumpFormat = .snapshot) -> Snapshotting
    where Value: FetchRequest & OrderedRequest, Format == String
    {
        SimplySnapshotting.lines.pullback { (request: Value) in
            let stream = SnapshotStream()
            try! db.dumpRequest(request.withStableOrder(), format: format, to: stream)
            return stream.output
        }
    }
    
    /// A snapshot strategy for comparing the results of the SQL statements.
    ///
    /// For example:
    ///
    /// ```swift
    /// let dbQueue: DatabaseQueue
    /// try dbQueue.read { db in
    ///     assertSnapshot(
    ///         of: "SELECT * FROM player ORDER BY id",
    ///         as: .dump(db))
    /// }
    /// ```
    ///
    /// Records:
    ///
    /// ```
    /// - id: 1
    ///   name: 'Arthur'
    ///   score: 500
    /// - id: 2
    ///   name: 'Barbara'
    ///   score: 1000
    /// ```
    ///
    /// - parameter db: A `GRDB.Database` database connection.
    /// - parameter format: The output format (a `GRDB.DumpFormat`).
    public static func dump(_ db: Database, format: some DumpFormat = .snapshot) -> Snapshotting
    where Value == SQL, Format == String
    {
        SimplySnapshotting.lines.pullback { (sql: Value) in
            let stream = SnapshotStream()
            try! db.dumpSQL(sql, format: format, to: stream)
            return stream.output
        }
    }
}
