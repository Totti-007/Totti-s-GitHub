//
//  Serial.h
//  SocketAutoBundle
//
//  Created by WeidongCao on 2019/12/25.
//  Copyright © 2019 Weidong Cao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ORSSerialPort.h"
#import "ORSSerialPortManager.h"

@class ORSSerialPortManager;

NS_ASSUME_NONNULL_BEGIN

@protocol SerialDelegate <NSObject>

-(void)receivedDataFromSerial:(NSData *)data;

@end

@interface Serial : NSObject<ORSSerialPortDelegate,SerialDelegate>

@property (strong, nonatomic) NSString *port;
@property (strong, nonatomic) NSNumber *baudrate;

@property (weak, nonatomic) id<SerialDelegate> delegate;

-(NSMutableArray *)scan;
-(BOOL)open;
-(BOOL)close;

-(BOOL)sendCmd:(NSString *)cmd;
-(NSString *)query:(NSString *)cmd timeout:(double )to;


@end

NS_ASSUME_NONNULL_END
