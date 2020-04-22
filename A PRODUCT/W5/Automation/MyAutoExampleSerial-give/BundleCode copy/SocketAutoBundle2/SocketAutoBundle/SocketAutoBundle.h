/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 *
 *  SocketAutoBundle.h
 *  SocketAutoBundle
 *
 */

 #import <CoreTestFoundation/CoreTestFoundation.h>

@interface SocketAutoBundle : CTPluginBaseFactory <CTPluginFactory>

- (void)registerBundlePlugins;

@end
