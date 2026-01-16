#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [VERSION] [OPTIONS]

Package DHBootlegToolkit for Homebrew distribution.

Arguments:
  VERSION           Version number (e.g., 0.0.2, 1.0.0)
                    If not provided, will try to auto-detect from git tags
                    or use the default version from Info.plist

Options:
  --skip-build      Skip building and use existing .app in build directory
  --no-upload       Don't show GitHub upload instructions
  --cask-path PATH  Path to homebrew-tap cask file (default: auto-detect)
  --help, -h        Show this help message

Examples:
  $0 0.0.2                          # Package version 0.0.2
  $0 1.0.0 --skip-build             # Use existing build
  $0                                # Auto-detect version from git tags

EOF
    exit 0
}

# Parse arguments
VERSION=""
SKIP_BUILD=false
NO_UPLOAD=false
CASK_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_usage
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --no-upload)
            NO_UPLOAD=true
            shift
            ;;
        --cask-path)
            CASK_PATH="$2"
            shift 2
            ;;
        -*)
            print_error "Unknown option: $1"
            echo "Run '$0 --help' for usage information"
            exit 1
            ;;
        *)
            if [ -z "$VERSION" ]; then
                VERSION="$1"
            else
                print_error "Too many arguments"
                echo "Run '$0 --help' for usage information"
                exit 1
            fi
            shift
            ;;
    esac
done

# Navigate to project root
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

# Auto-detect version if not provided
if [ -z "$VERSION" ]; then
    print_info "No version specified, attempting to auto-detect..."

    # Try to get from git tags
    if git rev-parse --git-dir > /dev/null 2>&1; then
        LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
        if [ -n "$LATEST_TAG" ]; then
            VERSION="${LATEST_TAG#v}"  # Remove 'v' prefix if present
            print_info "Detected version from git tag: $VERSION"
        fi
    fi

    # If still no version, try Info.plist
    if [ -z "$VERSION" ]; then
        if [ -f "DHBootlegToolkit/Resources/Info.plist" ]; then
            VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "DHBootlegToolkit/Resources/Info.plist" 2>/dev/null || echo "")
            if [ -n "$VERSION" ]; then
                print_info "Detected version from Info.plist: $VERSION"
            fi
        fi
    fi

    # If still no version, use default
    if [ -z "$VERSION" ]; then
        VERSION="0.0.1"
        print_warning "Could not auto-detect version, using default: $VERSION"
    fi
fi

# Validate version format (basic semver check)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
    print_error "Invalid version format: $VERSION"
    echo "Version should be in semver format (e.g., 1.0.0, 0.0.2, 1.0.0-beta.1)"
    exit 1
fi

echo ""
print_info "📦 Packaging DHBootlegToolkit v$VERSION for Homebrew..."
echo ""

# Build the app
if [ "$SKIP_BUILD" = false ]; then
    # Clean previous builds
    print_info "🧹 Cleaning previous builds..."
    rm -rf build/
    rm -rf DHBootlegToolkit.xcodeproj

    # Generate Xcode project
    print_info "⚙️  Generating Xcode project..."
    if ! xcodegen generate; then
        print_error "Failed to generate Xcode project"
        exit 1
    fi

    # Build the app
    print_info "🔨 Building DHBootlegToolkit..."
    if ! xcodebuild \
      -scheme DHBootlegToolkit \
      -configuration Release \
      -derivedDataPath ./build \
      CODE_SIGN_IDENTITY="-" \
      CODE_SIGNING_REQUIRED=NO \
      CODE_SIGNING_ALLOWED=NO \
      clean build > build.log 2>&1; then
        print_error "Build failed! Check build.log for details"
        tail -20 build.log
        exit 1
    fi
    print_success "Build completed successfully"
else
    print_warning "Skipping build, using existing .app"
fi

# Find the .app bundle
APP_PATH=$(find build -name "DHBootlegToolkit.app" -type d 2>/dev/null | head -n 1)

if [ -z "$APP_PATH" ]; then
    print_error "Could not find DHBootlegToolkit.app"
    echo "Make sure the app has been built successfully"
    exit 1
fi

print_success "Found app at: $APP_PATH"

# Create release directory
mkdir -p releases

# Create a clean copy of the .app
print_info "📋 Copying app to release directory..."
rm -rf releases/DHBootlegToolkit.app
cp -R "$APP_PATH" releases/

# Create a zip file
print_info "🗜️  Creating zip archive..."
cd releases
rm -f "DHBootlegToolkit-$VERSION.zip"
if ! ditto -c -k --keepParent DHBootlegToolkit.app "DHBootlegToolkit-$VERSION.zip"; then
    print_error "Failed to create zip archive"
    exit 1
fi

# Calculate SHA256
SHA=$(shasum -a 256 "DHBootlegToolkit-$VERSION.zip" | awk '{print $1}')

# Get file size
SIZE=$(du -h "DHBootlegToolkit-$VERSION.zip" | awk '{print $1}')

echo ""
print_success "Package created successfully!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Release package: releases/DHBootlegToolkit-$VERSION.zip"
echo "📏 Size: $SIZE"
echo "🔐 SHA256: $SHA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Try to auto-detect cask path if not provided
if [ -z "$CASK_PATH" ]; then
    # Try to find homebrew-tap in parent directory
    POSSIBLE_PATHS=(
        "../homebrew-tap/Casks/dhbootlegtoolkit.rb"
        "../../homebrew-tap/Casks/dhbootlegtoolkit.rb"
        "$HOME/Repos/homebrew-tap/Casks/dhbootlegtoolkit.rb"
    )

    for path in "${POSSIBLE_PATHS[@]}"; do
        if [ -f "$path" ]; then
            CASK_PATH="$path"
            break
        fi
    done
fi

# Show next steps
if [ "$NO_UPLOAD" = false ]; then
    echo "📋 Next steps:"
    echo ""
    echo "1️⃣  Upload to GitHub releases:"
    echo ""
    echo "   # Using GitHub CLI:"
    if command -v gh &> /dev/null; then
        echo "   gh release create $VERSION \\"
        echo "     releases/DHBootlegToolkit-$VERSION.zip \\"
        echo "     --title \"DHBootlegToolkit v$VERSION\" \\"
        echo "     --notes \"Release v$VERSION\""
    else
        echo "   # Install GitHub CLI first: brew install gh"
        echo "   # Or upload manually at:"
        echo "   # https://github.com/lRoMYl/DHBootlegToolkit/releases/new"
    fi
    echo ""
    echo "2️⃣  Update the Cask:"
    echo ""
    if [ -n "$CASK_PATH" ] && [ -f "$CASK_PATH" ]; then
        print_info "Found cask at: $CASK_PATH"
        echo ""
        echo "   Update these lines in $CASK_PATH:"
    else
        echo "   Update these lines in homebrew-tap/Casks/dhbootlegtoolkit.rb:"
    fi
    echo ""
    echo "   version \"$VERSION\""
    echo "   sha256 \"$SHA\""
    echo ""
    echo "3️⃣  Commit and push:"
    echo ""
    echo "   cd /path/to/homebrew-tap"
    echo "   git add Casks/dhbootlegtoolkit.rb"
    echo "   git commit -m \"Update DHBootlegToolkit to v$VERSION\""
    echo "   git push origin master"
    echo ""
    echo "4️⃣  Test installation:"
    echo ""
    echo "   brew update"
    echo "   brew upgrade --cask dhbootlegtoolkit"
    echo ""
fi

# Offer to open GitHub releases page
if command -v open &> /dev/null && [ "$NO_UPLOAD" = false ]; then
    echo ""
    read -p "Open GitHub releases page in browser? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "https://github.com/lRoMYl/DHBootlegToolkit/releases/new?tag=$VERSION&title=DHBootlegToolkit%20v$VERSION"
    fi
fi

print_success "Done! 🎉"
