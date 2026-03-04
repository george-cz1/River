import Foundation
import SwiftData

@Model
final class DeletedTask {
    var id: UUID = UUID()
    var title: String = ""
    var deletedAt: Date = Date()

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.deletedAt = Date()
    }

    init(from task: FocusTask) {
        self.id = UUID()
        self.title = task.title
        self.deletedAt = Date()
    }
}
