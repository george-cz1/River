import Foundation
import SwiftData

@Model
final class FocusTask {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var sortOrder: Int = 0

    init(title: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }
}
