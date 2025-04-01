//
//  Created by Brett Clifton on 3/31/25.
//

actor SafeArray<T> {
    private var array: [T] = []
    
    func append(_ element: T) {
        array.append(element)
    }
    
    func insertAtBeginning(_ element: T) {
        array.insert(element, at: 0)
    }
    
    func removeFirst(where predicate: (T) -> Bool) {
        if let index = array.firstIndex(where: predicate) {
            array.remove(at: index)
        }
    }
    
    func removeAll(where predicate: (T) -> Bool) {
        array.removeAll(where: predicate)
    }
    
    func forEach(_ action: (T) -> Void) {
        for element in array {
            action(element)
        }
    }
    
    func isEmpty() -> Bool {
        array.isEmpty
    }
    
    func allItems() -> [T] {
        return array
    }
}
