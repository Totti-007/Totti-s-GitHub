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

#ifndef FactoryDeviceControl_FDCControlBits_h
#define FactoryDeviceControl_FDCControlBits_h

typedef NS_ENUM (int, FDCControlBitStatus) {
    FDCControlBitPassed = 0,
    FDCControlBitIncomplete,
    FDCControlBitFailed,
    FDCControlBitUntested,
    FDCControlBitUnknown,
};

/*
 * 1v0 refers to Control Bit version 1.0
 * 2v0 refers to Control Bit version 2.0
 * Since different control bit versions contain different variables for each control bit,
 * some variables will be irrelevant depending on which version the device is running on.
 * If the variable is irrelevant, its value is set to -1 or nil.
 */
@interface FDCControlBitState : NSObject<NSSecureCoding>

@property (nonatomic, readonly) int version;                // 1v0 and 2v0
@property (nonatomic, readonly) FDCControlBitStatus testStatus;      // 1v0 and 2v0
@property (nonatomic, readonly) int stationID;              // 1v0 and 2v0
@property (nonatomic, readonly) int absoluteFailCount;      // 1v0 and 2v0
@property (nonatomic, readonly) int relativeFailCount;      // 1v0 and 2v0
@property (nonatomic, readonly) int eraseCount;             // 1v0 and 2v0
@property (nonatomic, readonly) int relativeWriteCount;     // 2v0 only. Set to -1 in 1v0.
@property (nonatomic, readonly) NSDate *timestamp;          // 1v0 only. Set to -1 in 2v0.
@property (nonatomic, readonly) NSString *softwareVersion;  // 1v0 only. Set to nil in 2v0.
@property (nonatomic, readonly) NSString *comment;          // 2v0 only. Set to -1 in 1v0.

@end


@interface FDCControlBitHeader : NSObject<NSSecureCoding>

@property (nonatomic, readonly) int version;                // 1v0 and 2v0
@property (nonatomic, readonly) int fatpControlBitStart;    // 1v0 and 2v0
@property (nonatomic, readonly) int absoluteWriteCount;     // 2v0 only. Set to -1 in 1v0.
@property (nonatomic, readonly) int lastWrittenOffset;      // 2v0 only. Set to -1 in 1v0.
@property (nonatomic, readonly) int lastWrite;              // 2v0 only. Set to -1 in 1v0.

@end


#endif // ifndef FactoryDeviceControl_FDCControlBits_h
