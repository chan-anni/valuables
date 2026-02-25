# Introduction
Valuables is a lost and found app platform that connects item owners and finders through a visual map interface. Through centering discovery around location, the app makes it easier for users to report found items, search for lost belongings, and coordinate safe retrieval. Now you can find your items without physically retracing your steps, or submit a lost item report when there is not trustworthy central desk!

# How To Install The Software
## Android
The app will be available in Apk for download. It will require at least **Android 5.0**
## iOS
Through Appstore once it is launched
The app requires **iOS 15 or later**

# How To Run The Software
The user can just open the app and it will be functional for use as long as they have the versions required in [How to install the Software](#how-to-install-the-software).

# How To Use The Software

The software is still in development, all the incomplete features will be marked with **IP (In Progress)**

### Navigation Bar
Use the navigation bar to redirect to different pages within the application:
  - [Landing/Map Page](#landing/map-page)
  - [Listing Page](#listing-page)
  - [Create Report Page](#create-report-page)
  - [Messages Page](#messages-page-(IP))
  - [Profile page](#profile/account-page)
  
### Landing/Map Page
![Map page picture](Map.jpg)
In the map page, the user can navigate around and see the pins which represent the locations of where the corresponding item was found.

Pins: Each pin is am item reported by another user, clicking on it reveals more information about the item.

Item View: The item view shows its title, a description of what the item is, and a picture that allows the user to identify the object.

Search Bar (IP): Search bar allows users to search for items based on their title and description.

### Listing Page
![Listing page picture](Listing.jpg)
The listing page is another way to see what users' have found. It would also show users' lost item report, allowing other users to acknowledge other lost items to possibly lookout for. Users can scroll through all the active items in order to find what they may be looking for.

Expanded Item View (IP): The item view shows a slightly longer description of the item that is not visible in the smaller view.

### Create Report Page
![Report selection picture](Report1.jpg)
![Report page picture](Report2.jpg)
When a user clicks the round plus button the navigation bar, they will be guided to choose what kind of report they would like to fill out. After deciding on reporting a lost item or a found item, they will be asked to fill out information in regards to the item like a description of the item and a picture of the item (required for found items) that other users will be able to see when they click on a listing. Additionally, they will be asked to include the location of the item.

### Messages Page (IP)
![Inbox page picture](Chat1.jpg)
![Chat page picture](Chat2.jpg)
When a user decides that they would like to claim an item, they will be directed to chat with the user that currently has the item. Here, users can determine if the item truly belongs to whoever is claiming it. Users can also discuss what their future plans are to get the item back to the rightful owner. Users can click on the chat to continue chatting with other users they are in contact with.

### Profile/Account Page
![Profile page picture](Profile.jpg)
Here, users can edit their profile picture, their profile name and information in relation to their account. If they are not signed-in, they will be able to sign-in using Google Authentication or sign-out if necessary. They will also be able to scroll through their current uploaded listings, both lost and found, as well as check for any potential matches for their lost items.

History & Activity Page (IP): After clicking on the icon where users can check their past history, they should be able to see past reports for found items and lost items that have been claimed/unclaimed. They should also be able to see any past potential matches between an item they have lost and other uploaded items.

# How to report a bug
User can access the [GitHub repository](https://github.com/chan-anni/valuables/issues) and create a issue to indicate a specific bug.
Details that should be included in the report:
- Enter a **clear unique summary**.
- **Steps to reproduce a bug, expected results** and **actual results**
    - If you can reproduce occasionally, but not after following specific steps, you must provide additional information for the bug to be useful.
    - If you can't reproduce the problem, there's probably no use in reporting it, unless you provide unique information about its occurrence.
	- Make sure your software is up to date. Ideally, test an in-development version to see whether your bug has already been fixed.
	- If the bug seems egregious (i.e. obviously affecting a large portion of users), there's probably something unusual about your setup that's a necessary part of the steps to reproduce the bug. You have much better chances of figuring it out than a developer who does not have access to your system.
- Provide additional information, especially if you can't reproduce the bug in a new profile; and/or by reporting a **crash**, **memory usage**, **performance**, **regression** bug; or if the problem is with a specific web site.

## Known Bugs
We have some bugs that are in our GitHub "Issues" tab for the things that are still in progress.

- User can create multiple chats if they start a claim on the same item