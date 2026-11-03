import Foundation

struct BaselineEngine {
    struct MetricBaseline {
        let mean: Double
        let standardDeviation: Double
    }

    static func baseline(values: [Double]) -> MetricBaseline? {
        guard !values.isEmpty else { return nil }
        let mean = values.reduce(0, +) / Double(values.count)
        guard values.count > 1 else { return MetricBaseline(mean: mean, standardDeviation: 0) }
        let variance = values.reduce(0) { partial, value in
            partial + pow(value - mean, 2)
        } / Double(values.count - 1)
        return MetricBaseline(mean: mean, standardDeviation: sqrt(variance))
    }

    static func zScore(value: Double, baseline: MetricBaseline) -> Double {
        guard baseline.standardDeviation > 0 else { return 0 }
        return (value - baseline.mean) / baseline.standardDeviation
    }

    static func percentChange(from baseline: Double, to current: Double) -> Double {
        guard baseline != 0 else { return 0 }
        return ((current - baseline) / abs(baseline)) * 100
    }
}