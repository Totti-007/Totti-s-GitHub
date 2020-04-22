//
//  ATDPDDiagsAltMode.h
//  ATDeviceElements
//
//  Created by Corey Lange on 1/16/18.
//  Copyright © 2018 htwe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ATDeviceElements/ATDPDAltMode.h>

typedef NS_ENUM(uint32_t, ATDFDCommand) {
    ATDFDCommand_Reset = 0,
    ATDFDCommand_GetHWVersion = 1,
    ATDFDCommand_GetFWVersion = 2,
    ATDFDCommand_ReadCycleCount = 15,
    ATDFDCommand_IncrementCycleCount = 16,
};

@interface ATDPDDiagsAltMode : ATDPDAltMode

- (id) initWithInterface:(ATDPDAltModeInterface*)interface
                   onSOP:(PDMessageType)sop;

- (BOOL) selectFactoryDiagsCommandPage:(uint16_t)page
                 withSupportedCommands:(uint32_t*)supportedCommands
                             withError:(NSError**)error;

- (BOOL) executeFactoryDiagsCommand:(ATDFDCommand)command
                           withData:(uint32_t*)commandData
                         withLength:(uint8_t*)length
                          withError:(NSError**)error;

- (BOOL) resetWithError:(NSError**)error;

- (BOOL) getHardwareVersion:(uint32_t*)hwVersion
                  withError:(NSError**)error;

- (BOOL) getFirmwareVersion:(uint32_t*)fwVersion
                  withError:(NSError**)error;

- (BOOL) readCycleCount:(uint32_t*)cycleCount
              withError:(NSError**)error;

- (BOOL) incrementCycleCountWithError:(NSError**)error;

@end
