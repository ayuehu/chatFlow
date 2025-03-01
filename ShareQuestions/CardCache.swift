import SwiftUI
import SwiftData

actor CardCache {
    static let shared = CardCache()
    private var cache: [Int: CardView] = [:]
    
    func getCard(for index: Int, item: Item) -> CardView {
        if let cachedCard = cache[index] {
            print("get cache card", item.question)
            return cachedCard
        }
        let newCard = CardView(item: item)
        print("new cache card", item.question)
        cache[index] = newCard
        return newCard
    }
    
    func clearCache() {
        cache.removeAll()
    }
    
    // 预加载指定索引的卡片
    func preloadCard(for index: Int, item: Item) {
        if cache[index] == nil {
            cache[index] = CardView(item: item)
        }
    }
} 
