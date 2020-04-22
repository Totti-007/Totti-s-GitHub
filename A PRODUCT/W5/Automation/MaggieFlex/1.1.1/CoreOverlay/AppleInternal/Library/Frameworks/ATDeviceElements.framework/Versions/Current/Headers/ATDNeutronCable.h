//
//  ATDNeutronCable.h
//  ATDeviceElements
//
//  Created by Corey Lange on 1/2/18.
//  Copyright © 2018 htwe. All rights reserved.
//

#ifndef ATDNeutronCable_h
#define ATDNeutronCable_h

#import <Foundation/Foundation.h>
@class ATDPDAltModeInterface;

@interface ATDNeutronCable : NSObject

- (id) initWithInterface:(ATDPDAltModeInterface*)interface;

//Serial Number Functions
- (NSString *) appleSerialNumber:  (NSError**) error;
- (NSString *) vendorSerialNumber: (NSError**) error;


//LED Control Functions
- (BOOL) turnLedRedWithError:(NSError**)error;
- (BOOL) turnLedYellowWithError:(NSError**)error;
- (BOOL) turnLedGreenWithError:(NSError**)error;
- (BOOL) turnLedOffWithError:(NSError**)error;
- (BOOL) slowBlinkLedRedWithError:(NSError**)error;
- (BOOL) slowBlinkLedYellowWithError:(NSError**)error;
- (BOOL) slowBlinkLedGreenWithError:(NSError**)error;
- (BOOL) fastBlinkLedRedWithError:(NSError**)error;
- (BOOL) fastBlinkLedYellowWithError:(NSError**)error;
- (BOOL) fastBlinkLedGreenWithError:(NSError**)error;

//Diags Functions
- (BOOL) hardwareVersion:(uint32_t*)hwVersion
         andFirmwareVersion:(uint32_t*)fwVersion
                  withError:(NSError**)error;
- (BOOL) readCycleCount:(uint32_t*)cycleCount
              withError:(NSError**)error;
- (BOOL) incrementCycleCountWithError:(NSError**)error;

@end

#endif /* ATDNeutronCable_h */
