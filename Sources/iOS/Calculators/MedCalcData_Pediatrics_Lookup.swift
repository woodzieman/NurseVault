import Foundation

// MARK: - Lookup helpers.
extension MedCalcPedsData {
    // MARK: - Lookup helpers

    /// The source if (x < key) row chain: first row whose key exceeds x, clamped to the last row.
    static func row(_ table: [LMS], _ x: Double) -> LMS {
        for r in table where x < r.key { return r }
        return table[table.count - 1]
    }

    /// For interleaved [female, male] tables: first pair whose key exceeds x, clamped to the last pair.
    static func row(_ table: [LMS], _ x: Double, female: Bool) -> LMS {
        let pairs = table.count / 2
        var pair = pairs - 1
        for p in 0..<pairs where x < table[2 * p].key {
            pair = p
            break
        }
        return table[2 * pair + (female ? 0 : 1)]
    }

    /// LMS z-score for a measured value (L = 0 is treated as a log-normal distribution).
    static func zScore(lms: LMS, value: Double) -> Double {
        guard value > 0, lms.m > 0 else { return .nan }
        if abs(lms.l) < 1e-9 {
            return log(value / lms.m) / lms.s
        }
        return (pow(value / lms.m, lms.l) - 1) / (lms.l * lms.s)
    }

    /// Z-score with linear interpolation between the two bracketing rows (source zScoreInterp).
    static func interpolatedZScore(_ table: [LMS], _ x: Double, _ value: Double) -> Double {
        guard table.count > 1 else { return zScore(lms: table[0], value: value) }
        var upper = table.count - 1
        for i in 0..<(table.count - 1) where x <= table[i].key {
            upper = i
            break
        }
        let r2 = table[upper]
        let z2 = zScore(lms: r2, value: value)
        if upper == 0 { return z2 }
        let r1 = table[upper - 1]
        let z1 = zScore(lms: r1, value: value)
        return z1 + (z2 - z1) * (x - r1.key) / (r2.key - r1.key)
    }

    /// Normal CDF to a percentage, matching the source z-to-percentile table (clamped at +/-3.09 to 0.1 / 99.9).
    static func percentile(z: Double) -> Double {
        if z < -3.09 { return 0.1 }
        if z > 3.09 { return 99.9 }
        return 100 * 0.5 * (1 + erf(z / 2.0.squareRoot()))
    }

}
