import GRDB
import GRDBSnapshotTesting
import InlineSnapshotTesting
import XCTest

// Test that users can use fixture in order to test their migrations,
// as documented.
final class MigrationsTests: XCTestCase {
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("v1") { db in
            try db.create(table: "team") { t in
                t.primaryKey("id", .text)
                t.column("name", .text).notNull()
                t.column("color", .text).notNull()
            }
            
            try db.create(table: "player") { t in
                t.autoIncrementedPrimaryKey("id")
                t.belongsTo("team")
                t.column("name", .text).notNull()
            }
        }
        
        migrator.registerMigration("v2") { db in
            try db.alter(table: "player") { t in
                t.add(column: "score", .integer).notNull().defaults(to: 0)
            }
        }
        
        return migrator
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
        assertInlineSnapshot(of: dbQueue, as: .dumpContent()) {
            """
            sqlite_master
            CREATE TABLE "player" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "teamId" TEXT REFERENCES "team"("id"), "name" TEXT NOT NULL, "score" INTEGER NOT NULL DEFAULT 0);
            CREATE INDEX "player_on_teamId" ON "player"("teamId");
            CREATE TABLE "team" ("id" TEXT PRIMARY KEY NOT NULL, "name" TEXT NOT NULL, "color" TEXT NOT NULL);

            player

            team

            """
        }
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
        assertInlineSnapshot(of: dbQueue, as: .dumpContent()) {
            """
            sqlite_master
            CREATE TABLE "player" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "teamId" TEXT REFERENCES "team"("id"), "name" TEXT NOT NULL, "score" INTEGER NOT NULL DEFAULT 0);
            CREATE INDEX "player_on_teamId" ON "player"("teamId");
            CREATE TABLE "team" ("id" TEXT PRIMARY KEY NOT NULL, "name" TEXT NOT NULL, "color" TEXT NOT NULL);

            player
            - id: 1
              teamId: 'FRA'
              name: 'Antoine Dupond'
              score: 0
            - id: 2
              teamId: 'ENG'
              name: 'Owen Farrell'
              score: 0
            - id: 3
              teamId: NULL
              name: 'Tartempion'
              score: 0

            team
            - id: 'ENG'
              name: 'England Rugby'
              color: 'white'
            - id: 'FRA'
              name: 'XV de France'
              color: 'blue'

            """
        }
    }
    
    func test_that_migration_v1_is_never_modified() throws {
        let dbQueue = try DatabaseQueue()
        try migrator.migrate(dbQueue, upTo: "v1")
        assertInlineSnapshot(of: dbQueue, as: .dumpContent()) {
            """
            sqlite_master
            CREATE TABLE "player" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "teamId" TEXT REFERENCES "team"("id"), "name" TEXT NOT NULL);
            CREATE INDEX "player_on_teamId" ON "player"("teamId");
            CREATE TABLE "team" ("id" TEXT PRIMARY KEY NOT NULL, "name" TEXT NOT NULL, "color" TEXT NOT NULL);

            player

            team

            """
        }
    }
    
    func test_that_migration_v2_is_never_modified() throws {
        let dbQueue = try DatabaseQueue()
        try migrator.migrate(dbQueue, upTo: "v2")
        assertInlineSnapshot(of: dbQueue, as: .dumpContent()) {
            """
            sqlite_master
            CREATE TABLE "player" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "teamId" TEXT REFERENCES "team"("id"), "name" TEXT NOT NULL, "score" INTEGER NOT NULL DEFAULT 0);
            CREATE INDEX "player_on_teamId" ON "player"("teamId");
            CREATE TABLE "team" ("id" TEXT PRIMARY KEY NOT NULL, "name" TEXT NOT NULL, "color" TEXT NOT NULL);

            player

            team

            """
        }
    }
}
