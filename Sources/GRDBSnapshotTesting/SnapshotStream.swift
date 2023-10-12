final class SnapshotStream: TextOutputStream {
    var output: String
    
    init() {
        output = ""
    }
    
    func write(_ string: String) {
        output.append(string)
    }
}
