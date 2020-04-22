/*
 *
 *	  Copyright (c) 2017 Apple Computer, Inc.
 *	  All rights reserved.
 *
 *	  This document is the property of Apple Computer, Inc. It is
 *	  considered confidential and proprietary information.
 *
 *	  This document may not be reproduced or transmitted in any form,
 *	  in whole or in part, without the express written permission of
 *	  Apple Computer, Inc.
 */



#ifndef Protocols_h
#define Protocols_h

#import <Foundation/Foundation.h>
#import "FDCControlBits.h"

NS_ASSUME_NONNULL_BEGIN


@protocol FDCRemoteTask <NSObject>

- (void)launch;
- (bool)waitUntilLaunched:(NSError **)err;
- (void)waitUntilExit;

- (bool)interrupt:(NSError **)err;
- (bool)terminate:(NSError **)err;

- (bool)writeStandardIn:(NSData *)data;

/*
 * standardOutBufferedData & standardErrBufferedData:
 *
 * Will read and clear buffered data on stdout/stderr. Buffering is only done if you leave the corresponding stream
 * handler block property as nil (standardOutHandler and standardErrHandler)
 * These are not blocking calls.
 */
- (NSData *)standardOutBufferedData;
- (NSData *)standardErrBufferedData;

@property (nullable, copy) NSString *launchPath;
@property (nullable, copy) NSArray<NSString *> *arguments;
@property (nullable, copy) NSDictionary<NSString *, NSString *> *environment;
@property (nullable, copy) NSString *currentDirectoryPath;

@property (readonly) bool isRunning;

@property (readonly) int terminationStatus; /* == NAN until task termination */
@property (readonly) int terminationReason; /* == NAN until task termination */

@property (nullable, copy) void (^standardOutHandler)(id<FDCRemoteTask>, NSData *data);
@property (nullable, copy) void (^standardErrHandler)(id<FDCRemoteTask>, NSData *data);
@property (nullable, copy) void (^terminationHandler)(id<FDCRemoteTask>, NSError *_Nullable error);


@end

@protocol FDCDeviceAppConnection;
@protocol FDCDeviceAppConnectionDelegate <NSObject>

- (void)deviceAppDidConnect:(id<FDCDeviceAppConnection>)dapp;

- (void)deviceAppConnection:(id<FDCDeviceAppConnection>)dapp
          didReceiveMessage:(NSDictionary *)msg
                      reply:(void(^)(NSDictionary *msg))reply_block;

- (void)deviceAppConnection:(id<FDCDeviceAppConnection>)dapp didReceiveMessage:(NSDictionary *)app_msg;
- (void)deviceAppConnection:(id<FDCDeviceAppConnection>)dapp didInterrupt:(NSError *)err; /* App has disconnected or crashed; can trigger deviceAppDidConnect: */
- (void)deviceAppConnection:(id<FDCDeviceAppConnection>)dapp didTerminate:(NSError *)err; /* Connection was closed; must create a new id<FDCDeviceAppConnection> object  */

@end


@protocol FDCDeviceAppConnection <NSObject>

- (bool)sendMessage:(NSDictionary *)app_msg error:(NSError **)error;
- (NSDictionary *)sendMessageSync:(NSDictionary *)msg timeout:(NSTimeInterval)timeout error:(NSError *__autoreleasing *)err;
- (void)disconnect;

@end


@protocol OSModeDevice <NSObject>


- (bool)sleep;
- (bool)reboot;
- (bool)shutdown;
- (bool)rebootOnDisconnect;

- (NSString *_Nullable)deviceSerialNumber;
- (NSDictionary *_Nullable)deviceAttributes;

- (NSData *_Nullable)readFileAtPath:(NSString *)path error:(NSError **)error;
- (bool)writeData:(NSData *)data toFile:(NSString *)path error:(NSError **)error;
- (NSArray *_Nullable)contentsOfDirectory:(NSString *)dir error:(NSError **)error;

/*
 * Check if the remote device is controllable.
 * Using a negative timeout value will wait indefinitely until the remote device is controllable.
 */
- (bool)ping:(NSTimeInterval)timeout;

- (id<FDCRemoteTask> _Nullable)remoteTaskWithLaunchPath:(NSString *)path
                                              arguments:(NSArray<NSString *> *_Nullable)arguments
                                                  error:(NSError **)error;

- (id<FDCDeviceAppConnection> _Nullable)deviceAppConnectionWithAppIdentifier:(NSString *)app_id
                                                                    delegate:(id<FDCDeviceAppConnectionDelegate>)delegate
                                                                       error:(NSError **)error;

- (bool)writeControlBitAtOffset:(int)offset
                         status:(FDCControlBitStatus)status
                    description:(NSString *)description
                          error:(NSError **)error
               challengeHandler:(NSString *(^)(NSString *challenge))challengeHandler;

- (FDCControlBitState *)readControlBitAtOffset:(int)offset error:(NSError **)error;
- (NSArray<FDCControlBitState *> *)readAllControlBits:(NSError **)error;


//Syscfg R/W

@end



@protocol FDCBristolProxyDelegate <NSObject>

- (void)log:(NSDictionary<NSString *, id> *)descriptor;
- (void)handleProgressValue:(NSDictionary<NSString *, id> *)descriptor;
- (void)handleResult:(NSDictionary<NSString *, id> *)descriptor;
- (void)queryUser:(NSDictionary<NSString *, id> *)descriptor;
- (void)displayInstruction:(NSDictionary<NSString *, id> *)descriptor;
- (void)dismissInstruction:(NSDictionary<NSString *, id> *)descriptor;
- (void)handleVersion:(NSString *)version;

@end


@protocol FDCBristolProxy <NSObject>

- (void)startAction:(NSDictionary<NSString *, id> *)descriptor;
- (void)abortAction:(NSDictionary<NSString *, id> *)descriptor;
- (void)queryResponse:(NSDictionary<NSString *, id> *)descriptor;
- (void)acknowledgeInstructionEvent:(NSDictionary<NSString *, id> *)descriptor;
- (void)version;

- (void)close;

@property (nonnull, strong) id<FDCBristolProxyDelegate> delegate;
@property (nullable,  copy) void (^errorHandler)(NSError *_Nullable error);

@end



@protocol macOSDevice <OSModeDevice>

- (id<FDCBristolProxy> _Nullable)createBristolTestProxy:(NSError **)err;

@end



@protocol iOSDevice <OSModeDevice>

- (NSDictionary *)gestaltQueryWithKeys:(NSArray<NSString *> *)keys error:(NSError **)error;

@end



@protocol bridgeOSDevice <iOSDevice>


@end


/* 
 * defer... indefinitely
 */

@protocol iEFIDevice <NSObject>

@end


@protocol macEFIDevice <NSObject>

@end


NS_ASSUME_NONNULL_END


#endif /* Protocols_h */
