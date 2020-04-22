/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 *
 *  SocketAutoBundle.h
 *  SocketAutoBundle
 *
 */

#import "SocketAutoBundle.h"
#import "SocketAutoPlugin.h"
#import "SerialAutoPlugin.h"

@implementation SocketAutoBundle

- (void)registerBundlePlugins
{
	[self registerPluginName:@"SocketAutoPlugin" withPluginCreator:^id<CTPluginProtocol>(){
		return [[SocketAutoPlugin alloc] init];
	}];
    
    [self registerPluginName:@"SerialAutoPlugin" withPluginCreator:^id<CTPluginProtocol>(){
        return [[SerialAutoPlugin alloc] init];
    }];
}

@end

