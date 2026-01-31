# DHBootlegToolkit

Your friendly neighborhood unofficial toolkit with the assistance of Claude Code to *hopefully* make your mundane chores just a bit more delightful ✨ or less frustrating 😫.

Disclaimer: Use it at your own risks, no warranty provided 🫣👉👈

[![Platform](https://img.shields.io/badge/platform-macOS%2026.0%2B-blue)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/swift-6.0-orange)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## Key Features

<table>
  <tr>
    <td width="50%">
      <img src="images/Market%20Watcher.png" alt="Market Watch" />
      <p align="center"><strong>Market Watch</strong><br/>Need more *goodwill* LTIP topup to cover the differences 😭</p>
    </td>
    <td width="50%">
      <img src="images/Not%20WebtranslateIt%20Editor.png" alt="Localization Editor" />
      <p align="center"><strong>Not WebTranslateIt Editor 🤡</strong><br/>Goodbye WTI, a tribute to you. Hopefully, we will get a *real* localization platform soon</p>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="images/S3%20Feature%20Config%20Editor.png" alt="S3 Config Editor" />
      <p align="center"><strong>S3 Feature Config Editor</strong><br/>Wrangle S3 configs without manually editing JSON like a caveman 🙄</p>
    </td>
    <td width="50%">
      <img src="images/S3%20Feature%20Config%20Editor%20-%20Batch%20Update.png" alt="S3 Batch Update" />
      <p align="center"><strong>Batch Updates</strong><br/>Apply changes or check values across multiple countries simultaneously</p>
    </td>
  </tr>
  <tr>
    <td colspan="2" align="center">
      <img src="images/S3%20Feature%20Config%20%20Schema%20Validation.png" alt="Schema Validation" width="70%" />
      <p align="center"><strong>JSON Schema Validation</strong><br/>We have a  schema but no visual feedback for it, we're not in 1950 😒</p>
    </td>
  </tr>
</table>

---

## Installation

### Install in One Command

```bash
brew install --cask lromyl/tap/dhbootlegtoolkit
```

**Alternative (two-step process):**

```bash
# Add the tap
brew tap lromyl/tap

# Install the cask
brew install --cask dhbootlegtoolkit
```

**Manual Updates:**

```bash
brew upgrade --cask dhbootlegtoolkit
```

### Building from Source

**Prerequisites:**
- macOS 26.0+ (deployment target)
- Xcode 16+ with Swift 6.0
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) for project generation
- GitHub CLI (`gh`) for PR creation (optional)

**Quick Build:**

```bash
# Clone repository
git clone https://github.com/lRoMYl/DHBootlegToolkit.git
cd DHBootlegToolkit

# Generate Xcode project
xcodegen

# Open in Xcode
open DHBootlegToolkit.xcodeproj

# Or build from command line
xcodebuild -scheme DHBootlegToolkit build
```

For detailed build instructions, troubleshooting, and development setup, see [Development Guide](docs/DEVELOPMENT.md).

---

### Editors

- **Localization Editor**: Edit translation keys, add new keys with wizard, manage images
- **S3 Config Editor**: Edit configs, apply fields in bulk, promote between environments

### Commit & Publish

Use the integrated Git bar (bottom of window) to:
1. Create a new branch
2. Commit changes with auto-generated messages
3. Push to remote
4. Open a pull request via GitHub CLI

For detailed module usage, see [Module Documentation](docs/MODULES.md).

---

## Documentation

Comprehensive documentation is available in the `docs/` directory:

- **[Architecture](docs/ARCHITECTURE.md)** - Technical architecture, packages, workers, and design patterns
- **[Module Documentation](docs/MODULES.md)** - Detailed guides for each module (Market Watch, Localization Editor, S3 Config Editor)
- **[Development Guide](docs/DEVELOPMENT.md)** - Building from source, code style, testing, and contributing
- **[UI Structure](docs/UI_STRUCTURE.md)** - View hierarchy, component architecture, and window integration
- **[Git Integration](docs/GIT_INTEGRATION.md)** - Git workflow implementation and external change detection
- **[State Management](docs/STATE_MANAGEMENT.md)** - State machines, concurrency patterns, and data flow
- **[Release Process](RELEASE.md)** - Creating releases (for maintainers)

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
