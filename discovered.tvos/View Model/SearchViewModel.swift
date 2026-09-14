//
//  SearchViewModel.swift
//  discovered.tvos
//
//  Keeps SearchViewController free from request/parsing details.
//

import Foundation

final class SearchViewModel {

    private(set) var items: [ShowItem] = []
    private(set) var isLoading = false

    var onUpdate: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?

    private var currentTask: URLSessionDataTask?
    private var latestQuery = ""

    deinit {
        currentTask?.cancel()
    }

    func search(query: String) {
        latestQuery = query
        isLoading = true
        onLoadingChanged?(true)
        currentTask?.cancel()

        currentTask = NetworkManager.shared.searchContent(query: query, start: 0, limit: 20) { [weak self] result in
            DispatchQueue.main.async {
                guard let self, query == self.latestQuery else { return }
                self.isLoading = false
                self.onLoadingChanged?(false)

                switch result {
                case .success(let response):
                    self.items = response.contentItems.map { $0.showItem }
                    self.onUpdate?()

                case .failure(let error):
                    self.items = []
                    self.onError?(error.localizedDescription)
                    self.onUpdate?()
                }
            }
        }
    }

    func numberOfItems() -> Int {
        items.count
    }

    func item(at index: Int) -> ShowItem? {
        guard index >= 0, index < items.count else { return nil }
        return items[index]
    }
}
