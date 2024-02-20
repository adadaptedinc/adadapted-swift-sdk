# AdAdapted iOS SDK

The iOS SDK integrates AdAdapted services with partner iOS apps via Swift Package Manager.

Development is done using XCode. Updating the public facing API should be done with care since those changes will require more than a drop-in update from partners.

Documentation for integrating the SDK with an App can be found at [https://docs.adadapted.com/#/docs/ios-getting-started](https://docs.adadapted.com/#/docs/ios-getting-started)

A valid API key is required to be able to run the SDK which can be dropped into one of the testing application's AppDelegate initialization chains.

### Prerequisites

* XCode with recent updates installed

### Installing

Step 1. Import the swift package to your app code.

Step 2. Import the dependency (based on latest release version)

    import adadapted_swift_sdk

## Running the tests

Unit tests can be run within the IDE. There are also two test apps that can run basic implementation and verification of features. [SwiftUIAdapted](https://github.com/adadaptedinc/swiftui-adapted) and [SwiftAdapted](https://github.com/adadaptedinc/swift-adapted). 

## Deployment

To create a new release, it must be named and tagged as only the version number (i.e. 1.0.0). Once the new release is published, it will be available through SPM shortly afterward.

## Versioning

SDK version is maintained on the LIBRARY_VERSION parameter in the Config class. Each new rounds of updates should be incremented manually here based on the significance of the update.

The value is updated from right to left based on this loose criteria:
* Bug fixes and minor tweaks
* Small feature additions or refactor
* Major feature additions or refactor


## Acknowledgments

* [README Template](https://gist.github.com/PurpleBooth/109311bb0361f32d87a2)
