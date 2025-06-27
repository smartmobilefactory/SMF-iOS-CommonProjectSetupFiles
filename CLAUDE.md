# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains Smart Mobile Factory's common project setup files for iOS development. It provides reusable components, scripts, and configurations that are shared across multiple iOS projects and frameworks through git submodules.

## Architecture

The repository is organized into several functional directories:

### SDK Helper Wrappers
- **LifetimeTracker/**: Memory leak detection helpers with base view controllers (wraps https://github.com/krzysztofzablocki/LifetimeTracker)

### Development Tools
- **SwiftLint/**: SwiftLint v0.59.1 configurations and execution scripts with portable binary
- **Xcode/**: Xcode version checking utilities

### Utilities
- **Plist2swift/**: Swift Package Manager tool that generates Swift code from plist files
- **Git/**: Git merge drivers and upmerge scripts for framework development
- **Strato/**: License management utilities

## Common Development Commands

### Main Setup Script
```bash
# For apps
"${SRCROOT}/Submodules/SMF-iOS-CommonProjectSetupFiles/setup-common-project-files.sh" --targettype "${PRODUCT_TYPE}"

# For SwiftUI apps
"${SRCROOT}/Submodules/SMF-iOS-CommonProjectSetupFiles/setup-common-project-files.sh" --targettype "${PRODUCT_TYPE}" --SwiftUI

# For framework unit tests
"${SRCROOT}/Submodules/SMF-iOS-CommonProjectSetupFiles/setup-common-project-files.sh" --targettype "com.apple.product-type.framework"
```

### Individual Tool Commands
```bash
# SwiftLint only
./SwiftLint/copy-and-run-swiftlint-config.sh

# Xcode version check
./Xcode/check-xcode-version.swift

# Plist2Swift code generation
./Plist2swift/Plist2swift -e EnumName -o output.swift input1.plist input2.plist
```

### Testing Plist2swift
```bash
cd Plist2swift
swift test
```

## Setup Integration

The main setup script handles:
- Copying and merging SwiftLint configurations (`.swiftlint.yml` and `.project-swiftlint.yml`)
- Running SwiftLint with portable binary or system installation
- Copying GitHub PR templates based on project type
- Optional Xcode version validation

## Key Configuration Files

- **swiftlint.yml**: Base SwiftLint v0.59.1 configuration
- **swiftlint+frameworks.yml**: Additional rules for frameworks
- **swiftlint+swiftUI.yml**: SwiftUI-specific rules
- **project-swiftlint.yml**: Template for project-specific excluded paths

## SDK Integration Pattern

The LifetimeTracker SDK helper follows this pattern:
1. Provides base view controllers that integrate with LifetimeTracker when available
2. Uses conditional compilation (`#if canImport(LifetimeTracker)`) to support projects with or without the dependency
3. Offers simple setup methods with sensible defaults
4. Handles debug vs release build configurations

## File Generation

- `.swiftlint.yml` is automatically copied to project root
- Add this file to `.gitignore` as it is generated
- Project-specific configurations use `.project-swiftlint.yml` template

## Framework Development

For framework projects:
- Unit test targets get separate SwiftLint configuration
- Special PR templates are used for breaking changes
- Git merge drivers help with version management during upmerges