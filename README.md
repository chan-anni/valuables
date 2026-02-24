# Valuables

Valuables is a location-based lost and found platform designed to connect item owners with finders through an intuitive visual map interface. By anchoring discovery to specific locations, Valuables makes it easier to report found items, search for lost belongings, and coordinate safe item returns.

## Project Goals
- **Simplify the lost and found process:** Streamline the finding process by having everything in one place, ready to check in your hand.
- **Visual Discovery:** Replace text and image-heavy lists with an easy-to-use map-based interface, allowing users to instantly see what has been found in their vicinity.
- **Safe Retrieval:** Allow secure communication between an item finder and its original owner without exposing private details.

For more detailed documentation and requirements, please refer to this document: [Living Document](https://docs.google.com/document/d/13QQbWXSVayHq30wGUSwdVvV63Vgm0ihH9rF6P2hdlEw/edit?usp=sharing)

## Repository Layout
Developer's note: our main code lies in the 'developing' branch, while code for releases will be pulled in from 'developing' to 'main'.
```text
valuables/
├── .github/workflows        # CI workflow 
├── Status-Reports/          # Weekly progress updates
│
├── valuables-app/           # Main Flutter application source code
│   ├── android/             # Android-specific configuration
│   ├── ios/                 # iOS-specific configuration
│   ├── lib/                 # Main application logic (Dart code)
|   |    ├── screens/         # Individual screens (form, map, etc.)
│   ├── test/                # Unit and widget tests
|   |    ├── screens/         # Specific tests for individual screens (form screen, map, etc.)
│   ├── web/                 # Web build configuration
│   ├── macos/               # macOS build configuration
│   ├── pubspec.yaml         # Project dependencies and settings            
│
└── README.md                # Top-level project overview

```
## Contributing
Please refer to our developer's guidelines for information about how to contribute: [Developer Guidelines](developer_guide.md)

## User's Manual
For information about how to use the app, please take a look at our user manual here: [User Manual](user_manual.md)
## Use Case

As of the Beta version, the current app can perform the core feature of submitting a 'found item' claim. 
The use case would be the following:

**User Goal**: A finder wants to quickly report someone's lost accessory that they found so the owner can locate it on the map.

**Success Conditions**: The item is logged into the database, and it shows on the map interface.

**Step by Step Flow**
1. User clicks on the 'Report Item' form and clicks on the 'Found' item type.
2. System loads up the form.
3. User fills out the form with a title, corresponding category, and chooses a date for when they found the item. The user then clicks the location button.
4. System loads up a map screen where the user can type in an address in the search bar, use their current location, or click on the map to place a pin.
5. User clicks on a location and then confirms the location.
6. System loads back to the form page with the location now chosen.
7. User clicks on the upload image button and uploads an image.
8. User clicks submit to the form.
9. System confirms and takes the user back to the home page. Item information is loaded into the backend database. An item marker appears on the map page.
