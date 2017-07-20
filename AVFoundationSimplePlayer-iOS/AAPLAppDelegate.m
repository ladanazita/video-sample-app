/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Application delegate.
*/

#import "AAPLAppDelegate.h"
#import <Analytics/SEGAnalytics.h>
#import "SEGNielsenDCRIntegrationFactory.h"


@implementation AAPLAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    // https://segment.com/ladanazita/sources/video/overview
    SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:@"nu3idUpAunUqh7pJWwFsgUKg7qTo7Ouz"];

    configuration.trackApplicationLifecycleEvents = YES;
    configuration.flushAt = 1;
    configuration.recordScreenViews = YES;
    [configuration use:[SEGNielsenDCRIntegrationFactory instance]];
    [SEGAnalytics debug:YES];
    [SEGAnalytics setupWithConfiguration:configuration];
}

@end
