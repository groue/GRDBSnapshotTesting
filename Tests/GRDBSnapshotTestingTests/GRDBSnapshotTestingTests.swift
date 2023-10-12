import GRDB
import XCTest
import SnapshotTesting
import GRDBSnapshotTesting

private struct Player: Codable, MutablePersistableRecord {
    static let team = belongsTo(Team.self)
    var id: Int64?
    var name: String
    var teamId: String?
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

private struct Team: Codable, PersistableRecord {
    static let players = hasMany(Player.self)
    var id: String
    var name: String
    var color: String
}

final class GRDBSnapshotTestingTests: XCTestCase {
    func test_DatabaseReader_dumpContent() throws {
        let dbQueue = try makeRugbyDatabase()
        assertSnapshot(of: dbQueue, as: .dumpContent())
    }
    
    func test_DatabaseReader_dumpContent_custom_format() throws {
        let dbQueue = try makeRugbyDatabase()
        assertSnapshot(of: dbQueue, as: .dumpContent(format: .json()))
    }
    
    func test_DatabaseReader_dumpTables() throws {
        let dbQueue = try makeRugbyDatabase()
        assertSnapshot(of: dbQueue, as: .dumpTables(["player"]))
        assertSnapshot(of: dbQueue, as: .dumpTables(["player", "team"]))
        assertSnapshot(of: dbQueue, as: .dumpTables(["team", "player"]))
    }
    
    func test_DatabaseReader_dumpTables_custom_format() throws {
        let dbQueue = try makeRugbyDatabase()
        assertSnapshot(of: dbQueue, as: .dumpTables(["player", "team"], format: .list(header: true)))
    }
    
    func test_SQL() throws {
        let dbQueue = try makeRugbyDatabase()
        try dbQueue.read { db in
            assertSnapshot(
                of: "SELECT * FROM player ORDER BY id",
                as: .dump(db))
        }
    }
    
    func test_SQL_custom_format() throws {
        let dbQueue = try makeRugbyDatabase()
        try dbQueue.read { db in
            assertSnapshot(
                of: "SELECT * FROM player ORDER BY id",
                as: .dump(db, format: .quote()))
        }
    }
    
    func test_SQL_interpolation() throws {
        let dbQueue = try makeRugbyDatabase()
        try dbQueue.read { db in
            let name = "Antoine Dupond"
            assertSnapshot(
                of: "SELECT * FROM player WHERE name = \(name)",
                as: .dump(db))
        }
    }
    
    func test_SQL_multiple_statements() throws {
        try DatabaseQueue().write { db in
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
    
    func test_FetchRequest() throws {
        let dbQueue = try makeRugbyDatabase()
        try dbQueue.read { db in
            let request: SQLRequest<Player> = """
                SELECT * FROM player ORDER BY id
                """
            assertSnapshot(of: request, as: .dump(db))
        }
    }
    
    func test_FetchRequest_custom_format() throws {
        let dbQueue = try makeRugbyDatabase()
        try dbQueue.read { db in
            let request: SQLRequest<Player> = """
                SELECT * FROM player ORDER BY id
                """
            assertSnapshot(of: request, as: .dump(db, format: .line(nullValue: "<null>")))
        }
    }
    
    func test_QueryInterfaceRequest() throws {
        let dbQueue = try makeRugbyDatabase()
        try dbQueue.read { db in
            let request = Player.all()
            assertSnapshot(of: request, as: .dump(db))
        }
    }
    
    func test_QueryInterfaceRequest_association_to_one() throws {
        let dbQueue = try makeRugbyDatabase()
        try dbQueue.read { db in
            let request = Player.including(required: Player.team)
            assertSnapshot(of: request, as: .dump(db))
        }
    }
    
    func test_QueryInterfaceRequest_association_to_many() throws {
        let dbQueue = try makeRugbyDatabase()
        try dbQueue.read { db in
            let request = Team.including(all: Team.players)
            assertSnapshot(of: request, as: .dump(db))
        }
    }

    func test_QueryInterfaceRequest_association_to_many_custom_format() throws {
        let dbQueue = try makeRugbyDatabase()
        try dbQueue.read { db in
            let request = Team.including(all: Team.players)
            assertSnapshot(of: request, as: .dump(db, format: .json()))
        }
    }

    private func makeRugbyDatabase() throws -> DatabaseQueue {
        let dbQueue = try DatabaseQueue()
        try dbQueue.write { db in
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
            
            try db.create(view: "playerAndTeam", asLiteral: """
                SELECT player.*, team.name AS teamName
                FROM player
                LEFT JOIN team ON team.id = player.teamId
                """)
            
            let england = Team(id: "ENG", name: "England Rugby", color: "white")
            let france = Team(id: "FRA", name: "XV de France", color: "blue")
            
            try england.insert(db)
            try france.insert(db)

            _ = try Player(name: "Antoine Dupond", teamId: france.id).inserted(db)
            _ = try Player(name: "Owen Farrell", teamId: england.id).inserted(db)
            _ = try Player(name: "Tartempion", teamId: nil).inserted(db)
        }
        return dbQueue
    }
}
