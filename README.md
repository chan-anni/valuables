# Valuables

Valuables is a location-based lost and found platform designed to connect item owners with finders through an intuitive visual map interface. By anchoring discovery to specific locations, Valuables makes it easier to report found items, search for lost belongings, and coordinate safe item returns.

## Project Goals
- **Simplify the lost and found process:** Streamline the finding process by having everything in one place, ready to check in your hand.
- **Visual Discovery:** Replace text and image-heavy lists with an easy-to-use map-based interface, allowing users to instantly see what has been found in their vicinity.
- **Safe Retrieval:** Allow secure communication between an item finder and its original owner without exposing private details.

For more detailed documentation and requirements, please refer to this document: [Living Document](https://docs.google.com/document/d/13QQbWXSVayHq30wGUSwdVvV63Vgm0ihH9rF6P2hdlEw/edit?usp=sharing)

## Repository Layout

```text
valuables/
├── Status-Reports/          # Weekly progress updates
│
├── valuables-app/           # Main Flutter application source code
│   ├── android/             # Android-specific configuration
│   ├── ios/                 # iOS-specific configuration
│   ├── lib/                 # Main application logic (Dart code)
│   ├── test/                # Unit and widget tests
│   ├── web/                 # Web build configuration
│   ├── macos/               # macOS build configuration
│   ├── pubspec.yaml         # Project dependencies and settings            
│
└── README.md                # Top-level project overview
