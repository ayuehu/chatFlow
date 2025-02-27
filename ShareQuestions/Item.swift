//
//  Item.swift
//  ShareQuestions
//
//  Created by ayue on 2025/2/23.
//

import Foundation
import SwiftData
import SwiftUI
import MarkdownUI

@Model
final class Item {
    var question: String
    var answer: String
    var timestamp: Date
    var isViewed: Bool
    
    // Markdown 主题
    var theme: Theme {
        Theme()
            .text {
                FontFamily(.system())
                FontSize(.em(1.0))
                ForegroundColor(.primary)
            }
            .heading1 { configuration in
                VStack(alignment: .leading, spacing: 8) {
                    configuration.label
                        .fontWeight(.bold)
                        .font(.system(size: 28))
                    Divider()
                }
            }
            .heading2 { configuration in
                configuration.label
                    .fontWeight(.bold)
                    .font(.system(size: 24))
            }
            .heading3 { configuration in
                configuration.label
                    .fontWeight(.bold)
                    .font(.system(size: 20))
            }
            .strong {
                FontWeight(.bold)
                FontFamily(.system())
            }
            .link {
                ForegroundColor(.blue)
            }
            .listItem { configuration in
                HStack(alignment: .firstTextBaseline) {
                    Text("•").foregroundColor(.secondary)
                    configuration.label
                }
            }
            .codeBlock { configuration in
                configuration.label
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
    }
    
    // Markdown 视图
    var markdownContent: some View {
        Markdown(answer)
            .markdownTheme(theme)
    }
    
    init(question: String, answer: String, timestamp: Date = Date(), isViewed: Bool = false) {
        self.question = question
        self.answer = answer
        self.timestamp = timestamp
        self.isViewed = isViewed
    }
}

// 预览支持
#if DEBUG
extension Item {
    static var preview: Item {
        Item(
            question: "测试问题",
            answer: """
            # 标题1
            ## 标题2
            ### 标题3
            
            普通文本
            
            **粗体文本**
            
            - 列表项1
            - 列表项2
            
            [链接文本](https://example.com)
            
            ```swift
            let code = "示例代码"
            ```
            """
        )
    }
}
#endif

