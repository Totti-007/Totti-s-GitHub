//
//  ATDeviceUSBIMUInterface.h
//  ATDeviceElements
//
//  Created by Sai  on 1/5/18.
//  Copyright © 2018 htwe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import  <ATDeviceElements/ATDeviceBusInterfaceBase.h>

@interface ATDeviceUSBIMUInterface : ATDeviceBusInterface

// Users can init with the USB Location ID
- (id)initWithUSBLocationId:(uint32) locationId;

// Or Users can use USB VendorID, ProductID and BCDevice.
- (id)initWithVendorId: (uint16_t) aVid
          andProductId: (uint16_t) aPid
           andBCDevice: (uint16_t) aBCDevice;
@end
