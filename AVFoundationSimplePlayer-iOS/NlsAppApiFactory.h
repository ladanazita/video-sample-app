/**
 * \file	NlsAppApiFactory.h
 *
 * Copyright Notice:
 * Confidential and Proprietary
 * Copyright (c) 2015 by The Nielsen Company
 * All Rights Reserved
 *
 * \brief	NlsAppApiFactory
 */

#import <Foundation/Foundation.h>

@class NielsenAppApi;
@protocol NielsenAppApiDelegate;


@interface NlsAppApiFactory : NSObject

+ (NielsenAppApi *)createNielsenAppApiWithDelegate:(id<NielsenAppApiDelegate>)delegate;

@end
