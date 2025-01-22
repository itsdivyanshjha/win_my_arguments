import Foundation

enum ChatError: Error {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case apiError(String)
}

class ChatService {
    private let apiKey = "2d03a675-782b-48f3-af14-d253a711e3a1"
    private let baseURL = "https://api.sambanova.ai/v1/chat/completions"
    
    func sendMessage(_ message: String) async throws -> String {
        print("🚀 Starting API request process...")
        
        guard let url = URL(string: baseURL) else {
            print("❌ Invalid URL: \(baseURL)")
            throw ChatError.invalidURL
        }
        
        let messageData = ChatRequest(
            stream: true,
            model: "Meta-Llama-3.1-8B-Instruct",
            messages: [
                ChatMessage(role: "system", content: "You are a helpful assistant that provides factual information and references to help win arguments. Focus on providing verifiable facts and cite sources when possible."),
                ChatMessage(role: "user", content: message)
            ]
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        request.httpBody = try encoder.encode(messageData)
        
        print("📤 Sending request to API...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ChatError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                throw ChatError.apiError("API returned status code \(httpResponse.statusCode)")
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                let events = responseString.components(separatedBy: "\n\n")
                var fullContent = ""
                
                for event in events {
                    if event.hasPrefix("data: ") {
                        let jsonString = String(event.dropFirst(6))
                        if jsonString == "[DONE]" { continue }
                        
                        if let eventData = jsonString.data(using: .utf8),
                           let streamResponse = try? JSONDecoder().decode(StreamResponse.self, from: eventData) {
                            if let content = streamResponse.choices.first?.delta.content {
                                fullContent += content
                            }
                        }
                    }
                }
                
                return fullContent.isEmpty ? "No response content" : fullContent
            }
            
            throw ChatError.decodingError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response"]))
        } catch {
            print("💥 Error occurred: \(error)")
            throw ChatError.networkError(error)
        }
    }

    func testConnection() async {
        print("🧪 Testing API connection...")
        do {
            let response = try await sendMessage("Hello, this is a test message")
            print("✅ Test successful! Response: \(response)")
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }
}

// Request Models
struct ChatRequest: Codable {
    let stream: Bool
    let model: String
    let messages: [ChatMessage]
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

// Updated Response Models to match potential API response formats
struct ChatResponse: Codable {
    let id: String?
    let choices: [Choice]
    
    enum CodingKeys: String, CodingKey {
        case id
        case choices
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        choices = try container.decode([Choice].self, forKey: .choices)
    }
}

struct Choice: Codable {
    let message: ResponseMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try container.decode(ResponseMessage.self, forKey: .message)
        finishReason = try container.decodeIfPresent(String.self, forKey: .finishReason)
    }
}

struct ResponseMessage: Codable {
    let role: String
    let content: String
}

struct APIErrorResponse: Codable {
    let error: APIError
}

struct APIError: Codable {
    let message: String
    let type: String?
}

// Add these new response models for streaming
struct StreamResponse: Codable {
    let choices: [StreamChoice]
}

struct StreamChoice: Codable {
    let delta: DeltaContent
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case delta
        case finishReason = "finish_reason"
    }
}

struct DeltaContent: Codable {
    let content: String?
    let role: String?
} 