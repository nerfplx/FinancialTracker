import Foundation

final class ExpenseStore {
    private let queue = DispatchQueue(label: "expense.store.queue", qos: .utility)
    private var pendingWrite: DispatchWorkItem?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let fileURL: URL
    
    init(filename: String = "expenses.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.fileURL = docs.appendingPathComponent(filename)
    }
    
    private func load() -> [Expense] {
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([Expense].self, from: data)
        } catch {
            return []
        }
    }
    
    func loadAsync(completion: @escaping ([Expense]) -> Void) {
        queue.async { [weak self] in
            guard let self else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            let value = self.load()
            DispatchQueue.main.async {
                completion(value)
            }
        }
    }
    
    func saveDebounced(_ expenses: [Expense], delay: TimeInterval = 0.45) {
        pendingWrite?.cancel()
        let work = DispatchWorkItem { [encoder, fileURL] in
            do {
                let data = try encoder.encode(expenses)
                try data.write(to: fileURL, options: [.atomic])
            } catch {
                print("Save failed: \(error.localizedDescription)")
            }
        }
        pendingWrite = work
        queue.asyncAfter(deadline: .now() + delay, execute: work)
    }
}
