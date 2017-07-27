/**
 * \file	NlsAppApiFactory.m
 *
 * Copyright Notice:
 * Confidential and Proprietary
 * Copyright (c) 2015 by The Nielsen Company
 * All Rights Reserved
 *
 * \brief	NlsAppApiFactory
 */

#import "NlsAppApiFactory.h"
#import <NielsenAppApi/NielsenAppApi.h>


@implementation NlsAppApiFactory

+ (NielsenAppApi *)createNielsenAppApiWithDelegate:(id<NielsenAppApiDelegate>)delegate
{
    NSString *appName = [[NSUserDefaults standardUserDefaults] stringForKey:@"app_name_NlsID3"];
    if (appName == nil || [appName isEqualToString:@"nil"]) {
        appName = @"";
    }

    NSString *appVersion = [[NSUserDefaults standardUserDefaults] stringForKey:@"app_version_NlsID3"];
    if (appVersion == nil || [appVersion isEqualToString:@"nil"]) {
        appVersion = @"";
    }

    NSString *sfCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"app_sfcode_NlsID3"];
    if (sfCode == nil || [sfCode isEqualToString:@"nil"]) {
        sfCode = @"us";
    }

    NSDictionary *appInformation = @{
        @"appid" : @"PE65BE019-9F08-4253-B823-F695B9C89F60",
        @"appversion" : appVersion,
        @"appname" : appName,
        @"sfcode" : sfCode,
        @"nol_devDebug" : @"INFO"
    };

    NielsenAppApi *api = [[NielsenAppApi alloc] initWithAppInfo:appInformation delegate:delegate];
    api.debug = YES;
    return api;
}


@end
