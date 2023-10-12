# ``GRDBSnapshotTesting``

Swift snapshot testing for GRDB

## Overview

The library makes it possible to test [GRDB](http://github.com/groue/GRDB.swift/graphs/traffic) databases and requests with [SnapshotTesting](https://github.com/pointfreeco/swift-snapshot-testing).

## Snapshot database content

Snapshot the full database content (the schema, and the content of all tables) by providing a [`GRDB.DatabaseReader`](https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/databasereader) instance, such as [`DatabaseQueue`](https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/databasequeue) or [`DatabasePool`](https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/databasepool):

```swift
func test_full_database_content() throws {
    let dbQueue = try makeMyDatabase()
    assertSnapshot(of: dbQueue, as: .dumpContent())
}
```

The `.dumpContent()` snapshotting records the database schema and the content of all tables. For example:

```
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
```

It it also possible to snapshot the content of specific tables:

```swift
func test_full_database_content() throws {
    let dbQueue = try makeMyDatabase()
    assertSnapshot(of: dbQueue, as: .dumpTables(["player", "team"]))
}
```


## Snapshot database requests

Requests are values that conform to [`GRDB.FetchRequest`](https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/fetchrequest), such as [`QueryInterfaceRequest`](https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/queryinterfacerequest) and [`SQLRequest`](https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/fetchrequest):

```swift
func test_specific_request_content() throws {
    let dbQueue = try makeMyDatabase()
    try dbQueue.read { db in
        // QueryInterfaceRequest
        let request = Player.all()
        assertSnapshot(of: request, as: .dump(db))

        // SQLRequest
        let request: SQLRequest<Player> = "SELECT * FROM player ORDER BY id" 
        assertSnapshot(of: request, as: .dump(db))
    }
}
```

Both requests above could record something like:

```
- id: 1
  name: 'Arthur'
  score: 500
- id: 2
  name: 'Barbara'
  score: 1000
```

> Tip: Reliable tests need database requests with a well-defined order.
>
> Such ordering is automatically provided by GRDBSnapshotTesting for query interface requests such as `Player.all()`, so you don't have to think about it. For SQL requests, however, it is recommended to provide an explicit order. For example:
>
> ```swift
> // NOT RECOMMENDED: unordered request
> let request: SQLRequest<Player> = "SELECT * FROM player" 
> assertSnapshot(of: request, as: .dump(db))
>
> // RECOMMENDED: totally ordered request
> let request: SQLRequest<Player> = "SELECT * FROM player ORDER BY id" 
> assertSnapshot(of: request, as: .dump(db))
> ```

## Snapshot raw SQL

Raw SQL is provided as [`SQL`](https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/sql) literals:

```swift
func test_sql() throws {
    let dbQueue = try DatabaseQueue()
    try dbQueue.write { db in
        assertSnapshot(
            of: "SELECT * FROM player ORDER BY id",
            as: .dump(db))
    }
}
```

Take care of snapshotting SQL queries with a well-defined order, in order to guarantee the test stability. 

When you provide multiple SQL statements, join them with a semicolon:

```swift
func test_sql() throws {
    let dbQueue = try DatabaseQueue()
    try dbQueue.write { db in
        assertSnapshot(
            of: """
                CREATE TABLE player(id, name, score);
                INSERT INTO player VALUES (1, 'Arthur', 1000);
                INSERT INTO player VALUES (2, 'Barbara', 500);
                SELECT * FROM player ORDER BY name;
                SELECT MAX(score) AS maxScore FROM player;
                """,
            as: .dump(db))
    }
}
```

The above SQL records:

```
- id: 1
  name: 'Arthur'
  score: 500
- id: 2
  name: 'Barbara'
  score: 1000

- maxScore: 1000
```

## Topics

### Snapshot database content

- ``SnapshotTesting/Snapshotting/dumpContent()``
- ``SnapshotTesting/Snapshotting/dumpTables(_:)``

### Snapshot database requests

- ``SnapshotTesting/Snapshotting/dump(_:)-71xgn``
- ``SnapshotTesting/Snapshotting/dump(_:)-757kq``

### Snapshot raw SQL

- ``SnapshotTesting/Snapshotting/dump(_:)-8dq44``

### Support

- ``SnapshotDumpFormat``
- ``GRDB/DumpFormat/snapshot``
