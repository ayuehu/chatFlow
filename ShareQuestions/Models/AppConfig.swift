import Foundation
import SwiftData

@Model
class AppConfig {
    var dataVersion: Int
    var viewedIndices: [Int]
    var likedIndices: [Int]
    var lastUpdated: Date
    
    init(dataVersion: Int = 0, viewedIndices: [Int] = [], likedIndices: [Int] = []) {
        self.dataVersion = dataVersion
        self.viewedIndices = viewedIndices
        self.likedIndices = likedIndices
        self.lastUpdated = Date()
    }
    
    // 添加已浏览索引
    func addViewedIndex(_ index: Int) {
        if !viewedIndices.contains(index) {
            viewedIndices.append(index)
            lastUpdated = Date()
        }
    }
    
    // 添加已点赞索引
    func addLikedIndex(_ index: Int) {
        if !likedIndices.contains(index) {
            likedIndices.append(index)
            lastUpdated = Date()
        }
    }
    
    // 移除已点赞索引
    func removeLikedIndex(_ index: Int) {
        if let position = likedIndices.firstIndex(of: index) {
            likedIndices.remove(at: position)
            lastUpdated = Date()
        }
    }
    
    // 更新数据版本
    func updateDataVersion(_ version: Int) {
        dataVersion = version
        lastUpdated = Date()
    }
    
    // 重置已浏览索引
    func resetViewedIndices() {
        viewedIndices = []
        lastUpdated = Date()
    }
} 