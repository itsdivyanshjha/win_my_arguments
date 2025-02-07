import Foundation

class CacheManager {
    private var cache: [String: FactCheckResponse] = [:]
    
    // Implement caching for frequently accessed facts
    func cacheResponse(_ response: FactCheckResponse, for query: String) {
        cache[query] = response
    }
    
    func getCachedResponse(for query: String) -> FactCheckResponse? {
        return cache[query]
    }
} 