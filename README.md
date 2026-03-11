# Valuables
Valuables is a location-based lost-and-found platform designed to connect item owners with finders through an intuitive visual map interface. By anchoring discovery to specific locations, Valuables makes it easier to report found items, search for lost belongings, and coordinate safe item returns.
## Current Version
Last Release: 1.0.0
## Project Goals
- **Simplify the lost and found process:** Streamline the finding process by having everything in one place, ready to check in your hand.
- **Visual Discovery:** Replace text and image-heavy lists with an easy-to-use map-based interface, allowing users to instantly see what has been found in their vicinity.
- **Safe Retrieval:** Allow secure communication between an item finder and its original owner without exposing private details.

> [!note]
> For more detailed documentation and requirements, please refer to this document: [Living Document](https://docs.google.com/document/d/13QQbWXSVayHq30wGUSwdVvV63Vgm0ihH9rF6P2hdlEw/edit?usp=sharing)
## Core Features:
### Found Items Displayed on Map
The items each user find and report are displayed on the map as the location where they were found, allowing the owner to easily retrace their step and look for their lost items.
### Reporting Lost Items
When user lose something, they can report where it was last seem with its corresponding information. Our algorithm will provide a primitive match and notify the user in case there are similar items found in the area.
### Reporting Found Items
When user find something, they can easily pin it on the map by filling out a form, allowing all other users to search and enter in contact for claiming the item.
### Internal Chat
Clicking on the pin and starting a claim creates a chat between the users, allowing them to confirm ownership and agree on meeting for reclaiming their items.
### Pin Filtering
User can easily filter the items on the map based on time and category of the items, allowing them to more easily find their belongings.
### Match Notification
If the owner post a lost item report and someone else finds the item and made a found item post in the same area, the owner will receive a match notification for them to check if it is their item.

> [!note]
> Original Plan for Final Release
> **Major features:**
> - [x] P0: Display lost items on the map with a pin and a dedicated page with traditional cards
> - [x] P0: Ability to report something as lost through a form 
> - [x] P0: Ability to report something as found through a form
> - [x] P1: Allow users to chat with each other with an internally implemented texting feature that allows users to claim their items
> - [x] P1: Ability to filter lost items reported through expiry time (things expire after a month but users can go filter to certain dates for items reported within a time period)
> - [x] P1: Push notifications to users when an item is found in an area they reported
>
> **Stretch Goals:**
> - [ ] P2: User/owner verification system through an authentication tag
> - [ ] P2: Allow users to create a lost item bounty
> - [x] P2: See the listing by clicking on the pin, showing a small pop-up on the map
> - [ ] P2: Integrating with the local lost and found center

## Repository Layout
Developer's note: our main code lies in the 'developing' branch, while code for releases will be pulled in from 'developing' to 'main'.
```text
valuables/
├── .github/workflows # CI workflow
|
├── Status-Reports/ # Weekly progress updates
|
├── valuables-app/ # Main Flutter application source code
│   ├── android/ # Android-specific configuration
|   |
│   ├── ios/ # iOS-specific configuration
|   |
│   ├── lib/ # Main application logic (Dart code)
|   |   ├── chat/ # Files related to chat and messaging feature
|   |   ├── notifs/ # Files related to app notification handling
|   |   ├── claims/ # Files related to the in-app claiming feature
|   |   ├── screens/ # Individual screens (form, map, etc.--things that pop up from a button)
|   |   ├── pages/ # The actual pages from navigation (profile, history, map, etc.)
|   |
│   ├── test/ # Unit, widget, and integration tests
|   |   ├── screens/ # Specific tests for individual screens (form screen, map, etc.)
|   |
│   ├── pubspec.yaml # Project dependencies and settings
|   |
└── README.md # Top-level project overview
```
## Contributing
Please refer to our developer's guidelines for information about how to contribute: [Developer Guidelines](developers_guide.md)
## User's Manual
For information about how to use the app, please take a look at our user manual here: [User Manual](user_manual.md)
# AI Usage
- We use CoPilot for reviewing the Pull Requests, which are only approved upon human agreement with CoPilot's suggestions
- We also used Cursor, Gemini, and Claude for boilerplate code generation (e.g., making example widget code)
