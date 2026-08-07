
import Foundation

class ZoneViewModelManager {
    static let shared = ZoneViewModelManager()

    private init() {}

    private let queue = DispatchQueue(label: "com.adadapted.zoneviewmodelmanager")
    private var viewModelCollection: [WeakZoneViewModel] = []

    func addViewModel(viewModel: SwiftZoneViewModel) {
        cleanupViewModels(for: viewModel)
        queue.sync {
            viewModelCollection.append(WeakZoneViewModel(viewModel: viewModel))
        }
    }

    private func cleanupViewModels(for newViewModel: SwiftZoneViewModel) {
        let affectedViewModels: [SwiftZoneViewModel] = queue.sync {
            let affected = viewModelCollection.compactMap { $0.viewModel }.filter { $0.zoneId == newViewModel.zoneId }
            viewModelCollection.removeAll { $0.viewModel == nil || $0.viewModel?.zoneId == newViewModel.zoneId }
            return affected
        }
        affectedViewModels.forEach { $0.onDetach() }
    }
}

private struct WeakZoneViewModel {
    weak var viewModel: SwiftZoneViewModel?
}
