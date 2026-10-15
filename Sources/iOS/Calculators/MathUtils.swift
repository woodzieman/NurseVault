import Foundation
extension Double { var safeLog: Double { self > 0 ? log(self) : .nan } }
func formatResult(_ value: Double, _ decimals: Int = 2) -> String {
    let formatted = String(format: "%.\\(decimals)f", value)
    return formatted.replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
        .replacingOccurrences(of: ".$", with: "")
}
func normalCDF(_ x: Double) -> Double {
    let a1 = 0.254829592, a2 = -0.284496736, a3 = 1.421413741
    let a4 = -1.453152023, a5 = 1.061405429, p = 0.3275911
    let sign = x < 0 ? -1.0 : 1.0, absX = abs(x)
    let t = 1.0 / (1.0 + p * absX)
    return 0.5 * (1.0 + sign * (1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-absX * absX / 2.0)))
}
