# Module Documentation

> **Navigation:** [← Back to README](../README.md) | [Architecture](ARCHITECTURE.md) | [Development](DEVELOPMENT.md) | [UI Structure](UI_STRUCTURE.md)

This document provides detailed information about each module in DHBootlegToolkit.

## Table of Contents

- [Market Watch Module](#market-watch-module)
- [Localization Editor Module](#localization-editor-module)
- [S3 Feature Config Editor Module](#s3-feature-config-editor-module)
- [Logger Module](#logger-module)

---

## Market Watch Module

**Location:** `DHBootlegToolkit/Views/StockTicker/`
**State Container:** `StockTickerStore.swift`

Real-time stock market monitoring with sentiment analysis and interactive charts.

### Features & Capabilities

- Real-time price tracking via WebSocket connections
- Dynamic sentiment analysis with adaptive thresholds
- Interactive price charts with 11 time ranges
- Market statistics and trading hours display
- Witty market commentary with emoji indicators
- **Position Calculator** (NEW): Track investment positions with profit/loss calculations
  - Average strike price tracking
  - Total units/shares owned
  - Target price goals
  - Real-time P/L visualization
  - Progress tracking toward targets
  - 100% offline - all calculations done locally, no tracking

### YahooFinanceWorker Integration

**WebSocket Connections:**
- Maintains persistent WebSocket connection to Yahoo Finance
- Receives real-time price updates as they occur
- Automatic reconnection on connection loss

**REST API Fallback:**
- Falls back to REST API when WebSocket unavailable
- Periodic polling for price updates
- Historical data fetching for charts

**AsyncStream Data Updates:**
```swift
func priceStream() -> AsyncStream<StockData> {
    AsyncStream { continuation in
        // Stream real-time updates to UI
    }
}
```

### CommentaryEngine

**Dynamic Sentiment Analysis:**
- Analyzes price movements in real-time
- Calculates percentage change from baseline
- Compares against adaptive thresholds

**Witty Market Commentary Generation:**
- Generates contextual commentary based on sentiment category
- Uses emoji indicators for visual impact
- Randomized messages for variety

**Threshold-Based Categories:**
- **Moonshot** 🚀: Exceptional gains (e.g., +5% or more)
- **Gains** 📈: Moderate positive movement
- **Flat** 😐: Minimal movement within neutral range
- **Losses** 📉: Moderate negative movement
- **Crash** 💥: Severe losses (e.g., -5% or more)

**Adaptive Calculation:**
```swift
// Volatility-based threshold adjustment
let volatility = standardDeviation(returns) * volatilityMultiplier
let adjustedThreshold = baseThreshold * (1 + volatility)
```

### Configuration

**Symbol Management:**
- Add/remove stock symbols
- Persist symbol list in UserDefaults
- Support for major exchanges (NYSE, NASDAQ)

**Threshold Customization:**
- Fixed baseline thresholds
- Dynamic adjustments based on 3-month volatility
- Configurable volatility multiplier

### Technical Implementation

**Key Files:**

| File | Purpose |
|------|---------|
| `StockTickerDetailView.swift` | Main detail view with price card, thresholds, charts, and position calculator |
| `StockPriceCard.swift` | Price display with trading hours and connection status |
| `SentimentThresholdLegend.swift` | Dynamic threshold display with color indicators |
| `StockChartView.swift` | Interactive Swift Charts implementation with range selection |
| `MarketStatsGrid.swift` | Market statistics display (open, high, low, volume, P/E, market cap) |
| `StockTickerBrowserView.swift` | Sidebar stock list navigation |
| **`PositionCalculatorCard.swift`** | Position tracking with P/L calculations and visualization |
| **`PositionEditorSheet.swift`** | Modal editor for adding/editing positions |
| **`ProfitLossVisualization.swift`** | Interactive P/L slider with price markers and progress bar |
| **`PositionSummaryBadge.swift`** | Compact P/L badge for sidebar rows |
| **`PrivacyNoticeBanner.swift`** | Privacy reassurance banner for offline calculations |

**Data Flow:**
```
YahooFinanceWorker (WebSocket/REST)
        ↓
AsyncStream<StockData>
        ↓
StockTickerStore (@Observable)
        ↓
SwiftUI Views (automatic updates)
```

### Chart Time Ranges

Interactive charts support 11 time ranges with adaptive formatting:

| Range | X-Axis Stride | X-Axis Format | Use Case |
|-------|---------------|---------------|----------|
| 1D | Hour | Hour (HH:00) | Intraday trading patterns |
| 1W | Day | Weekday (Mon, Tue) | Weekly price movements |
| 1M | Week | Day (16, 23, 30) | Monthly trends |
| 3M | Month | Month + Day (Jan 15) | Quarterly analysis |
| 6M | Month | Month + Day (Jan 15) | Half-year performance |
| YTD | Month | Month (Jan, Feb) | Year-to-date tracking |
| 1Y | Month | Month (Jan, Feb) | Annual performance |
| 2Y | Year | Year (2024, 2025) | Multi-year trends |
| 5Y | Year | Year (2021, 2022, ...) | Long-term analysis |
| 10Y | Year | Year (2016, 2017, ...) | Decade-long perspective |
| All | Year | Year | Complete historical data |

**Chart Features:**
- **Hover inspection**: View exact price at specific time
- **Range selection**: Drag to select range and view statistics
- **Smooth interpolation**: Catmull-rom curves for professional appearance
- **Sentiment overlay**: Color-coded based on price change
- **Adaptive axes**: Labels adjust based on time range

### Position Calculator

**NEW FEATURE:** Track investment positions with real-time profit/loss calculations.

**Privacy-First Design:**
- All calculations performed locally on-device
- No network requests for position data
- Data stored only in UserDefaults
- No analytics or tracking
- Clear privacy notice displayed to users

**Position Tracking:**
- **Average Strike Price**: Track the average price paid per share
- **Total Units**: Number of shares owned
- **Target Price** (optional): Desired sell price goal
- **Total Investment**: Automatically calculated (strike × units)
- **Current Value**: Real-time value based on current stock price

**P/L Calculations:**
```swift
// Current profit/loss
profitLoss = (currentPrice - strikePrice) × units
profitLossPercent = ((currentPrice - strikePrice) / strikePrice) × 100

// Progress to target
progressPercent = ((currentPrice - strikePrice) / (targetPrice - strikePrice)) × 100
```

**Visual Components:**

1. **PositionCalculatorCard**: Main calculator interface
   - Position summary (strike, units, target)
   - Real-time P/L display with color coding
   - P/L visualization slider
   - Edit/Clear buttons
   - Empty state with "Add Position" prompt

2. **ProfitLossVisualization**: Interactive slider showing:
   - Loss zone (red) | Break-even point | Profit zone (green) | Target
   - Current price marker with color coding
   - Progress bar showing percentage to target
   - Price labels for strike, current, and target
   - Detailed P/L summary:
     - Current P/L (amount + percentage)
     - Amount/percentage to target (if set)
     - Amount/percentage to break-even (if in loss)

3. **PositionEditorSheet**: Modal form editor
   - Strike price input (Decimal validation)
   - Units input (Int validation)
   - Target price input (optional, must be > strike)
   - Live calculation preview
   - Total investment and current value display

4. **PositionSummaryBadge**: Compact sidebar badge
   - Shows quick P/L summary (e.g., "💰 +€250 ↑")
   - Color-coded (green/red/gray)
   - Direction arrow indicator
   - Only shown when position exists

5. **PrivacyNoticeBanner**: Reassurance banner
   - Lock shield icon
   - Clear privacy message
   - Displayed below calculator card

**Data Persistence:**
```swift
// UserDefaults keys per symbol
"position_DHER.DE" → PositionData JSON
"position_TALABAT.AE" → PositionData JSON

// Automatic save on edit
store.savePosition(position)

// Automatic load on app launch
store.loadPositions()
```

**StockTickerStore Integration:**
```swift
// New properties
var positions: [String: PositionData]
var showPositionEditor: Bool
var editingPositionSymbol: String?

// New methods
func savePosition(_ position: PositionData)
func deletePosition(for symbol: String)
func position(for symbol: String) -> PositionData?
func currentProfitLoss(for symbol: String) -> (amount: Decimal, percent: Double)?
func progressToTarget(for symbol: String) -> Double?
```

**PositionData Model:**
```swift
struct PositionData: Codable, Sendable {
  let symbol: String
  let strikePrice: Decimal
  let units: Int
  let targetPrice: Decimal?
  let lastUpdated: Date

  // Computed properties
  var totalInvestment: Decimal
  func currentValue(at price: Decimal) -> Decimal
  func profitLoss(at currentPrice: Decimal) -> Decimal
  func profitLossPercent(at currentPrice: Decimal) -> Double
  func isProfitable(at currentPrice: Decimal) -> Bool
  func progressToTarget(at currentPrice: Decimal) -> Double?
  func amountToTarget(at currentPrice: Decimal) -> Decimal?
  func percentToTarget(at currentPrice: Decimal) -> Double?
}
```

### Use Cases

- **Day traders**: Monitor real-time price movements with 1D chart
- **Swing traders**: Analyze weekly/monthly patterns with sentiment indicators
- **Long-term investors**: Track yearly performance with All-time chart + position P/L
- **Portfolio trackers**: Calculate real-time profit/loss on holdings with privacy guarantee
- **Market enthusiasts**: Enjoy witty commentary during market volatility

---

## Localization Editor Module

**Location:** `DHBootlegToolkit/Views/LocalizationEditor/`
**State Container:** `AppStore.swift` (~1600 lines)

Edit translation keys for mobile and web platforms with integrated Git workflow.

### Features & Capabilities

- **Multi-tab editor** supporting translation keys, images, and text files
- **Feature-based navigation** for organizing translations by feature folders
- **Multi-platform support** for mobile and web localization files
- **New key wizard** with screenshot attachment
- **External change detection** with conflict resolution
- **Git integration** with file-level status badges

### Feature-Based Navigation

**Repository Structure:**
```json
{
  "basePath": "translations/project",
  "platforms": [
    { "id": "mobile", "folderName": "mobile", "displayName": "Mobile" },
    { "id": "web", "folderName": "web", "displayName": "Web" }
  ],
  "primaryLanguageFile": "en.json",
  "assetsFolderName": "images"
}
```

**Navigation Hierarchy:**
- Feature folders (e.g., `onboarding/`, `checkout/`)
- Platform selection (mobile/web) per feature
- Translation keys grouped by feature
- Associated images and text files

### Multi-Platform Support

**Platform Selection:**
- Switch between mobile and web translations
- Platform-specific key organization
- Independent translation files per platform

**File Structure:**
```
translations/project/
├── mobile/
│   ├── onboarding/
│   │   ├── en.json
│   │   ├── es.json
│   │   └── images/
│   └── checkout/
│       ├── en.json
│       └── images/
└── web/
    ├── onboarding/
    │   └── en.json
    └── checkout/
        └── en.json
```

### New Key Wizard

**Three-Step Flow:**

1. **Screenshot** - Add reference screenshot for context
2. **Key Details** - Enter key name, translation text, notes, character limit
3. **Review** - Preview and confirm before saving

**Wizard Features:**
- Screenshot attachment for visual context
- Key name validation with regex pattern
- Character limit tracking
- Notes field for translator context
- Review step prevents errors

### JSONEditorCore/UI/Kit Integration

**JSONEditorCore:**
- JSON parsing and serialization
- Tree structure management
- Edit operations and validation

**JSONEditorUI:**
- Tree view components for hierarchical JSON
- Field editors for different value types
- Search and filtering UI (JSONSearchBar)
- Editor toolbar (JSONEditorToolbar)

**JSONEditorKit:**
- Helper functions for JSON manipulation
- Validation utilities
- Formatting tools for readable output

### Git Integration

**File-Level Status Badges:**
- `[A]` Added - New translation keys
- `[M]` Modified - Changed translations
- `[-]` Deleted - Removed keys

**Git Workflow:**
- Create feature branch for translations
- Commit changes with descriptive messages
- Open PR directly from app via GitHub CLI

**External Change Detection:**
- Detects concurrent edits from other tools
- Shows conflict resolution dialog
- Options to keep local changes or reload from disk

### Key Files

| File | Purpose |
|------|---------|
| `DetailTabView.swift` | Multi-tab container with new key wizard |
| `TranslationDetailView.swift` | Individual translation key editor with fixed toolbar |
| `TranslationListView.swift` | List of translation keys per feature |
| `TextTabView.swift` | Text/JSON file previewer |
| `ImageTabView.swift` | Image preview viewer |
| `FeatureBrowserView.swift` | Feature tree navigation with git badges |

### UI Improvements

**Fixed Bottom Toolbar:**
- `.ultraThinMaterial` background for liquid glass effect
- Prominent save button with glow shadow when enabled
- Keyboard shortcut (⌘S) for quick save
- Bottom padding prevents content occlusion

**Visual Enhancements:**
- Liquid glass styling throughout
- Material effects for depth
- Color-coded status badges
- Smooth animations

### Use Cases

- **Mobile developers**: Manage app translations locally
- **Web developers**: Edit website localization files
- **Translators**: Add new keys with screenshots for context
- **Teams**: Collaborate via Git with conflict resolution

---

## S3 Feature Config Editor Module

**Location:** `DHBootlegToolkit/Views/S3FeatureConfigEditor/`
**State Container:** `S3Store.swift`

Edit feature configuration stored in S3 JSON format with validation and batch operations.

### Features & Capabilities

- **Multi-environment support** (staging/production toggle)
- **Country-level configuration** editing with search/filter
- **JSON schema validation** prevents configuration errors
- **Field promotion** between environments
- **Bulk operations** apply changes across multiple countries simultaneously

### S3EditorConfiguration

**New Configuration System** (commit 4c51d03):
- Centralized S3 editor settings
- Improved field promotion logic
- Enhanced batch operation handling
- Schema validation configuration

**Configuration Location:**
```swift
// S3EditorConfiguration.swift
struct S3EditorConfiguration {
    let basePath: String
    let environments: [S3Environment]
    let validationSchema: JSONSchema
}
```

### Multi-Environment Support

**Environment Toggle:**
- Switch between staging and production
- Independent configuration files per environment
- Environment-specific validation rules

**Repository Structure:**
```
static.fd-api.com/s3root/feature-config/
├── staging/
│   ├── US/config.json
│   ├── UK/config.json
│   └── ...
└── production/
    ├── US/config.json
    ├── UK/config.json
    └── ...
```

### JSON Schema Validation

**Real-Time Validation:**
- Validates JSON against schema as you type
- Highlights validation errors inline
- Prevents invalid configurations from being saved

**Validation Features:**
- Type checking (string, number, boolean, array, object)
- Required fields enforcement
- Pattern matching for string values
- Enum value validation

**Error Display:**
- Clear error messages
- Field-level error indicators
- Schema violation details

### Batch Operations

**Apply Field Across Countries:**
- Select a field to apply
- Choose target countries
- Preview changes before applying
- Apply to all or selected countries

**Batch Update Features:**
- Multi-country selection
- Preview diff before applying
- Atomic operations (all or nothing)
- Rollback on validation failure

### Field Promotion

**Promote Between Environments:**
- Copy field values from staging to production
- Preview promotion changes
- Selective field promotion
- Validation before promotion

**Promotion Flow:**
1. Select field in staging
2. Choose promotion action
3. Preview changes in production
4. Confirm and apply

### Recent Improvements

**Nested Field Inspection Performance Fix** (commit 4c51d03):
- Resolved app hang when inspecting deeply nested JSON structures
- Optimized tree traversal for large configs
- Improved rendering performance for nested fields

**Bulk Delete Functionality Fix:**
- Fixed bulk delete operations for multiple config fields
- Proper cleanup of nested structures
- Validation after deletion

**S3JSONSerializer Enhancements:**
- Improved field operation serialization
- Better handling of complex data types
- Order-preserving serialization for clean diffs

### Enhanced UI

**JSONSearchBar:**
- Full-text search across configuration
- Field path search
- Highlight search results in tree
- Clear search with escape key

**JSONEditorToolbar:**
- Quick actions for common operations
- Search integration
- Environment switcher
- Validation status indicator

**New Sheets:**
- **S3InspectFieldSheet**: Enhanced nested field handling with performance improvements
- **S3ApplyFieldSheet**: Bulk operations across countries with preview
- **S3PromotionSheet**: Field promotion between environments

### Key Files

| File | Purpose |
|------|---------|
| `S3DetailView.swift` | Main S3 config editor with JSON tree |
| `S3BrowserView.swift` | Country/environment navigator |
| `JSONTreeView.swift` | Hierarchical JSON tree editor |
| `S3PromotionSheet.swift` | Promote configs between environments |
| `S3ApplyFieldSheet.swift` | Apply field across countries |
| `S3InspectFieldSheet.swift` | Inspect and edit nested fields |
| `S3EditorConfiguration.swift` | S3 editor configuration management |

### Use Cases

- **DevOps engineers**: Manage feature flags across countries
- **Product managers**: Toggle features for specific markets
- **QA teams**: Test configurations in staging before production
- **Operations**: Bulk update configs for rapid rollouts

---

## Logger Module

**Location:** `DHBootlegToolkit/Views/Logs/`
**State Container:** TBD

*Placeholder for future implementation.*

### Planned Features

- Operation logs and timing information
- Git operation history
- File system operation logs
- Performance metrics
- Error tracking

---

**Related Documentation:**
- [Architecture](ARCHITECTURE.md) - Technical architecture and patterns
- [Development Guide](DEVELOPMENT.md) - Building and contributing
- [UI Structure](UI_STRUCTURE.md) - View hierarchy and components
- [Git Integration](GIT_INTEGRATION.md) - Git workflow implementation
