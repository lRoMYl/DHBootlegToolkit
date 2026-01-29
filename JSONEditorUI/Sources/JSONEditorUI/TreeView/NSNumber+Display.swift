import Foundation

extension NSNumber {
    /// Returns a string representation of the number that matches
    /// the JSON serialization format.
    ///
    /// - For booleans: returns "true" or "false"
    /// - For floats: returns string with decimal point (e.g., "30.0")
    /// - For integers: returns string without decimal point (e.g., "30")
    ///
    /// This ensures the UI display matches the serialized JSON format.
    var displayValue: String {
        // Check for boolean type first
        if CFGetTypeID(self) == CFBooleanGetTypeID() {
            return self.boolValue ? "true" : "false"
        }

        // Check if it's a float type
        if CFNumberIsFloatType(self) {
            return "\(self.doubleValue)"
        }

        // Otherwise it's an integer
        return "\(self.intValue)"
    }
}
