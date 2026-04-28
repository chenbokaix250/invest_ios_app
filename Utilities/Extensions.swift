import Foundation
import SwiftUI

extension Date {
    func formatted(as format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

extension Color {
    static let stockGreen = Color(red: 0.13, green: 0.69, blue: 0.33)
    static let stockRed = Color(red: 0.91, green: 0.30, blue: 0.24)
}

extension Double {
    var formattedPrice: String {
        String(format: "$%.2f", self)
    }

    var formattedPercent: String {
        String(format: "%.2f%%", self)
    }

    var formattedChange: String {
        let sign = self >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", self))"
    }
}
