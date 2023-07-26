import Foundation

struct BestGame: Codable {
    let correct: Int
    let total: Int
    let date: Date
}

extension BestGame: Comparable {
    
    private var accuracy: Double {
        
        total != .zero ? Double(correct) / Double(total) : .zero
    }
    
    static func < (lhs: BestGame, rhs: BestGame) -> Bool {
        return lhs.accuracy < rhs.accuracy
    }
}

