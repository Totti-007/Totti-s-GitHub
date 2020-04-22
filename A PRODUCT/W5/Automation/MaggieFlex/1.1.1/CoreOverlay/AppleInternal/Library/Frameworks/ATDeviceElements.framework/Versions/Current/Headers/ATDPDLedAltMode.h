//
//  ATDLedAltMode.h
//  ATDeviceElements
//
//  Created by Corey Lange on 1/2/18.
//  Copyright © 2018 htwe. All rights reserved.
//

#ifndef ATDLedAltMode_h
#define ATDLedAltMode_h

#import <Foundation/Foundation.h>
#import <ATDeviceElements/ATDPDAltMode.h>

typedef NS_ENUM(uint8_t, ATDLedType) {
    ATDLed_None = 0,
    ATDLed_Discrete_Red,
    ATDLed_Discrete_Orange,
    ATDLed_Discrete_Yellow,
    ATDLed_Discrete_Green,
    ATDLed_Discrete_Blue,
    ATDLed_Discrete_Violet,
    ATDLed_Discrete_White,
    ATDLed_DCSD_Red,
    ATDLed_DCSD_Yellow,
    ATDLed_DCSD_Green,
    ATDLed_DCSD_Combined,
    ATDLed_8bit_Red,
    ATDLed_8bit_Green,
    ATDLed_8bit_Blue,
    ATDLed_8bit_RGB,
    ATDLed_PWM_Red,
    ATDLed_PWM_Orange,
    ATDLed_PWM_Yellow,
    ATDLed_PWM_Green,
    ATDLed_PWM_Blue,
    ATDLed_PWM_Violet,
    ATDLed_PWM_White,
    ATDLed_Invalid
};

#define kCombinedDCSDColorOff       0
#define kCombinedDCSDColorRed       1
#define kCombinedDCSDColorYellow    2
#define kCombinedDCSDColorGreen     3

#define kCombinedDCSDModeOff        0
#define kCombinedDCSDModeOn         1
#define kCombinedDCSDModeSlow       2
#define kCombinedDCSDModeFast       3

@interface ATDPDLedAltMode : ATDPDAltMode

- (id) initWithInterface:(ATDPDAltModeInterface*)interface
                   onSOP:(PDMessageType)sop;

- (BOOL) changeLED:(uint8_t)ledIndex
          withArgs:(uint32_t)args
         withError:(NSError**)error;

- (BOOL) turnLedOn:(uint8_t)ledIndex
         withError:(NSError**)error;

- (BOOL) turnLedOff:(uint8_t)ledIndex
          withError:(NSError**)error;

- (BOOL) slowBlinkLed:(uint8_t)ledIndex
            withError:(NSError**)error;

- (BOOL) fastBlinkLed:(uint8_t)ledIndex
            withError:(NSError**)error;

- (BOOL) setCombinedDCSDLed:(uint8_t)ledIndex
                  withColor:(uint8_t)color
                   withMode:(uint8_t)mode
                  withError:(NSError**)error;

- (BOOL) setLedIntensity:(uint8_t)ledIndex
           withIntensity:(uint8_t)intensity
               withError:(NSError**)error;

- (BOOL) setRGBLed:(uint8_t)ledIndex
           withRed:(uint8_t)red
         withGreen:(uint8_t)green
          withBlue:(uint8_t)blue
         withError:(NSError**)error;

- (BOOL) blinkLED:(uint8_t)ledIndex
       withPeriod:(uint16_t)period
        withError:(NSError**)error;

- (BOOL) setTimeout:(uint32_t)timeout
          withError:(NSError**)error;

@end

#endif /* ATDLedModeDevice_h */
