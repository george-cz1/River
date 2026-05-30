import Foundation

// MARK: - Data Models

struct PlanningContext {
    let existingTaskCount: Int
    let timeOfDay: String   // "morning" | "afternoon" | "evening"
}

enum TaskCategory: String, Codable {
    case warmup
    case deepWork
    case admin
    case creative
}

struct ProposedTask: Identifiable {
    let id: UUID
    var title: String
    var estimatedMinutes: Int
    var category: TaskCategory
    var rationale: String
}

struct PlanResult {
    let tasks: [ProposedTask]
    let deferredCount: Int
    let acknowledged: String?
}

// MARK: - Service

@Observable
@MainActor
final class AIPlanningService {
    static let shared = AIPlanningService()

    enum PlanningError: LocalizedError {
        case networkError(Error)
        case invalidResponse
        case rateLimited
        case notAuthorized

        var errorDescription: String? {
            switch self {
            case .networkError: return "Check your connection and try again."
            case .invalidResponse: return "Something went wrong on our end. Try again."
            case .rateLimited: return "You've planned a lot today — try again tomorrow."
            case .notAuthorized: return "AI planning is a Pro feature."
            }
        }
    }

    private(set) var isTranscribing = false
    private(set) var isPlanning = false
    private(set) var lastError: PlanningError?

    // Proxy base URL — set to deployed worker URL before release.
    // DEBUG builds use mock data so the UI is testable without a running proxy.
    private let proxyBaseURL = "https://river-proxy.workers.dev"

    private init() {}

    // MARK: - Public API

    func transcribe(audioFileURL: URL) async throws -> String {
        isTranscribing = true
        defer { isTranscribing = false }

        #if DEBUG
        try await Task.sleep(for: .seconds(1.5))
        return "I need to finish the deck for the Tuesday meeting, also reply to Sarah's email about the contract review, oh and I completely forgot to pay the electric bill, and I was thinking I should probably review the Q3 numbers before the call."
        #else
        return try await performTranscription(audioFileURL: audioFileURL)
        #endif
    }

    func plan(brainDump: String, context: PlanningContext) async throws -> PlanResult {
        isPlanning = true
        defer { isPlanning = false }

        #if DEBUG
        try await Task.sleep(for: .seconds(2))
        return mockPlanResult()
        #else
        return try await performPlanning(brainDump: brainDump, context: context)
        #endif
    }

    // MARK: - Network (Release)

    private func performTranscription(audioFileURL: URL) async throws -> String {
        guard let url = URL(string: "\(proxyBaseURL)/transcribe") else {
            throw PlanningError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(try Data(contentsOf: audioFileURL))
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try validateHTTPResponse(response)
            let decoded = try JSONDecoder().decode(TranscriptResponse.self, from: data)
            return decoded.text
        } catch let error as PlanningError {
            throw error
        } catch {
            throw PlanningError.networkError(error)
        }
    }

    private func performPlanning(brainDump: String, context: PlanningContext) async throws -> PlanResult {
        guard let url = URL(string: "\(proxyBaseURL)/plan") else {
            throw PlanningError.invalidResponse
        }

        let requestBody = PlanRequestBody(
            brainDump: brainDump,
            existingTaskCount: context.existingTaskCount,
            timeOfDay: context.timeOfDay
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try validateHTTPResponse(response)
            let decoded = try JSONDecoder().decode(ServerPlanResponse.self, from: data)
            return PlanResult(
                tasks: decoded.tasks.map { task in
                    ProposedTask(
                        id: UUID(),
                        title: task.title,
                        estimatedMinutes: task.estimatedMinutes,
                        category: TaskCategory(rawValue: task.category) ?? .admin,
                        rationale: task.rationale
                    )
                },
                deferredCount: decoded.deferred.count,
                acknowledged: decoded.acknowledged
            )
        } catch let error as PlanningError {
            throw error
        } catch {
            throw PlanningError.networkError(error)
        }
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw PlanningError.invalidResponse }
        switch http.statusCode {
        case 200...299: break
        case 401, 403: throw PlanningError.notAuthorized
        case 429: throw PlanningError.rateLimited
        default: throw PlanningError.invalidResponse
        }
    }

    // MARK: - Debug Mock

    private func mockPlanResult() -> PlanResult {
        PlanResult(
            tasks: [
                ProposedTask(
                    id: UUID(),
                    title: "Pay the electric bill online (5 min)",
                    estimatedMinutes: 10,
                    category: .warmup,
                    rationale: "A quick, concrete win to warm up your focus engine before tackling harder tasks."
                ),
                ProposedTask(
                    id: UUID(),
                    title: "Reply to Sarah's email: confirm you've received the contract and will review by Thursday",
                    estimatedMinutes: 20,
                    category: .admin,
                    rationale: "Clearing communication tasks early prevents them from nagging your working memory all day."
                ),
                ProposedTask(
                    id: UUID(),
                    title: "Open the deck and write the agenda slide and three key points for the Tuesday meeting",
                    estimatedMinutes: 50,
                    category: .deepWork,
                    rationale: "This is your most cognitively demanding task — scheduling it mid-morning hits your peak focus window."
                )
            ],
            deferredCount: 1,
            acknowledged: "Q3 numbers review is deferred — that can happen right before the call when the data is freshest."
        )
    }
}

// MARK: - Decodable helpers (private)

private struct TranscriptResponse: Decodable {
    let text: String
}

private struct PlanRequestBody: Encodable {
    let brainDump: String
    let existingTaskCount: Int
    let timeOfDay: String
}

private struct ServerPlanResponse: Decodable {
    struct TaskResponse: Decodable {
        let title: String
        let estimatedMinutes: Int
        let category: String
        let rationale: String
    }
    let tasks: [TaskResponse]
    let deferred: [String]
    let acknowledged: String?
}
