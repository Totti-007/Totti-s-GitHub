/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 *
 *  Password.h
 *  Password
 *
 */

#import "Password.h"
#import "TE_Password.h"

@implementation Password

- (void)registerBundlePlugins
{
	[self registerPluginName:@"TE_Password" withPluginCreator:^id<CTPluginProtocol>(){
		return [[TE_Password alloc] init];
	}];
}

@end
