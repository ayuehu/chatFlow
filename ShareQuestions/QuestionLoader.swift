import Foundation

struct QuestionLoader {
    static func loadQuestionsFromFile(named filename: String) -> [Item] {
        guard let fileURL = Bundle.main.url(forResource: filename, withExtension: "txt"),
              let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            print("无法读取文件：\(filename).txt")
            return []
        }
        
        var questions: [Item] = []
        let sections = content.components(separatedBy: "\n----q----\n")
        print(sections.count)
        for section in sections {
            let lines = section.trimmingCharacters(in: .whitespacesAndNewlines)
                             .components(separatedBy: "\n")
            
            guard lines.count >= 2 else { continue }
            
            // 第一行是问题（去掉"Q: "前缀如果有的话）
            let question = lines[0].replacingOccurrences(of: "Q: ", with: "")
            
            // 剩余的行是答案
            let answer = lines[1...].joined(separator: "\n")
//            let answers = answer.trimmingCharacters(in: .whitespacesAndNewlines)
//                            .components(separatedBy: "\n----rc----\n")
            let answers = answer.components(separatedBy: "\n----rc----\n")
            
            let item = Item(
                question: question,
                answer: answers[0],
                thinking: answers[1],
                type : filename,
                timestamp: Date(),
                isViewed: false
            )
            questions.append(item)
        }
        
        return questions
    }
} 
