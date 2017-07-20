# AVFoundationSimplePlayer-iOS: Using AVFoundation to Play Media

Demonstrates how to create a simple movie playback app using only the AVPlayer and AVPlayerLayer classes from AVFoundation (not AVKit). You'll see how to load a movie file as an AVAsset and then how to implement various functionality including play, pause, fast forward, rewind, time slider updating, and scrubbing.

Implements Segment's [Video Spec](https://segment.com/docs/spec/video/) and [Segment-Nielsen-DCR](https://github.com/segment-integrations/analytics-ios-integration-nielsen-dcr).


## Installation

* Run `pod install`.
* Click into **Pods > Segment-Nielsen-DCR**
* Click **show in Finder**
* Drag Integration files from **Classes** directory to project in Xcode
* Select **Groups**
* Be sure to select the correct Target Membership

The integration relies on the the Nielsen framework, which is not available on Cocoapods. You must manually include the framework in your project. Navigate to [Nielsen's Engineering Site](https://engineeringforum.nielsen.com/sdk/developers/downloads.php) and download the following Video framework:

![](http://i.imgur.com/Xp1kRWd.png+)

Nielsen also requires the following frameworks, which must be included into Link Binary with Libraries (within app target’s Build Phases)
  - AdSupport.framework
  - SystemConfiguration.framework
  - CoreLocation.framework (Not applicable for International (Germany))
  - libsqlite3

## Requirements

### Build

Xcode 8.0, iOS 9.0 SDK

### Runtime

iOS 9.0 or later

Copyright (C) 2016 Apple Inc. All rights reserved.
