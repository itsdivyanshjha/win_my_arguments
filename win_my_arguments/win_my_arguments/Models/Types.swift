import Foundation

struct BiasMetrics {
    var politicalBias: Float
    var emotionalBias: Float
    var sourceBias: Float
}

struct CredibilityScore {
    var score: Float
    var confidence: Float
    var sources: [String]
}

struct LogicalFallacy {
    var type: String
    var description: String
    var confidence: Float
}

struct CounterArgument {
    var argument: String
    var strength: Float
    var sources: [String]
}

struct SearchResult {
    var content: String
    var relevance: Float
    var source: String
}

struct VerificationResult {
    var isVerified: Bool
    var confidence: Float
    var sources: [String]
}

struct Fact {
    var content: String
    var sources: [String]
    var verificationScore: Float
}

struct FactCheckResult {
    var isFactual: Bool
    var confidence: Float
    var sources: [String]
    var explanation: String
}

struct FactCheckResponse {
    var query: String
    var result: FactCheckResult
    var timestamp: Date
} 