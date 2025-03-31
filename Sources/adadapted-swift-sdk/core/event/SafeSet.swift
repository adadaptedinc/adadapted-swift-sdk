//
//  Created by Brett Clifton on 3/27/25.
//

actor SafeSet<T: Hashable> {
    private var set: Set<T> = []
    
    func insert(_ element: T) {
        set.insert(element)
    }
    
    func isEmpty() -> Bool {
        set.isEmpty
    }
    
    func copyAndClear() -> Array<T> {
        let copiedSet = set
        set.removeAll()
        return Array(copiedSet)
    }
}
