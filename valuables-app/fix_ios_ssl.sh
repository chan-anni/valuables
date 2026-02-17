#!/bin/bash

echo "=== Starting CocoaPods SSL fix and Flutter iOS setup ==="

# Ensure script stops on any error
set -e

PROJECT_DIR=$(pwd)
IOS_DIR="$PROJECT_DIR/ios"

echo "Project directory: $PROJECT_DIR"

# Step 1: Reinstall CocoaPods via Homebrew
echo "--- Reinstalling CocoaPods via Homebrew ---"
brew uninstall --ignore-dependencies cocoapods || true
brew install cocoapods

# Step 2: Remove old CocoaPods caches and repos
echo "--- Removing old CocoaPods caches and repos ---"
rm -rf ~/Library/Caches/CocoaPods
rm -rf ~/.cocoapods/repos

# Step 3: Setup CocoaPods CDN
echo "--- Setting up CocoaPods CDN ---"
pod setup

# Step 4: Clean iOS pods and reinstall
echo "--- Cleaning iOS Pods and reinstalling ---"
cd "$IOS_DIR"
rm -rf Pods Podfile.lock
pod install --repo-update

# Step 5: Flutter clean and pub get
echo "--- Running Flutter clean and pub get ---"
cd "$PROJECT_DIR"
flutter clean
flutter pub get

echo "=== Finished CocoaPods SSL fix and Flutter iOS setup ==="
echo "You can now run your app with: flutter run -d <device-id>"

