/*

import Foundation

internal class SignalPerformanceTracker {
    static let shared = SignalPerformanceTracker()

    private var processingTimes: [Double] = []
    private let queue = DispatchQueue(label: "signal.performance.tracker")

    private init() {}

    internal func recordProcessingTime(_ time: Double) {
        queue.async {
            self.processingTimes.append(time)
        }
    }

    internal func printStats() {
        queue.sync {
            guard !processingTimes.isEmpty else {
                print("No signal processing times recorded")
                return
            }

            let totalTime = processingTimes.reduce(0, +)
            let avgTime = totalTime / Double(processingTimes.count)
            let maxTime = processingTimes.max() ?? 0
            let minTime = processingTimes.min() ?? 0

            // Calculate percentiles
            let sorted = processingTimes.sorted()
            let p50 = sorted[sorted.count / 2]
            let p95 = sorted[Int(Double(sorted.count) * 0.95)]
            let p99 = sorted[Int(Double(sorted.count) * 0.99)]

            print("=== Signal Processing Performance ===")
            print("Total signals: \(processingTimes.count)")
            print("Average: \(String(format: "%.2f", avgTime))ms")
            print("Min: \(String(format: "%.2f", minTime))ms")
            print("Max: \(String(format: "%.2f", maxTime))ms")
            print("P50: \(String(format: "%.2f", p50))ms")
            print("P95: \(String(format: "%.2f", p95))ms")
            print("P99: \(String(format: "%.2f", p99))ms")
            print("=====================================")
        }
    }

    internal func reset() {
        queue.async {
            self.processingTimes.removeAll()
        }
    }
}

*/
