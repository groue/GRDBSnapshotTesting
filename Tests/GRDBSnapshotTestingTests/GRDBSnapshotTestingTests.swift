import GRDB
import GRDBSnapshotTesting
import InlineSnapshotTesting
import XCTest

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
        assertInlineSnapshot(of: dbQueue, as: .dumpContent()) {
            """
            sqlite_master
            CREATE TABLE "player" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "teamId" TEXT REFERENCES "team"("id"), "name" TEXT NOT NULL);
            CREATE INDEX "player_on_teamId" ON "player"("teamId");
            CREATE VIEW "playerAndTeam" AS SELECT player.*, team.name AS teamName
            FROM player
            LEFT JOIN team ON team.id = player.teamId;
            CREATE TABLE "team" ("id" TEXT PRIMARY KEY NOT NULL, "name" TEXT NOT NULL, "color" TEXT NOT NULL);

            player
            - id: 1
              teamId: 'FRA'
              name: 'Antoine Dupond'
            - id: 2
              teamId: 'ENG'
              name: 'Owen Farrell'
            - id: 3
              teamId: NULL
              name: 'Tartempion'

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
    
    func test_DatabaseReader_dumpContent_custom_format() throws {
        let dbQueue = try makeRugbyDatabase()
        assertInlineSnapshot(of: dbQueue, as: .dumpContent(format: .json())) {
            """
            sqlite_master
            CREATE TABLE "player" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "teamId" TEXT REFERENCES "team"("id"), "name" TEXT NOT NULL);
            CREATE INDEX "player_on_teamId" ON "player"("teamId");
            CREATE VIEW "playerAndTeam" AS SELECT player.*, team.name AS teamName
            FROM player
            LEFT JOIN team ON team.id = player.teamId;
            CREATE TABLE "team" ("id" TEXT PRIMARY KEY NOT NULL, "name" TEXT NOT NULL, "color" TEXT NOT NULL);

            player
            [{"id":1,"teamId":"FRA","name":"Antoine Dupond"},
            {"id":2,"teamId":"ENG","name":"Owen Farrell"},
            {"id":3,"teamId":null,"name":"Tartempion"}]

            team
            [{"id":"ENG","name":"England Rugby","color":"white"},
            {"id":"FRA","name":"XV de France","color":"blue"}]

            """
        }
    }
    
    func test_DatabaseReader_dumpTables() throws {
        let dbQueue = try makeRugbyDatabase()
        assertInlineSnapshot(of: dbQueue, as: .dumpTables(["player"])) {
            """
            player
            - id: 1
              teamId: 'FRA'
              name: 'Antoine Dupond'
            - id: 2
              teamId: 'ENG'
              name: 'Owen Farrell'
            - id: 3
              teamId: NULL
              name: 'Tartempion'

            """
        }
        assertInlineSnapshot(of: dbQueue, as: .dumpTables(["player", "team"])) {
            """
            player
            - id: 1
              teamId: 'FRA'
              name: 'Antoine Dupond'
            - id: 2
              teamId: 'ENG'
              name: 'Owen Farrell'
            - id: 3
              teamId: NULL
              name: 'Tartempion'

            team
            - id: 'ENG'
              name: 'England Rugby'
              color: 'white'
            - id: 'FRA'
              name: 'XV de France'
              color: 'blue'

            """
        }
        assertInlineSnapshot(of: dbQueue, as: .dumpTables(["team", "player"])) {
            """
            team
            - id: 'ENG'
              name: 'England Rugby'
              color: 'white'
            - id: 'FRA'
              name: 'XV de France'
              color: 'blue'

            player
            - id: 1
              teamId: 'FRA'
              name: 'Antoine Dupond'
            - id: 2
              teamId: 'ENG'
              name: 'Owen Farrell'
            - id: 3
              teamId: NULL
              name: 'Tartempion'

            """
        }
    }
    
    func test_DatabaseReader_dumpTables_custom_format() throws {
        let dbQueue = try makeRugbyDatabase()
        assertInlineSnapshot(of: dbQueue, as: .dumpTables(["player", "team"], format: .list(header: true))) {
            """
            player
            id|teamId|name
            1|FRA|Antoine Dupond
            2|ENG|Owen Farrell
            3||Tartempion

            team
            id|name|color
            ENG|England Rugby|white
            FRA|XV de France|blue

            """
        }
    }
    
    func test_SQL() throws {
        let dbQueue = try makeRugbyDatabase()
        try dbQueue.read { db in
            assertInlineSnapshot(
                of: "SELECT * FROM player ORDER BY id",
                as: .dump(db)) {
                """
                - id: 1
                  teamId: 'FRA'
                  name: 'Antoine Dupond'
                - id: 2
                  teamId: 'ENG'
                  name: 'Owen Farrell'
                - id: 3
                  teamId: NULL
                  name: 'Tartempion'

                """
            }
        }
    }
    
    func test_SQL_custom_format() throws {
        let dbQueue = try makeRugbyDatabase()
        try dbQueue.read { db in
            assertInlineSnapshot(
                of: "SELECT * FROM player ORDER BY id",
                as: .dump(db, format: .quote())) {
                """
                1,'FRA','Antoine Dupond'
                2,'ENG','Owen Farrell'
                3,NULL,'Tartempion'

                """
            }
        }
    }
    
    func test_SQL_interpolation() throws {
        let dbQueue = try makeRugbyDatabase()
        try dbQueue.read { db in
            let name = "Antoine Dupond"
            assertInlineSnapshot(
                of: "SELECT * FROM player WHERE name = \(name)",
                as: .dump(db)) {
                """
                - id: 1
                  teamId: 'FRA'
                  name: 'Antoine Dupond'

                """
            }
        }
    }
    
    func test_SQL_multiple_statements() throws {
        try DatabaseQueue().write { db in
            assertInlineSnapshot(
                of: """
                    CREATE TABLE player(id, name, score);
                    INSERT INTO player VALUES (1, 'Arthur', 1000);
                    INSERT INTO player VALUES (2, 'Barbara', 500);
                    SELECT * FROM player ORDER BY name;
                    SELECT MAX(score) AS maxScore FROM player;
                    """,
                as: .dump(db)) {
                """
                - id: 1
                  name: 'Arthur'
                  score: 1000
                - id: 2
                  name: 'Barbara'
                  score: 500

                - maxScore: 1000

                """
            }
        }
    }
    
    func test_FetchRequest() throws {
        let dbQueue = try makeRugbyDatabase()
        try dbQueue.read { db in
            let request: SQLRequest<Player> = """
                SELECT * FROM player ORDER BY id
                """
            assertInlineSnapshot(of: request, as: .dump(db)) {
                """
                - id: 1
                  teamId: 'FRA'
                  name: 'Antoine Dupond'
                - id: 2
                  teamId: 'ENG'
                  name: 'Owen Farrell'
                - id: 3
                  teamId: NULL
                  name: 'Tartempion'

                """
            }
        }
    }
    
    func test_FetchRequest_custom_format() throws {
        let dbQueue = try makeRugbyDatabase()
        try dbQueue.read { db in
            let request: SQLRequest<Player> = """
                SELECT * FROM player ORDER BY id
                """
            assertInlineSnapshot(of: request, as: .dump(db, format: .line(nullValue: "<null>"))) {
                """
                    id = 1
                teamId = FRA
                  name = Antoine Dupond

                    id = 2
                teamId = ENG
                  name = Owen Farrell

                    id = 3
                teamId = <null>
                  name = Tartempion

                """
            }
        }
    }
    
    func test_QueryInterfaceRequest() throws {
        let dbQueue = try makeRugbyDatabase()
        try dbQueue.read { db in
            let request = Player.all()
            assertInlineSnapshot(of: request, as: .dump(db)) {
                """
                - id: 1
                  teamId: 'FRA'
                  name: 'Antoine Dupond'
                - id: 2
                  teamId: 'ENG'
                  name: 'Owen Farrell'
                - id: 3
                  teamId: NULL
                  name: 'Tartempion'

                """
            }
        }
    }
    
    func test_QueryInterfaceRequest_association_to_one() throws {
        let dbQueue = try makeRugbyDatabase()
        try dbQueue.read { db in
            let request = Player.including(required: Player.team)
            assertInlineSnapshot(of: request, as: .dump(db)) {
                """
                - id: 1
                  teamId: 'FRA'
                  name: 'Antoine Dupond'
                  id: 'FRA'
                  name: 'XV de France'
                  color: 'blue'
                - id: 2
                  teamId: 'ENG'
                  name: 'Owen Farrell'
                  id: 'ENG'
                  name: 'England Rugby'
                  color: 'white'

                """
            }
        }
    }
    
    func test_QueryInterfaceRequest_association_to_many() throws {
        let dbQueue = try makeRugbyDatabase()
        try dbQueue.read { db in
            let request = Team.including(all: Team.players)
            assertInlineSnapshot(of: request, as: .dump(db)) {
                """
                - id: 'ENG'
                  name: 'England Rugby'
                  color: 'white'
                - id: 'FRA'
                  name: 'XV de France'
                  color: 'blue'

                players
                - id: 1
                  teamId: 'FRA'
                  name: 'Antoine Dupond'
                - id: 2
                  teamId: 'ENG'
                  name: 'Owen Farrell'

                """
            }
        }
    }

    func test_QueryInterfaceRequest_association_to_many_custom_format() throws {
        let dbQueue = try makeRugbyDatabase()
        try dbQueue.read { db in
            let request = Team.including(all: Team.players)
            assertInlineSnapshot(of: request, as: .dump(db, format: .json())) {
                """
                [{"id":"ENG","name":"England Rugby","color":"white"},
                {"id":"FRA","name":"XV de France","color":"blue"}]

                players
                [{"id":1,"teamId":"FRA","name":"Antoine Dupond"},
                {"id":2,"teamId":"ENG","name":"Owen Farrell"}]

                """
            }
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
