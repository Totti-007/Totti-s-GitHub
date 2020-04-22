//
//  ATDPDAltMode.h
//  ATDeviceElements
//
//  Created by Corey Lange on 1/3/18.
//  Copyright © 2018 htwe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ATDeviceElements/ATDPDAltModeInterface.h>

#define kMaximumNumberOfVDOsPerMessage  6

@interface ATDPDAltMode : NSObject

- (BOOL) entered;

- (uint32_t) receivedMode;

- (uint8_t) objectPosition;

- (id) initWithInterface:(ATDPDAltModeInterface*)interface
                   onSOP:(PDMessageType)sop
                withSVID:(uint16_t)svid
           withModeValue:(uint32_t)modeValue
            withModeMask:(uint32_t)modeMask;

- (BOOL) enterModeWithError:(NSError**)error;

- (BOOL) exitModeWithError:(NSError**)error;

- (BOOL) sendStructuredVDM:(uint8_t)command
                   andData:(uint32_t*)data
                  withSize:(uint8_t*)size
              withResponse:(VDMCmdType*)responseType
                 withDelay:(NSTimeInterval)delay
                 withError:(NSError **)error;

- (BOOL) sendUnstructuredVDM:(uint16_t)header
                     andData:(uint32_t*)data
                    withSize:(uint8_t*)size
           expectingResponse:(BOOL)expectingResponse
                   withDelay:(NSTimeInterval)delay
                   withError:(NSError **)error;

@end
