//
//  ATDeviceZinc.h
//  ATDeviceElements
//
//  Created by Sai  on 11/3/17.
//  Copyright © 2017 htwe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ATDeviceElements/ATDeviceLED.h>

@interface ATDeviceZinc : ATDeviceLED

// API defined in ATDeviceLED.h

/**
change the brightness of the 3 LEDs

 @param brightness   between 1 to 15 .  15 is the brightest
 @param saveToEEPROM    save to the EEPROM or not
 @param aError          description of the error
 @return                YES when there is no  error.
 */
- (BOOL) updateBrightness: (uint8_t) brightness
               andSaveToEEPROM: (BOOL) saveToEEPROM
                      andError: (NSError**) aError;

@end
