
import Foundation

class ZoneViewModelManager {
    static let shared = ZoneViewModelManager()

    private init() {}

    private let queue = DispatchQueue(label: "com.adadapted.zoneviewmodelmanager")
    private var viewModelCollection: [SwiftZoneViewModel] = []

    func addViewModel(viewModel: SwiftZoneViewModel) {
        cleanupViewModels(for: viewModel)
        queue.sync {
            viewModelCollection.append(viewModel)
        }
    }

    private func cleanupViewModels(for newViewModel: SwiftZoneViewModel) {
        let affectedViewModels: [SwiftZoneViewModel] = queue.sync {
            let affected = viewModelCollection.filter { $0.zoneId == newViewModel.zoneId }
            viewModelCollection.removeAll { $0.zoneId == newViewModel.zoneId }
            return affected
        }
        affectedViewModels.forEach { $0.onDetach() }
    }
}
