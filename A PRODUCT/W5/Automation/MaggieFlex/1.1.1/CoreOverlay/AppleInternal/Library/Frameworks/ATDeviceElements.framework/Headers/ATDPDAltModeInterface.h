//
//  ATDPDAltModeInterface.h
//  ATDeviceElements
//
//  Created by Corey Lange on 1/3/18.
//  Copyright © 2018 htwe. All rights reserved.
//

#import <ATDeviceElements/ATDPDDevice.h>

@interface ATDPDAltModeInterface : ATDPDDevice

- (BOOL)executeStructuredVDM:(uint8_t)command
                       onSOP:(PDMessageType)sop
                    withSVID:(uint16_t)svid
                 andPosition:(uint8_t)pos
                     andData:(uint32_t*)data
                    withSize:(uint8_t*)size
                withResponse:(VDMCmdType*)responseType
                   withDelay:(NSTimeInterval)delay
                   withError:(NSError **)error;

- (BOOL)executeUnstructuredVDM:(uint16_t)header
                         onSOP:(PDMessageType)sop
                      withSVID:(uint16_t)svid
                       andData:(uint32_t*)data
                      withSize:(uint8_t*)size
             expectingResponse:(BOOL)response
                     withDelay:(NSTimeInterval)delay
                     withError:(NSError **)error;

//PD Helper Functions
- (BOOL)checkIsModeSupported:(uint32_t)mode
                    withMask:(uint32_t)mask
                     forSVID:(uint16_t)svid
                       onSOP:(PDMessageType)sop
                  atPosition:(uint8_t*)position
            withReportedMode:(uint32_t*)reportedMode
                   withError:(NSError**)error;

@end
