//
//  ATDeviceLED.h
//  ATDeviceElements
//
//  Created by Sai  on 11/3/17.
//  Copyright © 2017 htwe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ATDeviceElements/ATDeviceElement.h>

@interface ATDeviceLED : ATDeviceElement

- (BOOL) turnLED_ONapplyToRed: (BOOL) applyToRed
              andApplyToGreen: (BOOL) applyToGreen
             andApplyToYellow: (BOOL) applyToYellow
                     andError: (NSError**) aError;

- (BOOL) turnLED_OFFapplyToRed: (BOOL) applyToRed
               andApplyToGreen: (BOOL) applyToGreen
              andApplyToYellow: (BOOL) applyToYellow
                      andError: (NSError**) aError;
/** turnOnRedLED
 * brief One Call to Turn On and Off Red, Green and Yellow LEDs. The difference between this API and turnLED_ONapplyToRed/turnLED_OFFapplyToRed, this API always apply the changes to all 3 LEDS.
 *
 * param[in] redOn:     YES = Turn ON Red, NO = Turn OFF Red.
 * param[in] greenOn:   YES = Turn ON Green, NO = Turn OFF Green.
 * param[in] yellowOn:  YES = Turn ON Yellow, NO = Turn OFF Yellow.
 * param[out] aError:   nil = NO means no error, or error set. Error code is defined in <ATDeviceElements/ATDeviceCarbonErrors.h>
 * retval BOOL:         YES = sucess NO = Error or Fail;
 *
 *
 */

- (BOOL) turnOnRedLED    : (BOOL) redOn
         turnOnGreenLED  : (BOOL) greenOn
         turnOnYellowLED : (BOOL) yellowOn
                andError : (NSError**) aError;


- (BOOL) blinkLEDapplyToRed: (BOOL) applyToRed
            andApplyToGreen: (BOOL) applyToGreen
           andApplyToYellow: (BOOL) applyToYellow
               andBlinkRate: (uint16_t) blinkRate
                   andError: (NSError**) aError;
@end
