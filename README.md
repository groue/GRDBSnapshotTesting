# GRDBSnapshotTesting

**The snapshot testing library for GRDB**

**Requirements**: iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+ &bull; Swift 5.7+ / Xcode 14+

📖 **[Documentation]**

---

This package makes it possible to test [GRDB] databases with [SnapshotTesting].

## Usage

```swift
import GRDB
import GRDBSnapshotTesting
import InlineSnapshotTesting
import XCTest

class MyDatabaseTests: XCTestCase {
    func test_full_database_content() throws {
        let dbQueue = try makeMyDatabase()
        assertInlineSnapshot(of: dbQueue, as: .dumpContent()) {
            """
            sqlite_master
            CREATE TABLE player (
              id INTEGER PRIMARY KEY,
              name TEXT NOT NULL,
              score INTEGER NOT NULL);

            player
            - id: 1
              name: 'Arthur'
              score: 500
            - id: 2
              name: 'Barbara'
              score: 1000
            """
        }
    }
    
    func test_tables() throws {
        let dbQueue = try makeMyDatabase()
        assertSnapshot(of: dbQueue, as: .dumpTables(["player", "team"]))
    }
    
    func test_request() throws {
        let dbQueue = try makeMyDatabase()
        try dbQueue.read { db in
            assertSnapshot(of: Player.all(), as: .dump(db))
        }
    }
    
    func test_sql() throws {
        let dbQueue = try makeMyDatabase()
        try dbQueue.read { db in
            assertSnapshot(of: "SELECT * FROM player ORDER BY id", as: .dump(db))
        }
    }
}
```

For more information, see the [Documentation]. 

[GRDB]: http://github.com/groue/GRDB.swift
[SnapshotTesting]: https://github.com/pointfreeco/swift-snapshot-testing
[Documentation]: https://swiftpackageindex.com/groue/GRDBSnapshotTesting/documentation
