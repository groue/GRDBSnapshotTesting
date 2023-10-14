import XCTest
import XCTest
import SnapshotTesting
import GRDB
import GRDBSnapshotTesting

final class InMemoryCopyTests: XCTestCase {
    func test_inMemoryCopy() throws {
        let path = try XCTUnwrap(Bundle.module.path(forResource: "playerDatabase", ofType: "sqlite", inDirectory: "Fixtures"))
        let dbQueue = try DatabaseQueue.inMemoryCopy(fromPath: path)
        
        // Test that content was faithfully copied
        assertSnapshot(of: dbQueue, as: .dumpContent())
    }
    
    func test_inMemoryCopy_write() throws {
        let path = try XCTUnwrap(Bundle.module.path(forResource: "playerDatabase", ofType: "sqlite", inDirectory: "Fixtures"))
        let dbQueue = try DatabaseQueue.inMemoryCopy(fromPath: path)
        
        // The in-memory copy is writable (necessary for testing migrations)
        try dbQueue.write { db in
            try db.execute(sql: "INSERT INTO player VALUES (NULL, 'Craig', 200)")
        }
        assertSnapshot(of: dbQueue, as: .dumpContent())
    }
    
    func test_inMemoryCopy_readOnly() throws {
        let path = try XCTUnwrap(Bundle.module.path(forResource: "playerDatabase", ofType: "sqlite", inDirectory: "Fixtures"))
        var config = Configuration()
        config.readonly = true
        let dbQueue = try DatabaseQueue.inMemoryCopy(fromPath: path, configuration: config)
        
        // Test that the copy is read-only
        XCTAssertThrowsError(try dbQueue.write { try $0.execute(sql: "DROP TABLE player") }) { error in
            guard let dbError = error as? DatabaseError else {
                XCTFail("Expected DatabaseError")
                return
            }
            XCTAssertEqual(dbError.message, "attempt to write a readonly database")
        }
        
        // Test that content was faithfully copied
        assertSnapshot(of: dbQueue, as: .dumpContent())
    }
    
    func test_migrations_are_testable() throws {
        // Given a migrator…
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { try $0.create(table: "team") { $0.autoIncrementedPrimaryKey("id") } }
        migrator.registerMigration("v2") { try $0.create(table: "match") { $0.autoIncrementedPrimaryKey("id") } }
        migrator.registerMigration("v3") { try $0.drop(table: "match") }

        // …GRDB users can test the migrator on fixtures
        let path = try XCTUnwrap(Bundle.module.path(forResource: "playerDatabase", ofType: "sqlite", inDirectory: "Fixtures"))
        let dbQueue = try DatabaseQueue.inMemoryCopy(fromPath: path)
        try migrator.migrate(dbQueue, upTo: "v2")
        assertSnapshot(of: dbQueue, as: .dumpContent())
        try migrator.migrate(dbQueue, upTo: "v3")
        assertSnapshot(of: dbQueue, as: .dumpContent())
    }
}
