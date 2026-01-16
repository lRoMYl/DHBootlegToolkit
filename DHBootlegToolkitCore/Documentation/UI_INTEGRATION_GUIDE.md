# UI Integration Guide - Commentary Source URL Button

## Overview
The `MarketSentiment` model now includes an optional `sourceURL` property that your UI can use to display a clickable button when a commentary has a source reference.

## Model Structure

```swift
public struct MarketSentiment: Sendable, Identifiable {
    public let id: UUID
    public let emoji: String
    public let commentary: String
    public let category: SentimentCategory
    public let generatedAt: Date
    public let sourceURL: URL?  // ← New property for UI display
}
```

## UI Implementation Examples

### SwiftUI Example

```swift
import SwiftUI
import DHOpsToolsCore

struct CommentaryView: View {
    let sentiment: MarketSentiment

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Emoji and commentary
            HStack(alignment: .top, spacing: 8) {
                Text(sentiment.emoji)
                    .font(.title)

                Text(sentiment.commentary)
                    .font(.body)
                    .foregroundColor(.primary)
            }

            // Source URL button (only shown when available)
            if let sourceURL = sentiment.sourceURL {
                Button(action: {
                    #if os(iOS)
                    UIApplication.shared.open(sourceURL)
                    #elseif os(macOS)
                    NSWorkspace.shared.open(sourceURL)
                    #endif
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "link.circle.fill")
                        Text("Read Source")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
```

### UIKit Example

```swift
import UIKit
import DHOpsToolsCore

class CommentaryCell: UITableViewCell {
    private let emojiLabel = UILabel()
    private let commentaryLabel = UILabel()
    private let sourceButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // Setup emoji label
        emojiLabel.font = .systemFont(ofSize: 32)

        // Setup commentary label
        commentaryLabel.font = .systemFont(ofSize: 16)
        commentaryLabel.numberOfLines = 0

        // Setup source button
        sourceButton.setTitle("Read Source", for: .normal)
        sourceButton.setImage(UIImage(systemName: "link.circle.fill"), for: .normal)
        sourceButton.addTarget(self, action: #selector(openSource), for: .touchUpInside)

        // Add to view hierarchy
        let stackView = UIStackView(arrangedSubviews: [
            emojiLabel,
            commentaryLabel,
            sourceButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .leading

        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    private var sourceURL: URL?

    func configure(with sentiment: MarketSentiment) {
        emojiLabel.text = sentiment.emoji
        commentaryLabel.text = sentiment.commentary

        // Show/hide source button based on URL availability
        if let url = sentiment.sourceURL {
            sourceURL = url
            sourceButton.isHidden = false
        } else {
            sourceURL = nil
            sourceButton.isHidden = true
        }
    }

    @objc private func openSource() {
        guard let url = sourceURL else { return }
        UIApplication.shared.open(url)
    }
}
```

### AppKit (macOS) Example

```swift
import AppKit
import DHOpsToolsCore

class CommentaryViewController: NSViewController {
    @IBOutlet weak var emojiLabel: NSTextField!
    @IBOutlet weak var commentaryLabel: NSTextField!
    @IBOutlet weak var sourceButton: NSButton!

    private var sourceURL: URL?

    func display(sentiment: MarketSentiment) {
        emojiLabel.stringValue = sentiment.emoji
        commentaryLabel.stringValue = sentiment.commentary

        // Show/hide and configure source button
        if let url = sentiment.sourceURL {
            sourceURL = url
            sourceButton.isHidden = false
            sourceButton.title = "Read Source"
        } else {
            sourceURL = nil
            sourceButton.isHidden = true
        }
    }

    @IBAction func openSource(_ sender: Any) {
        guard let url = sourceURL else { return }
        NSWorkspace.shared.open(url)
    }
}
```

## Button Design Guidelines

### Recommended Styles

1. **Link Style** (Subtle)
   - Small font (12-14pt)
   - Blue/accent color
   - Icon: `link.circle.fill` or `safari`
   - Text: "Read Source" or "Source"

2. **Chip/Tag Style** (Medium Prominence)
   - Rounded background with border
   - Muted color (gray/blue)
   - Icon + text
   - Text: "View Source" or "Learn More"

3. **Button Style** (High Prominence)
   - Bordered or filled button
   - Secondary color
   - Icon + text
   - Text: "Read Full Article"

### Example Designs

#### Minimal Link Style
```swift
Button(action: openSource) {
    HStack(spacing: 4) {
        Image(systemName: "link")
            .font(.caption)
        Text("Source")
            .font(.caption)
    }
    .foregroundColor(.secondary)
}
```

#### Chip/Tag Style
```swift
Button(action: openSource) {
    HStack(spacing: 6) {
        Image(systemName: "newspaper.fill")
            .font(.caption2)
        Text("Read Article")
            .font(.caption)
            .fontWeight(.medium)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(Color.blue.opacity(0.1))
    .foregroundColor(.blue)
    .cornerRadius(12)
}
```

#### Prominent Button Style
```swift
Button(action: openSource) {
    HStack(spacing: 8) {
        Image(systemName: "safari")
        Text("View Source")
            .fontWeight(.semibold)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .background(Color.blue)
    .foregroundColor(.white)
    .cornerRadius(8)
}
```

## Source URL Coverage

### Commentaries with URLs (~18% coverage)

The following categories have source URLs mapped:

1. **Talabat IPO** (7+ commentaries)
   - Source: https://www.menabytes.com/talabat-final-ipo-price/

2. **DeliveryHero Financials** (11+ commentaries)
   - Source: https://www.deliveryhero.com/newsroom/trading-update-q4-2024/

3. **Uber-Foodpanda Taiwan Deal** (6+ commentaries)
   - Source: https://techcrunch.com/2025/03/11/uber-terminates-foodpanda-taiwan-acquisition-citing-regulatory-hurdles/

4. **Baemin Acquisition** (5+ commentaries)
   - Source: https://gnss.asia/blog/delivery-hero-acquires-koreas-top-food-delivery-app-operator-for-us-4bn/

5. **EU Antitrust Fine** (5+ commentaries)
   - Source: https://www.gtlaw.com/en/insights/2025/8/european-commission-fines-delivery-hero-and-glovo-eur-329-million-in-first-labor-market-cartel-case

6. **Stock Performance** (4+ commentaries)
   - Source: https://finance.yahoo.com/news/delivery-hero-etr-dher-investor-three-year-losses-grow-to-68-as-the-stock-sheds-%E2%82%AC279m-this-past-week-090124503.html

7. **Grab-Foodpanda Deal** (3+ commentaries)
   - Source: https://thelowdown.momentum.asia/grab-is-buying-back-shares-but-not-foodpanda/

8. **Talabat IR** (5+ commentaries)
   - Source: https://ir.talabat.com/

### When URL is Not Available

For commentaries without a source URL (general observations, humor, meta-commentary), the `sourceURL` property will be `nil`. Your UI should gracefully hide the button in these cases.

## Best Practices

### 1. Conditional Display
Always check for `nil` before showing the button:
```swift
if let sourceURL = sentiment.sourceURL {
    // Show button
}
```

### 2. Accessibility
Add proper labels for screen readers:
```swift
Button(action: openSource) {
    // ...
}
.accessibilityLabel("Read source article")
.accessibilityHint("Opens external browser to view original article")
```

### 3. Loading States
Consider showing a loading indicator when opening URLs:
```swift
@State private var isLoading = false

Button(action: {
    isLoading = true
    UIApplication.shared.open(sourceURL) { success in
        isLoading = false
    }
}) {
    if isLoading {
        ProgressView()
    } else {
        // Button content
    }
}
```

### 4. Error Handling
Handle cases where the URL might fail to open:
```swift
guard let sourceURL = sentiment.sourceURL else { return }

#if os(iOS)
UIApplication.shared.open(sourceURL) { success in
    if !success {
        // Show error alert
        print("Failed to open URL: \(sourceURL)")
    }
}
#endif
```

## Testing

### Unit Test Example
```swift
import XCTest
@testable import DHBootlegToolkitCore

class MarketSentimentTests: XCTestCase {
    func testSentimentWithSourceURL() {
        let sentiment = MarketSentiment(
            emoji: "🚀",
            commentary: "Talabat IPO vibes: Priced at the top of range, just like this move 🚀",
            category: .moonshot,
            sourceURL: URL(string: "https://www.menabytes.com/talabat-final-ipo-price/")
        )

        XCTAssertNotNil(sentiment.sourceURL)
        XCTAssertEqual(sentiment.sourceURL?.absoluteString, "https://www.menabytes.com/talabat-final-ipo-price/")
    }

    func testSentimentWithoutSourceURL() {
        let sentiment = MarketSentiment(
            emoji: "📈",
            commentary: "Chart goes up for once!",
            category: .gains
        )

        XCTAssertNil(sentiment.sourceURL)
    }
}
```

### UI Test Example
```swift
func testSourceButtonAppears() {
    let sentiment = MarketSentiment(
        emoji: "🚀",
        commentary: "Test commentary",
        category: .moonshot,
        sourceURL: URL(string: "https://example.com")
    )

    let view = CommentaryView(sentiment: sentiment)
    let hosting = UIHostingController(rootView: view)

    // Verify button exists and is tappable
    // (Specific implementation depends on your testing framework)
}
```

## Migration Guide

If you have existing UI code displaying `MarketSentiment`, no changes are required since `sourceURL` is optional with a default value of `nil`. To add the source button:

1. **Check for URL availability**:
   ```swift
   if let url = sentiment.sourceURL {
       // Show button
   }
   ```

2. **Add button to your view hierarchy** (see examples above)

3. **Open URL in external browser** when tapped

That's it! The `CommentaryEngine` automatically populates the `sourceURL` when available.

## Questions?

For issues or questions about the source URL feature, refer to:
- `/Documentation/CommentarySources.md` - Full source mapping
- `/Documentation/COMMENTARY_ENHANCEMENT_SUMMARY.md` - Implementation overview
