
import Foundation

class ZoneViewModelManager {
    static let shared = ZoneViewModelManager()

    private init() {}

    private let queue = DispatchQueue(label: "com.adadapted.zoneviewmodelmanager")
    private var viewModelCollection: [WeakZoneViewModel] = []

    //Replacing and registering in one critical section, so two zones for the same id created at once
    //cannot each survive the other's cleanup and leave the id with a duplicate pair
    func addViewModel(viewModel: SwiftZoneViewModel) {
        let replacedViewModels: [SwiftZoneViewModel] = queue.sync {
            let replaced = viewModelCollection.compactMap { $0.viewModel }.filter { $0.zoneId == viewModel.zoneId }
            viewModelCollection.removeAll { $0.viewModel == nil || $0.viewModel?.zoneId == viewModel.zoneId }
            viewModelCollection.append(WeakZoneViewModel(viewModel: viewModel))
            return replaced
        }
        //Detached outside the lock, since onDetach goes on to do event and publisher work of its own
        replacedViewModels.forEach { $0.onDetach() }
    }
}

private struct WeakZoneViewModel {
    weak var viewModel: SwiftZoneViewModel?
}
