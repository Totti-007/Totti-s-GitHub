/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 *
 *  SocketAutoPlugin.h
 *  SocketAutoBundle
 *
 */

#import <Foundation/Foundation.h>
#import <CoreTestFoundation/CoreTestFoundation.h>
#import "Serial.h"

@interface SerialAutoPlugin : NSObject<CTPluginProtocol,SerialDelegate>

@end
