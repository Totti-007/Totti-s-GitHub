//
//  ATDevicePotassium.h
//  ATDeviceElements
//
//  Created by Sai  on 11/9/16.
//  Copyright © 2016 htwe. All rights reserved.
//

#import <ATDeviceElements/ATDeviceElements.h>
#import <ATDeviceElements/ATDeviceDust.h>

#define kATDPotassiumProductID 0x1636
#define kATDPotassiumBCDeviceID 0x0001


@interface ATDevicePotassium : ATDeviceElement

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

- (BOOL) readTargetVBus: (double*) targetVBus
          andChargeVBus: (double*) chargeVBus
             andSamples: (uint32_t) samples
               andError: (NSError**) aError;

- (BOOL) setDebugLevel: (uint8_t) level
              andError: (NSError**) aError;

- (BOOL) startHeartbeatWithTimeout: (uint32_t) timeout
                          andError: (NSError**) aError;

- (BOOL) sendHeartbeatWithError: (NSError**) aError;

- (BOOL) cancelHeartbeatWithError: (NSError**) aError;

- (BOOL) saveEnvironmentWithError: (NSError**) aError;

- (BOOL) sendForceDFUWithError: (NSError**) aError;

- (BOOL) setSWDPollingPeriod: (uint32_t) period
             andActualPeriod: (uint32_t*) currentPeriod
                    andError: (NSError**) aError;

- (BOOL) emulateDisconnectOnPort: (uint8_t) port
                     forDuration: (uint16_t) duration
                       withError: (NSError**) aError;

- (BOOL) sendRequestForVoltage: (uint16_t) voltage
                    andCurrent: (uint16_t) current
                     withError: (NSError**) aError;

- (BOOL) powerRoleSwapToSourceWithError: (NSError**) aError;

- (BOOL) powerRoleSwapToSinkWithError: (NSError**) aError;

- (BOOL) startAppleDebugModeWithError: (NSError**) aError;

// start_usb
- (BOOL) startAppleUSBModeWithError: (NSError**) aError;

- (BOOL) useBananaCircuit: (BOOL) enable
       withStartupTimeout: (uint16_t) timeout
                withError: (NSError**) aError;

- (BOOL) getBananaSerialNumber: (uint8_t*) serialNumber
                     withError: (NSError**) aError;

- (BOOL) getBananaVersion: (uint32_t*) version
                withError: (NSError**) aError;

- (BOOL) getBananaUSBState: (ATDeviceBananaUSBState*) state
                 withError: (NSError**) aError;

- (BOOL) bananaTypeKeys: (uint8_t*) keycodes
       withModifierKeys: (uint8_t) modifiers
        withSpecialKeys: (uint8_t) specials
            forDuration: (uint16_t) duration
              withError: (NSError**) aError;

- (BOOL) bananaReleaseAllKeysWithError: (NSError**) aError;


// mirageSetUSBOutputs

// Disable All USB Port = 0 or ATDeviceDustUSBPortAllOff
// enable USB Port 1 = 0x01 or ATDeviceDustUSBPort_1_On
// enable USB Port 2 = 0x02 or ATDeviceDustUSBPort_2_On
// enable USB Port 3 = 0x04 or ATDeviceDustUSBPort_3_On
// enable USB Port 4 = 0x08 or ATDeviceDustUSBPort_4_On
// enable USB Port 5 = 0x10 or ATDeviceDustUSBPort_5_On
// enable USB Port 6 = 0x20 or ATDeviceDustUSBPort_6_On
// enable USB Port 7 = 0x40 or ATDeviceDustUSBPort_7_On
// enable USB Port 8 = 0x80 or ATDeviceDustUSBPort_8_On
// enable All USB Port = 0xFF or ATDeviceDustUSBPortAllOn

// usbPortsMask - masks of the eight ports . Each number entered will turn on the corresponding USB port on Mirage. A zero clears all outputs.
// you can use combination of these mask. e.g. TO enable Port 1 and 2, usbPortsMask = ATDeviceDustUSBPort_1_On | ATDeviceDustUSBPort_2_On

//      USB Ports Mapping on Mirage
//  |------------------------------------|
//  |  ====     ====     ====     ====   |
//  |  ====     ====     ====     ====   |
//  |------------------------------------|

//  |------------------------------------|
//  |  =01=     =03=     =05=     =07=   |
//  |  =02=     =04=     =06=     =08=   |
//  |------------------------------------|

- (BOOL) mirageSetUSBOutputs: (uint32_t) usbPortsMask andError: (NSError**) aError;

@end
