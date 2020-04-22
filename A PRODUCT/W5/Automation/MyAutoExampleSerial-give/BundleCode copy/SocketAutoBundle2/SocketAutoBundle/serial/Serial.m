//
//  Serial.m
//  SocketAutoBundle
//
//  Created by WeidongCao on 2019/12/25.
//  Copyright © 2019 Weidong Cao. All rights reserved.
//

#import "Serial.h"
#import <CoreTestFoundation/CoreTestFoundation.h>

@interface Serial()

@property (nonatomic, strong) ORSSerialPortManager *serialPortManager;
@property(nonatomic,strong) ORSSerialPort *serialPort;
@property(nonatomic,strong) NSString * reponseEndMark;
@property(nonatomic,strong) NSString * dataReponseEndMark;
@property(atomic,strong) NSMutableString * response;
@property(nonatomic,assign) BOOL queryFlag;
@property(nonatomic,assign) BOOL responseOK;


@end

@implementation Serial

-(instancetype)init{
    self = [super init];

    if (self)
    {
        // enter initialization code here
        self.response=[[NSMutableString alloc] initWithCapacity:1];
        self.responseOK = NO;
        self.reponseEndMark=@"\n";
        self.serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
        self.queryFlag = NO;
        
        CTLog(CTLOG_LEVEL_INFO, @"SocketAutoBundle-Serial Init OK");
    }

    return self;
}

-(NSMutableArray *)scan{
    
    NSMutableArray *portList=[NSMutableArray new];
    NSArray *availablePorts = self.serialPortManager.availablePorts;
    CTLog(CTLOG_LEVEL_INFO, @"[SocketAutoBundle-Serial]availablePorts:%@",[availablePorts description]);
    
    [availablePorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ORSSerialPort *port = (ORSSerialPort *)obj;
        //printf("%lu. %s\n", (unsigned long)idx, [port.name UTF8String]);
        [portList addObject:[NSString stringWithFormat:@"/dev/tty.%@",port.name]];
    }];
    CTLog(CTLOG_LEVEL_INFO, @"[SocketAutoBundle-Serial]portList:%@",[portList description]);
    return portList;
}
-(BOOL)open{
    self.serialPort = [[ORSSerialPort alloc] initWithPath:self.port];
    self.serialPort.baudRate =self.baudrate;
    //flow control pins
    self.serialPort.usesRTSCTSFlowControl = NO;
    self.serialPort.usesDTRDSRFlowControl=NO;
    self.serialPort.usesDCDOutputFlowControl=NO;
    self.serialPort.delegate = self;
    
    [self.serialPort open];
    if ([self.serialPort isOpen]) {
        self.serialPort.RTS=NO;
        self.serialPort.DTR=NO;
        return YES;
    }
    return NO;
}
-(BOOL)close{
    
    return [self.serialPort close];
}

-(BOOL)sendCmd:(NSString *)cmd{
    if (!self.serialPort.isOpen) {
        [self printLog:@"ERROR:serial port not opened!"];
        return NO;
    }
    [self.response setString:@""];
    NSData *data = [cmd dataUsingEncoding:NSASCIIStringEncoding];
    NSString *msg=[NSString stringWithFormat:@"[TX]%@",cmd];
    
    [self printLog:msg];
    if ([self.serialPort sendData:data]) {
        return YES;
    }else{
        return NO;
    }
    return NO;
}
-(NSString *)query:(NSString *)cmd timeout:(double )to{
    if (!self.serialPort.isOpen) {
        [self printLog:@"ERROR:serial port not opened!"];
        return NO;
    }
    self.queryFlag = YES;
    [self.response setString:@""];
    NSData *data = [cmd dataUsingEncoding:NSASCIIStringEncoding];
    NSString *msg=[NSString stringWithFormat:@"[TX]%@",cmd];
    [self printLog:msg];
    self.responseOK = NO;
    if (![self.serialPort sendData:data]) {
        [self printLog:@"send command failure"];
        return @"";
    }
    double timeout= to;
    self.reponseEndMark=@"\n";

    NSDate *startT = [NSDate date];
    while(!self.responseOK){
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:startT];
        if (interval > timeout) {
            [self.response setString:@"TIMEOUT"];
            break;
        }
    }
    self.queryFlag = NO;
    return [self.response mutableCopy];;
}

- (void)receivedDataFromSerial:(nonnull NSData *)data {
    
}

#pragma mark ----ORSSerialPor tDelegate-------
-(void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data{
    if ([data length] == 0) {
        return;
    }
    [self.delegate receivedDataFromSerial:data];
    
    if (self.queryFlag) {
        NSString *str=[[NSString alloc]initWithData:data encoding:NSASCIIStringEncoding];
        [self.response appendString:str];
        if ([self.response hasSuffix:self.reponseEndMark]) {
            self.responseOK = YES;
        }
    }
}

- (void)serialPortWasRemovedFromSystem:(nonnull ORSSerialPort *)serialPort {
    
}

-(void)printLog:(NSString *)log{
    CTLog(CTLOG_LEVEL_INFO, @"[socket]%@",log);
    
}

@end
