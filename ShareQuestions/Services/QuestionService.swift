import Foundation
import LeanCloud
import SwiftData

class QuestionService {
    static let shared = QuestionService()
    
    // 存储当前数据版本
    private var currentVersion: Int = 0
    
    // 私有初始化方法
    private init() {}
    
    // 从LeanCloud获取数据版本
    func fetchDataVersion() async throws -> Int {
        let query = LCQuery(className: "DataVersion")
        
        return try await withCheckedThrowingContinuation { continuation in
            query.getFirst { result in
                switch result {
                case .success(let object):
                    do {
                        if let version = object["version"]?.intValue {
                            continuation.resume(returning: version)
                        } else {
                            continuation.resume(returning: 0)
                        }
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // 从LeanCloud获取最大索引值
    func fetchMaxIndex() async throws -> Int {
        let query = LCQuery(className: "DataVersion")
        
        return try await withCheckedThrowingContinuation { continuation in
            query.getFirst { result in
                switch result {
                case .success(let object):
                    do {
                        if let maxIndex = object["maxIndex"]?.intValue {
                            continuation.resume(returning: maxIndex)
                        } else {
                            continuation.resume(returning: 0)
                        }
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // 根据索引列表从LeanCloud获取问题数据
    func fetchQuestionsByIndices(indices: [Int]) async throws -> [Item] {
        let query = LCQuery(className: "Question")
        
        // 修复查询语法 indices.map { LCNumber(integerLiteral: Int64($0)) }
        let lcIndices = indices.map { LCNumber(integerLiteral: $0) }
        query.whereKey("index", .containedIn(lcIndices))
        query.limit = 200
        
        return try await withCheckedThrowingContinuation { continuation in
            query.find { result in
                switch result {
                case .success(let objects):
                    var items: [Item] = []
                    
                    for object in objects {
                        do {
                            let question = object["question"]?.stringValue ?? ""
                            let answer = object["answer"]?.stringValue ?? ""
                            let thinking = object["thinking"]?.stringValue ?? ""
                            let type = object["type"]?.stringValue ?? ""
                            let index = object["index"]?.intValue ?? 0
                            
                            // 确保问题和答案不为空
                            if !question.isEmpty && !answer.isEmpty {
                                let item = Item(
                                    question: question,
                                    answer: answer,
                                    thinking: thinking,
                                    type: type,
                                    index: index,
                                    timestamp: Date(),
                                    isViewed: false
                                )
                                
                                items.append(item)
                            }
                        } catch {
                            print("解析问题数据失败: \(error)")
                        }
                    }
                    
                    continuation.resume(returning: items)
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // 生成随机索引列表（排除已浏览的索引）
    func generateRandomIndices(maxIndex: Int, viewedIndices: [Int], count: Int) -> [Int] {
        var availableIndices = Array(0...maxIndex)
        
        // 移除已浏览的索引
        for index in viewedIndices {
            if let position = availableIndices.firstIndex(of: index) {
                availableIndices.remove(at: position)
            }
        }
        
        // 如果可用索引不足，返回所有可用索引
        if availableIndices.count <= count {
            return availableIndices.shuffled()
        }
        
        // 随机选择指定数量的索引
        return Array(availableIndices.shuffled().prefix(count))
    }
} 
