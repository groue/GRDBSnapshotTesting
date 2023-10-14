# Testing Database Requests

Test the results of database requests.

## Overview

Requests are values that conform to [`GRDB.FetchRequest`](https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/fetchrequest), such as [`QueryInterfaceRequest`](https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/queryinterfacerequest) and [`SQLRequest`](https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/fetchrequest).

You can test their results:

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

Raw [`SQL`](https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/sql) literals are also supported:

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

## Topics

### Request Testing

- ``SnapshotTesting/Snapshotting/dump(_:format:)-86ixl``
- ``SnapshotTesting/Snapshotting/dump(_:format:)-2yk09``
- ``SnapshotTesting/Snapshotting/dump(_:format:)-wvjs``
