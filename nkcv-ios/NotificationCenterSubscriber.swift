import Foundation


class NotificationCenterSubscriber {
    private var observers: [NSObjectProtocol] = []

    func subscribe(for name: Notification.Name, object: Any?, queue: OperationQueue?, using block: @escaping (NotificationCenterSubscriber, Notification) -> Void) {
        let observer = NotificationCenter.default.addObserver(forName: name, object: object, queue: queue) { [weak self] (note) in
            guard let self = self else {
                return
            }
            block(self, note)
        }
        runOnMain { [weak self] in
            guard let self = self else {
                return
            }
            self.observers.append(observer)
        }
    }

    func unsubscribeAll() {
        runOnMain { [weak self] in
            self?.unsubscribe()
        }
    }

    deinit {
        self.unsubscribe()
    }

    private func unsubscribe() {
        self.observers.reversed().forEach { (it) in
            NotificationCenter.default.removeObserver(it)
        }
        self.observers.removeAll()
    }
}
