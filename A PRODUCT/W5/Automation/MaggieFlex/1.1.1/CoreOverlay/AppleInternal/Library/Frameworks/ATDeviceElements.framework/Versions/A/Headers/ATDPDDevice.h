//
//  ATPDDevice.h
//  ATPDDevice
//
//  Created by Sai  on 12/13/16.
//  Copyright © 2016 htwe. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(uint8_t, PDMessageType) {
    PDType_SOP = 0,
    PDType_SOPPrime,
    PDType_SOPDoublePrime,
    PDType_SOPDebug,
};

typedef NS_ENUM(uint8_t, VDMCmdType) {
    VDMCmd_Init = 0,
    VDMCmd_ACK,
    VDMCmd_NAK,
    VDMCmd_BUSY,
};

//PD Macros
#define kVDMCommandDiscoverIdentity 1
#define kVDMCommandDiscoverSVIDs    2
#define kVDMCommandDiscoverModes    3
#define kVDMCommandEnterMode        4
#define kVDMCommandExitMode         5
#define kVDMCommandAttention        6

#define kVDMSVIDPD                  0xFF00
#define kVDMSVIDApple               0x05AC

#define kVDMStructuredDelay     0.05
#define kVDMUnstructuredDelay   0.05

@class AppleHPMUserClient;

@interface ATDPDDevice : NSObject
{
    @protected
    uint32_t deviceAddress;
    AppleHPMUserClient * pdClient;
}

- (id)  initWithRid:(uint8_t)rid
           andRoute: (uint64_t) route
   andDeviceAddress: (uint32_t) address;


// Default device address will be 0
- (id)  initWithRid:(uint8_t)rid
           andRoute: (uint64_t) route;

- (BOOL) openWithError:(NSError **) error;

- (IOReturn)registerWrite:(void*)buffer
                 ofLength:(uint64_t)length
                atAddress:(uint32_t)address;

- (IOReturn)registerRead:(void*)buffer
                ofLength:(uint64_t)length
               atAddress:(uint32_t)address
     andActualReadLength:(uint64_t*)read_length;

- (IOReturn)executeIECSCommand:(uint32)command;

- (BOOL) close;

@end
