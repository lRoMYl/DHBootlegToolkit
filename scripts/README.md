# Homebrew Packaging Scripts

## package-for-homebrew.sh

A comprehensive script for packaging DHBootlegToolkit for Homebrew distribution.

### Features

- ✅ Dynamic version input with validation
- ✅ Auto-detection from git tags or Info.plist
- ✅ Automatic build or skip-build option
- ✅ SHA256 hash calculation
- ✅ Auto-detect homebrew-tap cask location
- ✅ Colored, user-friendly output
- ✅ Interactive GitHub release page opener
- ✅ Comprehensive error handling

### Usage

#### Basic Usage

```bash
# Package a specific version (builds from scratch)
./scripts/package-for-homebrew.sh 0.0.2

# Auto-detect version from git tags
./scripts/package-for-homebrew.sh

# Use existing build (faster for testing)
./scripts/package-for-homebrew.sh 0.0.2 --skip-build
```

#### Advanced Options

```bash
# Skip build and don't show upload instructions
./scripts/package-for-homebrew.sh 1.0.0 --skip-build --no-upload

# Specify custom cask path
./scripts/package-for-homebrew.sh 1.0.0 --cask-path ~/custom/path/cask.rb

# Show help
./scripts/package-for-homebrew.sh --help
```

### Version Auto-Detection

The script will automatically detect the version from:

1. **Git tags** - Uses the latest git tag (removes 'v' prefix if present)
2. **Info.plist** - Reads `CFBundleShortVersionString` from `DHBootlegToolkit/Resources/Info.plist`
3. **Default fallback** - Uses `0.0.1` if nothing is found

### Complete Workflow

#### 1. Package the Release

```bash
cd /Users/romy.cheah/Repos/DHBootlegToolkit
./scripts/package-for-homebrew.sh 0.0.2
```

Output:
```
📦 Release package: releases/DHBootlegToolkit-0.0.2.zip
🔐 SHA256: abc123...
```

#### 2. Upload to GitHub

**Option A: Using GitHub CLI (recommended)**
```bash
gh release create 0.0.2 \
  releases/DHBootlegToolkit-0.0.2.zip \
  --title "DHBootlegToolkit v0.0.2" \
  --notes "Release notes here"
```

**Option B: Web Interface**
- The script will offer to open the GitHub releases page
- Manually upload the zip file

#### 3. Update the Cask

```bash
cd /Users/romy.cheah/Repos/homebrew-tap

# Edit Casks/dhbootlegtoolkit.rb
# Update version and sha256 with values from script output

git add Casks/dhbootlegtoolkit.rb
git commit -m "Update DHBootlegToolkit to v0.0.2"
git push origin master
```

#### 4. Test Installation

```bash
brew update
brew upgrade --cask dhbootlegtoolkit
```

### Tips

- **Use `--skip-build`** when you've already built the app and just need to repackage
- **Version format**: Must be valid semver (e.g., `1.0.0`, `0.0.2`, `1.0.0-beta.1`)
- **Release directory**: All packages are saved to `releases/` for easy management
- **Build logs**: If build fails, check `build.log` for detailed error messages

### Troubleshooting

**Problem**: "Could not find DHBootlegToolkit.app"
- **Solution**: Make sure the app builds successfully or use an existing build with `--skip-build`

**Problem**: "Invalid version format"
- **Solution**: Use semver format: `MAJOR.MINOR.PATCH` (e.g., 1.0.0)

**Problem**: Build fails
- **Solution**: Check `build.log` for details. Ensure all dependencies are installed

### File Locations

- **Script**: `scripts/package-for-homebrew.sh`
- **Output**: `releases/DHBootlegToolkit-VERSION.zip`
- **Build logs**: `build.log` (created in project root)
- **Cask**: `../homebrew-tap/Casks/dhbootlegtoolkit.rb` (auto-detected)
