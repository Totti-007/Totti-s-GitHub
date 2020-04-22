//
//  ATDeviceDiscovery.h
//  ATDeviceElements
//
//  Created by Sai  on 8/23/17.
//  Copyright © 2017 htwe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ATDeviceElements/ATDeviceElementsCommon.h>


@interface ATDeviceInfo: NSObject

-(id) initWithPath: (NSString*) path
           andName: (NSString*) name
    andUSBLocation: (NSInteger) usbLocation
         andUSBbcd: (NSInteger) usbBCDId;

@property (copy)  NSString * devicePath;
@property (copy)  NSString * deviceName;
@property (nonatomic) NSInteger usbLocationId;
@property (nonatomic) NSInteger usbBCD;
@end


@interface ATDeviceDiscovery : NSObject

/** deviceSerialPathForCircuitNumber
 * brief find the first ATDevice USB Devices (USB Interface endpoint0 e.g. Potassium or Sodium) that matches circuit Number.
 *
 * param[in] circuitNum     circuit Number. Currently Ciruit number is the Byte offset at 0 of the User EEPROM, you can use writeUserPageAtAddress to modify this circuit number
 * param[out] aError         nil = NO error, or error set if any device iterating has error. Error code is defined in <ATDeviceElements/ATDeviceCarbonErrors.h>
 * retval NSString:           return the string in /dev/cu.xxxx device.
 *
 *
 */
+(NSString*) deviceSerialPathForCircuitNumber: (uint8_t) circuitNum
                                     andError: (NSError**) aError;


/** deviceSerialPathForSlotID
 * brief find the first ATDevice UART Devices (e.g. Carbon or Zinc) that matches slot ID.  Devices must conform to use the UART Interface
 *
 * param[in] slotID      Currently slotID is the Byte offset at userPageAddress of the User EEPROM, you can use writeUserPageAtAddress to modify this slotID
 * param[in] userPageAddress The offset in User Page EEPROM where the SLotID stored
 * param[in] deviceBCD      The Test Device interested
 * param[out] aError         nil = NO error, or error set if any device iterating has error. Error code is defined in <ATDeviceElements/ATDeviceCarbonErrors.h>
 * retval NSString:           return the string in /dev/cu.xxxx device.
 *
 *
 */
+(NSString*) deviceSerialPathForSlotID: (NSInteger) slotID
                     atUserPageAddress: (NSInteger) userPageAddress
                          forDeviceBCD: (ATDeviceBCD) deviceBCD
                              andError: (NSError**) aError;

/** findSerialPath
 * brief find the first ATDevice USB Devices (endpoint0 e.g. Potassium or Sodium) that matches  circuit Number and set the serialPath and USBLocationID
 *
 * param[out] serialPath        this serialPath value will be set by the function. pass nil if you don't need it: string in /dev/cu.xxxx device.
 * param[out] usbLocationID     this usbLocationID value will be set by the function pass nil if you don't need it
 * param[in] circuitNum         circuit Number Currently Ciruit number is the Byte offset at 0 of the User EEPROM
 * param[out] aError           nil = NO error, or error set if any device iterating has error. Error code is defined in <ATDeviceElements/ATDeviceCarbonErrors.h>
 * retval:                       return YES if no error
 *
 *
 */
+(BOOL)     findSerialPath: (NSString**) serialPath
          andUSBLocationID: (uint32*) usbLocationID
          forCircuitNumber: (uint8_t) circuitNum
                  andError: (NSError**) aError;

/**
 find SerialPath and USB Location with Test Device BCD. If there is more than one Device match the BCD, the first one will be returned.

 @param[out] serialPath          this serialPath value will be set by the function. pass nil if you don't need it
 @param[out] usbLocationID       this usbLocationID value will be set by the function pass nil if you don't need it
 @param[in] deviceBCD           Each Apple Test Devices that support USB VCOM has unique
 @param[out] aError              nil = NO error, or error set if any device iterating has error. Error code is defined in <ATDeviceElements/ATDeviceCarbonErrors.h>
 @return:                    YES if no Error
 */
+(BOOL)     findSerialPath: (NSString**) serialPath
          andUSBLocationID: (uint32*) usbLocationID
              forDeviceBCD: (ATDeviceBCD) deviceBCD
                  andError: (NSError**) aError;

/** usbLocationIDForSerialPath
 * brief find USB Location for the specific Serial Path from all Apple Test Devices. Return 0 if not found.
 *
 * param[in] serialPath:     Serial Dev Path e.g. /dev/cu.xxxx
 * retval uint32:           It's the USB location ID for this serial Path. When Error ocurred, the returned location ID will be 0.
 *
 *
 */
+(uint32) usbLocationIDForSerialPath:(NSString*) serialPath;


/**
 discoverAppleTestDevices returns an array of Apple Test Devices that support USB virual COM

 @return an Array of ATDeviceInfo*. If there is error, nil will be returned
 */
+(NSArray <ATDeviceInfo*>*) discoverAppleTestDevices;

@end
