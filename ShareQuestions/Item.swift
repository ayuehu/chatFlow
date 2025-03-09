//
//  Item.swift
//  ShareQuestions
//
//  Created by kaka on 2025/2/23.
//

import Foundation
import SwiftData
import SwiftUI
import MarkdownUI

@Model
final class Item {
    var question: String
    var answer: String
    var thinking: String = ""
    var type: String = ""
    var index: Int = 0  // 添加索引字段
    var timestamp: Date
    var isViewed: Bool
    var isLiked: Bool = false
    
    // Markdown 主题
    var theme: Theme {
        Theme()
            .text {
                FontFamily(.system())  // PingFang SC 使用系统字体
                FontSize(.em(0.9375))  // 15px
                FontWeight(.regular)    // normal
                ForegroundColor(Color(hex: "#585A73"))
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
                ForegroundColor(Color(hex: "#585A73"))
            }
            .link {
                ForegroundColor(.blue)
            }
//            .listItem { configuration in
//                HStack(alignment: .firstTextBaseline) {
//                    Text("•").foregroundColor(.secondary)
//                    configuration.label
//                }
//            }
            .codeBlock { configuration in
                configuration.label
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
            .paragraph { configuration in
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)  // 允许多行
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)  // 确保文本可以占满宽度
            }
            .blockquote { configuration in
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                    .padding(.leading, 16)
            }
            .table { configuration in
                VStack(alignment: .leading, spacing: 8) {
                    configuration.label
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                        .padding(.vertical, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .tableCell { configuration in
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
            }
    }
    
    // Markdown 视图
    var markdownContent: some View {
        ScrollView {  // 添加 ScrollView 确保内容可以滚动
            Markdown(answer)
                .markdownTheme(theme)
                .lineSpacing(9)
                .kerning(0.2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)  // 确保文本可以占满宽度
        }
    }
    
    init(question: String, answer: String, timestamp: Date = Date(), isViewed: Bool = false) {
        self.question = question
        self.answer = answer
        self.timestamp = timestamp
        self.isViewed = isViewed
    }
    
    init(question: String, answer: String, thinking: String, type: String, index: Int = 0, timestamp: Date = Date(), isViewed: Bool = false) {
        self.question = question
        self.answer = answer
        self.thinking = thinking
        self.type = type
        self.index = index
        self.timestamp = timestamp
        self.isViewed = isViewed
    }
}

