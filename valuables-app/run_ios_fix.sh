#!/bin/bash
set -e  # Stop on any error

echo "=== Fixing CocoaPods SSL and running Flutter app ==="

# 1️⃣ Ensure we're in the project root
PROJECT_DIR="$(pwd)"
IOS_DIR="$PROJECT_DIR/ios"
echo "Project directory: $PROJECT_DIR"

# 2️⃣ Set CocoaPods to use HTTP (avoids SSL errors)
echo "Removing old CocoaPods trunk repo..."
pod repo remove trunk || true

echo "Adding trunk repo over HTTP..."
pod repo add trunk http://cdn.cocoapods.org/ || true

# 3️⃣ Export Homebrew certificates for CocoaPods
export SSL_CERT_FILE=$(brew --prefix ca-certificates)/etc/ca-certificates/cert.pem
export SSL_CERT_DIR=$(brew --prefix ca-certificates)/etc/ca-certificates
echo "Exported SSL_CERT_FILE and SSL_CERT_DIR"

# 4️⃣ Go

