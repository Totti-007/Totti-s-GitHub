/*
 *
 *	  Copyright (c) 2017 Apple Computer, Inc.
 *	  All rights reserved.
 *
 *	  This document is the property of Apple Computer, Inc. It is
 *	  considered confidential and proprietary information.
 *
 *	  This document may not be reproduced or transmitted in any form,
 *	  in whole or in part, without the express written permission of
 *	  Apple Computer, Inc.
 */

#import <Foundation/Foundation.h>
#import "Domains.h"
#import "Protocols.h"

@interface FactoryDeviceController : NSObject

/*
 * URL Examples...
 *
 *
 * iOS/watchOS:
 *   usb://0x14210000
 * 
 *
 * bridgeOS/macOS:
 *   usb://0x14210000
 *   tcp://169.254.12.12
 *
 */


+ (id<iOSDevice>)iOSDeviceControllerWithURL:          (NSURL *)url error:(NSError **)error;
+ (id<macOSDevice>)macOSDeviceControllerWithURL:      (NSURL *)url error:(NSError **)error;
+ (id<bridgeOSDevice>)bridgeOSDeviceControllerWithURL:(NSURL *)url error:(NSError **)error;

+ (id<OSModeDevice>)OSModeDeviceControllerWithURL:    (NSURL *)url error:(NSError **)error;

@end


@interface NSURL(URLWithFormat)

+ (instancetype)URLWithFormat:(NSString *)fmt, ...;

@end
