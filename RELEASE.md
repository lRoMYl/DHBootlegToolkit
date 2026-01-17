# Release Process

This document describes how to create releases for DHBootlegToolkit. The process is fully automated via GitHub Actions - you just create a release via the GitHub UI, and everything else happens automatically.

## Quick Start

**To create a new release:**

1. Go to [GitHub Releases](https://github.com/lRoMYl/DHBootlegToolkit/releases/new)
2. Enter a tag (e.g., `0.0.3`)
3. Enter a title (e.g., `Version 0.0.3`)
4. Write release notes describing the changes
5. Click "Publish release"
6. Done! Automation takes over from here.

The automation will:
- Build the app with the version from your tag
- Create and upload a zip file to the release
- Commit the version back to the `main` branch
- Create a PR in the Homebrew tap repository

## How It Works

### The Automated Workflow

```
You create release (30 seconds)
        ↓
GitHub Actions builds app (5 minutes)
        ↓
Zip uploaded to your release
        ↓
Version synced to main branch
        ↓
Homebrew tap updated via PR
        ↓
You merge Homebrew PR (30 seconds)
        ↓
Users can upgrade via Homebrew
```

### What Gets Stored Where

| Location | What's Stored | Purpose |
|----------|---------------|---------|
| **Git Repository** | Source code with `MARKETING_VERSION` in `project.yml` | Version control and development |
| **GitHub Release** | `DHBootlegToolkit-{version}.zip` file | Binary distribution |
| **Homebrew Tap** | Cask formula with version and SHA256 | User installation via `brew` |

**Important:** Build artifacts (`.app` bundles, `.zip` files) are NOT stored in git - only in GitHub Releases.

## Complete Release Flow

### What You Do (1 minute)

1. **Create release via GitHub UI:**
   - Navigate to: https://github.com/lRoMYl/DHBootlegToolkit/releases/new
   - Tag: `0.0.3` (or whatever version you're releasing)
   - Title: `Version 0.0.3`
   - Release notes: Describe what changed
   - Click "Publish release"

2. **Watch automation (optional):**
   - Visit [Actions tab](https://github.com/lRoMYl/DHBootlegToolkit/actions) to monitor progress
   - Wait ~5-10 minutes for workflow to complete

3. **Merge Homebrew PR:**
   - Check your [homebrew-tap repository](https://github.com/lRoMYl/homebrew-tap/pulls)
   - Review the auto-generated PR
   - Merge it

### What GitHub Actions Does (automatic, ~5-10 minutes)

**Build Job:**
- Checks out your code
- Extracts version from the tag (e.g., `0.0.3`)
- Installs XcodeGen and generates Xcode project
- Builds the app with `MARKETING_VERSION=0.0.3`
- Creates `DHBootlegToolkit-0.0.3.zip`
- Calculates SHA256 hash
- Uploads zip to your GitHub release

**Sync Version Job:**
- Updates `project.yml` with `MARKETING_VERSION: 0.0.3`
- Commits to main branch with message: `chore: bump version to 0.0.3 [skip ci]`
- Pushes the commit (the `[skip ci]` tag prevents re-triggering the workflow)

**Homebrew Update Job:**
- Forks/updates your homebrew-tap repository
- Updates `Casks/dhbootlegtoolkit.rb`:
  - `version "0.0.3"`
  - `sha256 "new-hash..."`
  - Downloads URL pointing to the new release
- Creates a PR for you to review

## Required Configuration

This is a **one-time setup** that's already done for this repository. If you're setting up automation for a new repository, you'll need:

### GitHub Repository Settings

1. **Personal Access Token (HOMEBREW_TAP_TOKEN):**

   This token allows the workflow to update your homebrew-tap repository automatically.

   **Option A: Fine-Grained Token (Recommended)**
   - More secure - can be limited to just the homebrew-tap repository
   - Steps to create:
     1. Go to: Settings → Developer settings → Personal access tokens → Fine-grained tokens
     2. Click "Generate new token"
     3. Repository access: "Only select repositories" → `lRoMYl/homebrew-tap`
     4. Permissions → Repository permissions → Contents: "Read and write"
     5. Generate and copy the token

   **Option B: Classic Token**
   - Simpler but has access to ALL your repositories
   - Steps to create:
     1. Go to: Settings → Developer settings → Personal access tokens → Tokens (classic)
     2. Click "Generate new token (classic)"
     3. Scopes: Select `repo` (or `public_repo` if tap is public)
     4. Generate and copy the token

   **Add to repository:**
   1. Go to: https://github.com/lRoMYl/DHBootlegToolkit/settings/secrets/actions
   2. Click "New repository secret"
   3. Name: `HOMEBREW_TAP_TOKEN`
   4. Value: Paste your token
   5. Click "Add secret"

2. **Workflow Permissions:**
   - Repository Settings → Actions → General → Workflow permissions
   - Set to: "Read and write permissions"
   - This allows the workflow to commit version changes back to main

### Version Management

The app uses Xcode's build settings for version management:

- **MARKETING_VERSION** in `project.yml` - The version string (e.g., `0.0.3`)
- **CURRENT_PROJECT_VERSION** in `project.yml` - Build number (auto-incremented by workflow)
- **Info.plist** uses `$(MARKETING_VERSION)` and `$(CURRENT_PROJECT_VERSION)` variable substitution

**Key points:**
- Git tags are the source of truth for versions
- Workflow extracts version from tag and builds with it
- After building, workflow commits updated version back to `project.yml`
- This keeps the repository synchronized with releases

## Verification Checklist

After creating a release, verify:

- [ ] GitHub Release shows the tag and zip file
- [ ] Zip file downloads and extracts correctly
- [ ] App launches and shows correct version
- [ ] Main branch has new commit: `chore: bump version to {version} [skip ci]`
- [ ] `project.yml` has `MARKETING_VERSION: {version}`
- [ ] Homebrew PR created in homebrew-tap repository
- [ ] Homebrew PR has correct version and SHA256
- [ ] After merging PR, `brew upgrade --cask dhbootlegtoolkit` works

**To check the app version:**
```bash
# After downloading and extracting the release zip
defaults read ~/Downloads/DHBootlegToolkit.app/Contents/Info CFBundleShortVersionString
# Should output: 0.0.3 (or whatever version you released)
```

## Manual Fallback

If the automation fails or you need to create a release manually, you can use the legacy script:

```bash
# Build and package manually
./scripts/package-for-homebrew.sh 0.0.3

# Follow the on-screen instructions to:
# 1. Upload to GitHub releases
# 2. Update Homebrew cask manually
```

The manual script is kept as a backup and for local testing.

## Troubleshooting

### Workflow Failed

**Problem:** GitHub Actions workflow shows a failure.

**Solution:**
1. Click on the failed workflow in the [Actions tab](https://github.com/lRoMYl/DHBootlegToolkit/actions)
2. Read the error logs to identify the issue
3. Fix the problem (e.g., build error, missing secret)
4. Re-run the workflow from the Actions UI, or delete and recreate the release

### Version Not Updated in Repository

**Problem:** `project.yml` still shows old version after release.

**Solution:**
1. Check the [workflow run](https://github.com/lRoMYl/DHBootlegToolkit/actions) - did the "Sync Version" job succeed?
2. Verify workflow permissions are set to "Read and write"
3. If needed, manually update `project.yml` and commit

### Homebrew PR Not Created

**Problem:** No PR appeared in homebrew-tap repository.

**Solution:**
1. Check if `HOMEBREW_TAP_TOKEN` secret exists and is valid
2. Check workflow logs for the "Update Homebrew" job
3. If automated update failed, manually update the cask:
   - Edit `Casks/dhbootlegtoolkit.rb` in homebrew-tap
   - Update `version` and `sha256` (from workflow output)
   - Commit and push

### Token Authentication Failed

**Problem:** Workflow fails with "Input required and not supplied: token" or authentication errors.

**Solution:**
1. **Verify secret exists:**
   - Visit: https://github.com/lRoMYl/DHBootlegToolkit/settings/secrets/actions
   - Check that `HOMEBREW_TAP_TOKEN` is listed

2. **Check token permissions:**
   - Go to: https://github.com/settings/tokens
   - Find your token (or create a new one if expired)
   - For fine-grained tokens: Verify it has access to `lRoMYl/homebrew-tap` with "Contents: Read and write"
   - For classic tokens: Verify it has the `repo` scope checked

3. **Token expired:**
   - Fine-grained and classic tokens have expiration dates
   - If expired, generate a new token with the same scopes
   - Update the `HOMEBREW_TAP_TOKEN` secret with the new value

4. **Test the setup:**
   - Create a test release (e.g., `0.0.3-test`) to verify the workflow runs successfully
   - Check the "Update Homebrew Cask" job logs for any authentication errors

### Build Succeeded but Zip Invalid

**Problem:** Zip file doesn't contain a working app.

**Solution:**
1. Download the zip from the release
2. Extract and test locally
3. Check build logs for warnings or errors
4. If the app is broken, delete the release and fix the build

## Testing Releases

### Test with Pre-release Tags

Before creating a production release, test with a pre-release tag:

```bash
git tag 0.0.3-test
git push --tags
```

This triggers the workflow without publishing to users. Check:
- App builds successfully
- Version is correct in the built app
- Zip file is created and valid
- Version syncs back to repository

### Local Testing

Test the build locally before releasing:

```bash
# Generate project
xcodegen generate

# Build with version override
xcodebuild -scheme DHBootlegToolkit -configuration Release \
  MARKETING_VERSION=0.0.3-local \
  clean build

# Verify version
defaults read build/Build/Products/Release/DHBootlegToolkit.app/Contents/Info CFBundleShortVersionString
```

## Alternative: Manual Tag Push

Instead of using the GitHub UI, you can create releases by pushing tags:

```bash
# Create and push tag
git tag 0.0.3
git push --tags

# Workflow automatically creates the release
```

This triggers the same automation, but the release will be auto-created with a default message. For better release notes, prefer the GitHub UI method.

## Links

- [GitHub Releases](https://github.com/lRoMYl/DHBootlegToolkit/releases)
- [GitHub Actions Workflows](https://github.com/lRoMYl/DHBootlegToolkit/actions)
- [Homebrew Tap Repository](https://github.com/lRoMYl/homebrew-tap)
- [Workflow File](.github/workflows/release.yml)

## Version History

The version history is tracked in two places:
- **Git tags** - Each release has a corresponding git tag
- **GitHub Releases** - User-facing release notes and download links

To see all releases: https://github.com/lRoMYl/DHBootlegToolkit/releases

## For Users

Users install and update via Homebrew:

```bash
# Initial installation
brew tap lromyl/tap
brew install --cask dhbootlegtoolkit

# Upgrade to latest version
brew update
brew upgrade --cask dhbootlegtoolkit
```

The automation ensures users can always upgrade to the latest version via Homebrew.
