#  Valuables 26/02/11

## High Level Goal
- Develop front end to backend map feature which allows user to see lost items as pins on the map, and report lost and found items for Beta Release.

## Original Goals
- Finish map requirements (adding listings show up) (~2 days)
- Write some unit tests + continuous integration tests for forms (4 days)
- Conenct data base with app (1 day)
- get map API to work with ios

## Progress and Issues
- The map API for ios works now! Fixed some keys and enviornments so that we could configure it.
- Basic unit tests are written and CI is set up but only cover widget/UI navigation. Tests that integrate into some sort of backend don't work and probably need to reconfigure some of the file setups.
- Supabase is connected, but image storages is not routed yet. The form needs to take images but getting it into the background hasn't worked yet.
- Basic MVP of lost and found form is implemented.

## Goals for Next Week
- Fix/add the image storage system links and map connection to the form (~2/3 days)
- Begin in app chatting feature (-6 days)
- Clean up UI for beta release by giving everything labels and finalizing formatting (~4 days)
- Write 5 more integration tests, which will include having inputted items being put into a backend (2 days)

