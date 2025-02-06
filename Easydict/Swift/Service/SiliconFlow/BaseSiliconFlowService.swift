import AsyncAlgorithms
import Foundation

// MARK: - BaseSiliconFlowService

@objcMembers
@objc(EZBaseSiliconFlowService)
public class BaseSiliconFlowService: StreamService {
    typealias SiliconFlowChatMessage = [String: String]
    
    let control = StreamControl()
    
    override func contentStreamTranslate(
        _ text: String,
        from: Language,
        to: Language
    ) -> AsyncThrowingStream<String, any Error> {
        let url = URL(string: endpoint)
        
        guard let url, url.isValid else {
            let invalidURLError = QueryError(
                type: .parameter, message: "`\(serviceType().rawValue)` endpoint is invalid"
            )
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: invalidURLError)
            }
        }
        
        result.isStreamFinished = false
        
        let queryType = queryType(text: text, from: from, to: to)
        let chatQueryParam = ChatQueryParam(
            text: text,
            sourceLanguage: from,
            targetLanguage: to,
            queryType: queryType,
            enableSystemPrompt: true
        )
        
        let chatHistory = serviceChatMessageModels(chatQueryParam)
        
        var messages: [[String: String]] = []
        for message in chatHistory {
            if let dict = message as? [String: String] {
                messages.append(dict)
            }
        }
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        return AsyncThrowingStream { continuation in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let firstChoice = choices.first,
                      let message = firstChoice["message"] as? [String: Any],
                      let content = message["content"] as? String else {
                    continuation.finish(throwing: QueryError(type: .network, message: "Invalid response format"))
                    return
                }
                
                continuation.yield(content)
                continuation.finish()
            }
            task.resume()
        }
    }
    
    override func serviceChatMessageModels(_ chatQuery: ChatQueryParam) -> [Any] {
        var chatMessages: [SiliconFlowChatMessage] = []
        for message in chatMessageDicts(chatQuery) {
            let dict: [String: String] = [
                "role": message.role.rawValue,
                "content": message.content
            ]
            chatMessages.append(dict)
        }
        return chatMessages
    }
    
    override func cancelStream() {
        control.cancel()
    }
} 