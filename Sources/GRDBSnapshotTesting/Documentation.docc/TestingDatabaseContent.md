# Testing Database Content

Test the database schema, the content of database tables, and migrations.

## Overview

Testing the database content provides a few guarantees. For example:

- Test that a fresh installation of your application successfully creates a database in the expected format.
- Test that a specific migration performs the expected modifications on particular database fixtures.
- Test that migrations follow the golden rule of migrations, which is that they are never modified once they have been released on users' devices.

We'll explore how GRDBSnapshotTesting helps addressing those use cases below.

If you are not familiar with migrations and how they help your application evolve its database schema over time, see the [Migrations] guide.

### Testing a fresh install

On the fresh install of an application, the database is frequently created somewhere on disk, and populated with the needed database tables.

It is delicate to write tests that depend on a specific location on disk, because this shared location prevents tests from running independently, or in parallel. To avoid this problem, run tests on a temporary database, such as an in-memory database, as below:       

```swift
import XCTest
import GRDB
import GRDBSnapshotTesting
import SnapshotTesting

final class MyDatabaseTests: XCTestCase {
    var migrator: DatabaseMigrator { 
        // Return the DatabaseMigrator for your database
    }

    func test_migrate_empty_database_to_latest_version() throws {
        // Given an empty and temporary in-memory database,
        let dbQueue = try DatabaseQueue()

        // When it is migrated to the latest version,
        try migrator.migrate(dbQueue)
        
        // Then it contains the expected schema and content.
        assertSnapshot(of: dbQueue, as: .dumpContent())
    }
}
```

### Testing a specific migration

Some migrations create a strong need for a testing. They sometimes perform dangerous operations on user data, with a risk of data loss or corruption.

To tests a specific migration, you can test its effect on a database [fixture](https://en.wikipedia.org/wiki/Test_fixture), such as a resource in your test bundle, as below:

```swift
import XCTest
import GRDB
import GRDBSnapshotTesting
import SnapshotTesting

final class MyDatabaseMigrationsTests: XCTestCase {
    var migrator: DatabaseMigrator { 
        // Return the DatabaseMigrator for your database
    }

    func test_migrate_empty_v1_to_v2() throws {
        // Given a copy of the database_v1_empty.sqlite fixture
        let path = try XCTUnwrap(Bundle.module.path(
            forResource: "database_v1_empty", 
            ofType: "sqlite",
            inDirectory: "Fixtures"))
        let dbQueue = try DatabaseQueue.inMemoryCopy(fromPath: path)

        // When it is migrated to v2,
        try migrator.migrate(dbQueue, upTo: "v2")
        
        // Then it contains the expected content.
        assertSnapshot(of: dbQueue, as: .dumpContent())
    }

    func test_migrate_populated_v1_to_v2() throws {
        // Given a copy of the database_v1_populated.sqlite fixture
        let path = try XCTUnwrap(Bundle.module.path(
            forResource: "database_v1_populated", 
            ofType: "sqlite",
            inDirectory: "Fixtures"))
        let dbQueue = try DatabaseQueue.inMemoryCopy(fromPath: path)

        // When it is migrated to v2,
        try migrator.migrate(dbQueue, upTo: "v2")

        // Then it contains the expected content.
        assertSnapshot(of: dbQueue, as: .dumpContent())
    }
}
```

In the example above, fixtures are stored in a "MyPackage/Tests/MyDatabaseTests/Fixture" resource directory of a test target:

```swift
// Package.swift:
.testTarget(
    name: "MyDatabaseTests",
    dependencies: [
        "MyDatabase",
        .product(name: "GRDB", package: "GRDB.swift"),
        .product(name: "GRDBSnapshotTesting", package: "GRDBSnapshotTesting"),
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
    ],
    exclude: ["__Snapshots__"],
    resources: [.copy("Fixtures")]
)
```

> Tip: You will prefer ``GRDB/DatabaseQueue/temporaryCopy(fromPath:configuration:)`` over ``GRDB/DatabaseQueue/inMemoryCopy(fromPath:configuration:)`` when the tested fixture is too big to fit in memory. 

### Testing the golden rule of migrations

The "golden rule of migrations" is that a migration is never modified once it has been released on users' devices. It is this rule that makes sure that the "version 3" of the database has a clear and unique meaning, and that no user device contains a variation that can break expectations.

There is no way to enforce this rule in code. But you can write tests, as below:

```swift
import XCTest
import GRDB
import GRDBSnapshotTesting
import SnapshotTesting

final class MyDatabaseMigrationsTests: XCTestCase {
    var migrator: DatabaseMigrator { 
        // Return the DatabaseMigrator for your database
    }

    func test_that_migration_v1_is_never_modified() throws {
        let dbQueue = try DatabaseQueue()
        try migrator.migrate(dbQueue, upTo: "v1")
        assertSnapshot(of: dbQueue, as: .dumpContent())
    }
    
    func test_that_migration_v2_is_never_modified() throws {
        let dbQueue = try DatabaseQueue()
        try migrator.migrate(dbQueue, upTo: "v2")
        assertSnapshot(of: dbQueue, as: .dumpContent())
    }

    func test_that_migration_v3_is_never_modified() throws {
        // The test for the currently developed migration is expected to fail.
        // TODO: remove this line when the migration is stabilized.
        XCTExpectFailure("Schema v3 is in development.")
        let dbQueue = try DatabaseQueue()
        try migrator.migrate(dbQueue, upTo: "v3")
        assertSnapshot(of: dbQueue, as: .dumpContent())
    }
}
```

Note how the test for the latest migration is marked with `XCTExpectFailure`. This is because a migration is frequently modified when you are developing an application feature. It is only when the feature is completed, and released, that the migration should be locked.

At the moment of the release, you can look for expected failures in the Xcode test reports, remove the `XCTExpectFailure` line, and record the definitive snapshot. Now all modifications to the migration will be spotted by this test.

## Topics

### Test the database content

- ``SnapshotTesting/Snapshotting/dumpContent(format:)``
- ``SnapshotTesting/Snapshotting/dumpTables(_:format:)``

### Create temporary database copies

- ``GRDB/DatabaseQueue/inMemoryCopy(fromPath:configuration:)``
- ``GRDB/DatabaseQueue/temporaryCopy(fromPath:configuration:)``

[Migrations]: https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/migrations
