
class ZoneViewModelManager {
    static let shared = ZoneViewModelManager()
    
    private init() {}
    
    private var viewModelCollection: [SwiftZoneViewModel] = []

    func addViewModel(viewModel: SwiftZoneViewModel) {
        cleanupViewModels(for: viewModel)
        viewModelCollection.append(viewModel)
    }

    private func cleanupViewModels(for newViewModel: SwiftZoneViewModel) {
        let affectedViewModels = viewModelCollection.filter { $0.zoneId == newViewModel.zoneId }
        affectedViewModels.forEach { $0.onDetach() }
        
        viewModelCollection.removeAll { $0.zoneId == newViewModel.zoneId }
    }
}
