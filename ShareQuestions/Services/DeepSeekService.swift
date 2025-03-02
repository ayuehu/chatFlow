import Foundation

class DeepSeekService {
    static let shared = DeepSeekService()
    private let apiKey = "sk-hthyqnwsbsvdserkzvzkadvhuirvzlslzwjdzoupkqfooufi"
    private let baseURL = "https://api.siliconflow.cn/v1/chat/completions"
    
    func sendMessage(question: String, message: String) async throws -> String {
        let requestBody: [String: Any] = [
            "model": "Pro/deepseek-ai/DeepSeek-V3",
            "messages": [
                ["role": "system", "content": question],
                ["role": "user", "content": message]
            ],
            "stream": true,
            "max_tokens": 512,
            "stop": ["null"],
            "temperature": 0.6,
            "top_p": 0.95,
            "top_k": 50,
            "frequency_penalty": 0,
            "n": 1,
            "response_format": ["type": "text"]
        ]
        print("requestBody", requestBody)
        
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "请求失败", code: 0)
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        
        throw NSError(domain: "解析失败", code: 0)
    }
    
    func streamMessage(messages: [[String: String]], onChunkReceived: @escaping (String) -> Void) async throws {
        let requestBody: [String: Any] = [
            "model": "Pro/deepseek-ai/DeepSeek-V3",
            "messages": messages,
            "stream": true,
            "max_tokens": 1024,
            "stop": ["null"],
            "temperature": 0.6,
            "top_p": 0.95,
            "top_k": 50,
            "frequency_penalty": 0,
            "n": 1,
            "response_format": ["type": "text"]
        ]
        print(requestBody)
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "请求失败", code: 0)
        }
        
        var accumulatedContent = ""
        for try await line in asyncBytes.lines {
            guard line.hasPrefix("data: "),
                  let jsonData = line.dropFirst(6).data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let delta = choices.first?["delta"] as? [String: Any],
                  let content = delta["content"] as? String else {
                continue
            }
            
            accumulatedContent += content
            onChunkReceived(accumulatedContent)
        }
    }
    
    func buildMessages(question: String, answer: String, history: [ChatMessage]) -> [[String: String]] {
        var messages = [[String: String]]()
        
        // 添加系统消息（卡片问题
        messages.append([
            "role": "system",
            "content": "请简短回答，避免复杂结构，如果要分点回答，请小于两个，口语化一些"
        ])
        //"请简短回答，避免分3个以上的点，避免复杂结构，口语化一些"  "针对用户问题的回复尽量简短，保持在256字以内，避免使用复杂的markdown格式。"
        messages.append([
            "role": "user",
            "content": "\(question)"
        ])
        
        messages.append([
            "role": "assistant",
            "content": "\(answer)"
        ])
        
        // 添加历史对话
        for message in history {
            messages.append([
                "role": message.isUser ? "user" : "assistant",
                "content": message.content
            ])
        }
        
        return messages
    }
} 
