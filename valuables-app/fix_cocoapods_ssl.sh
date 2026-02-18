#!/bin/bash
set -e

echo "🔹 Updating Homebrew and installing dependencies..."
brew update
brew upgrade
brew install openssl@3 ca-certificates ruby
brew link --force openssl@3
brew link --force ca-certificates

echo "🔹 Setting environment variables for Ruby / CocoaPods..."
export SSL_CERT_FILE=$(brew --prefix ca-certificates)/etc/ca-certificates/cert.pem
export SSL_CERT_DIR=$(brew --prefix ca-certificates)/etc/ca-certificates
export PATH="$(brew --prefix ruby)/bin:$PATH"

echo "🔹 Verifying Ruby sees OpenSSL..."
ruby -ropenssl -e 'puts "OpenSSL cert file: #{OpenSSL::X509::DEFAULT_CERT_FILE}"'

echo "🔹 Removing old CocoaPods repos..."
rm -rf ~/.cocoapods/repos || true

echo "🔹 Reinstalling CocoaPods gem..."
sudo gem uninstall -aIx cocoapods || true
sudo gem install cocoapods -- --with-openssl-dir=$(brew --prefix openssl@3)

echo "🔹 Updating CocoaPods repo and installing pods..."
cd ios
pod install --repo-update

echo "🔹 Cleaning Flutter project and running..."
cd ..
flutter clean
flutter pub get
echo "✅ You can now run your app with: flutter run -d <device>"

