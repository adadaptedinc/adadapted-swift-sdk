
class GroupGarbageCollector {
    static let shared = GroupGarbageCollector()
    
    private init() {}
    
    private var groupedViewModelCollections: [String: [SwiftZoneViewModel]] = [:]
    
    // Add a new ViewModel to the collection
    func addViewModel(_ viewModel: SwiftZoneViewModel) {
        addZoneViewModel(forKey: viewModel.viewGroupId, viewModel: viewModel)
        print("Share VM Collections: \(groupedViewModelCollections.count)")
    }
    
    // Collect garbage by stopping all view models in the group and removing them
    func collectGarbage(for viewModel: SwiftZoneViewModel) {
        let key = viewModel.viewGroupId
        
        groupedViewModelCollections[key]?.forEach { $0.onStop() }
        removeZoneViewModels(forKey: key)
    }
    
    // Add a ViewModel to the specific group (key)
    private func addZoneViewModel(forKey key: String, viewModel: SwiftZoneViewModel) {
        groupedViewModelCollections[key, default: []].append(viewModel)
    }
    
    // Remove all ViewModels for a specific group (key)
    private func removeZoneViewModels(forKey key: String) {
        groupedViewModelCollections[key] = nil
    }
}
