import Foundation

/// Configuration constants for S3 Feature Config Editor
enum S3EditorConfiguration {
  /// Maximum number of keys allowed in an object for field inspection
  /// Objects with more keys than this threshold cannot be inspected to avoid performance issues
  static let maxInspectableObjectKeys: Int = 30

  /// Error messages for inspection blocking
  enum InspectionError {
    static let absoluteRoot = "Cannot inspect the absolute root. Please select a specific field."
    static func tooManyKeys(count: Int) -> String {
      "Cannot inspect objects with more than \(maxInspectableObjectKeys) keys (this object has \(count) keys) due to performance constraints."
    }
  }
}
