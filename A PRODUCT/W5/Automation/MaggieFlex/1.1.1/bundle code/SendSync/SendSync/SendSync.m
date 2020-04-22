/*!
 *	Copyright 2019 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 *
 *  SendSync.h
 *  SendSync
 *
 */

#import "SendSync.h"
#import "Dut.h"
#import "Fixture.h"

@implementation SendSync

- (void)registerBundlePlugins
{
	[self registerPluginName:@"Dut" withPluginCreator:^id<CTPluginProtocol>(){
		return [[Dut alloc] init];
	}];
     
     [self registerPluginName:@"Fixture" withPluginCreator:^id<CTPluginProtocol>(){
          return [[Fixture alloc] init];
     }];

}

@end
