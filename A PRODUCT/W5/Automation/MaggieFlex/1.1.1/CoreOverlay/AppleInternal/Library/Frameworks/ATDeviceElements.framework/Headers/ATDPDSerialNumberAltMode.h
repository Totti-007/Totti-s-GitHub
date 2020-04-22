//
//  ATDSerialNumberModeDevice.h
//  ATDeviceElements
//
//  Created by Corey Lange on 1/2/18.
//  Copyright © 2018 htwe. All rights reserved.
//

#ifndef ATDPDSerialNumberAltMode_h
#define ATDPDSerialNumberAltMode_h

#import <Foundation/Foundation.h>
#import <ATDeviceElements/ATDPDAltMode.h>

typedef NS_ENUM(uint8_t, ATDSerialNumberType) {
    ATDSerialNumber_None = 0,
    ATDSerialNumber_17Byte,
    ATDSerialNumber_BinaryUUID,
    ATDSerialNumber_AsciiUUID,
    ATDSerialNumber_VendorData,
};

@interface ATDPDSerialNumberAltMode : ATDPDAltMode

- (id) initWithInterface:(ATDPDAltModeInterface*)interface
                   onSOP:(PDMessageType)sop;

- (BOOL) getSerialNumber:(NSString**)serialNumber
                  ofType:(ATDSerialNumberType)type
               withError:(NSError**)error;

@end

#endif /* ATDSerialNumberModeDevice_h */
