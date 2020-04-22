//
//  ATDeviceElementsCommon.h
//  ATDeviceElements
//
//  Created by Sai  on 3/15/17.
//  Copyright © 2017 htwe. All rights reserved.
//

#ifndef ATDeviceElementsCommon_h
#define ATDeviceElementsCommon_h

typedef NS_ENUM(uint32_t, ATDeviceElementsID) {
    ATDevice_INVALID_ID         = 0,
    ATDevice_PALLADIUM_ID       = 0xD0010001,
    ATDevice_TITANIUM_ID        = 0xD0010002,
    ATDevice_SPADE_ID           = 0xD0020001,
    ATDevice_XENON_ID           = 0xD0020002,
    ATDevice_POTASSIUM_ID       = 0xD0020003,
    ATDevice_CAESIUM_ID         = 0xD0020005,
    ATDevice_POTASSIUM_IMU_ID   = 0xD0020006,
    ATDevice_GALLIUM_ID         = 0xD0030001,
    ATDevice_RADON_ID           = 0xD0040001,
    ATDevice_DUST_ID            = 0xD0070001,
    ATDevice_MIRAGE_ID          = 0xD0070002,
    ATDevice_AZTEC_ID           = 0xD0070004,
    ATDevice_CARBON_ID          = 0xD0080001,
    ATDevice_ZINC_ID            = 0xD0080002,
    ATDevice_C3PO_ID            = 0xD0090001,
    ATDevice_MANTIS_ID          = 0xD00A0001,
};

typedef NS_ENUM(uint32_t, ATDeviceBCD) {
    ATDeviceInvalidBCD          = 0,
    ATDevicePotassiumBCD        = 0x01,
    ATDeviceSodiumBCD           = 0x02,
    ATDeviceCarbonBCD           = 0x03,
    ATDeviceCaesiumBCD          = 0x04,
    ATDeviceTitaniumBCD         = 0x05,
    ATDeviceC3PO_BCD            = 0x06,
    ATDeviceMantisBCD           = 0x07,
    ATDeviceZincBCD             = 0x08,
};


#endif /* ATDeviceElementsCommon_h */
