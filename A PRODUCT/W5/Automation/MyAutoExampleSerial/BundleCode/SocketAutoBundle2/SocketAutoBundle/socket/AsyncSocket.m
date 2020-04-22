//
//  AsyncSocket.m
//  SocketAutoBundle
//
//  Created by WeidongCao on 2019/12/25.
//  Copyright © 2019 Weidong Cao. All rights reserved.
//

#import "AsyncSocket.h"
#import <CoreTestFoundation/CoreTestFoundation.h>

#define READ_TIMEOUT 3
#define WRITE_TIMEOUT 3
#define SERVER_USERDATA 1000
#define CLIENT_USERDATA 2000


@interface AsyncSocket()

@property (nonatomic,strong) GCDAsyncSocket *socket;
@property (nonatomic,assign) BOOL isConnected;
@property (nonatomic,strong) NSMutableArray *socketArray;
@property (atomic,assign) BOOL IS_REPLY;
@property (nonatomic,strong) NSMutableString *receiveStr;
@property (atomic,assign) BOOL timeout;

@end


@implementation AsyncSocket

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        // enter initialization code here
        self.socketArray=[[NSMutableArray alloc] initWithCapacity:1];
        self.receiveStr=[[NSMutableString alloc] initWithCapacity:1];
        
        self.isConnected = NO;
        
    }

    return self;
}

-(BOOL)open{
    if (self.mode == nil) {
        self.mode = @"server";
    }
    if (self.ip == nil) {
        self.ip = @"127.0.0.1";
    }
    //  !!!! 用GCD的形式
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.socket setDelegate:self];
    NSError *error = NULL;
    if ([self.mode isEqualToString:@"client"]) {
        self.isConnected=NO;
        int t = [self.socket connectToHost:self.ip onPort:self.port error:&error];
        NSString *msg=[NSString stringWithFormat:@"start status:%d error:%@",t,[error description]];
        [self printLog:msg];
        if(t){
            return YES;
        }else{
            return NO;
        }
    }else{
        // 服务器socket实例化  在0x1234端口监听数据
        self.socketArray=[[NSMutableArray alloc] initWithCapacity:1];;
        BOOL status =[self.socket acceptOnInterface:self.ip port:self.port error:&error];
        NSString *msg=[NSString stringWithFormat:@"start status:%hhd error:%@",status,[error description]];
        [self printLog:msg];
        if(status){
            self.isConnected=YES;
            return YES;
        }else{
            return NO;
        }
        
    }

    return NO;
}
-(BOOL)close{
    if ([self.mode isEqualToString:@"client"]) {
        [self.socket setDelegate:nil];
        [self.socket disconnect];
        self.socket=nil;
        
    }else{
        for (int i=0; i<[_socketArray count]; i++) {
            GCDAsyncSocket *client=[_socketArray objectAtIndex:i];
            [client disconnect];
            [client setDelegate:nil];
            
        }
        [self.socket setDelegate:nil];
        [self.socket disconnect];
    }
    self.isConnected=NO;
    [self printLog:@"close socket"];
    return YES;
}
-(BOOL)sendCmd:(NSString *)cmd{
    if (!_isConnected) {
        [self printLog:@"[send Command]ERROR:no connect"];
        return NO;
    }
    NSData *data=[cmd dataUsingEncoding:NSUTF8StringEncoding];
    NSString *msg=[NSString stringWithFormat:@"[TX]%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    [self printLog:msg];
    if ([self.mode isEqualToString:@"client"]) {
        [self.socket writeData:data withTimeout:WRITE_TIMEOUT tag:300];
        // 继续读取socket数据
        [self.socket readDataWithTimeout:-1 tag:300];
    }
    else{
        if([self.socketArray count] == 0){
            [self printLog:@"No client connected,please check!"];
            return NO;
        }
        for (int i=0; i<[self.socketArray count]; i++) {
            GCDAsyncSocket *client=[_socketArray objectAtIndex:i];
            [client writeData:data withTimeout:WRITE_TIMEOUT tag:300];
            // 继续读取socket数据
            [client readDataWithTimeout:-1 tag:300];
        }
        
    }
    return YES;
}
-(NSString *)query:(NSString *)cmd timeout:(double )to{
    if (!_isConnected) {
        [self printLog:@"[query]ERROR:no connect"];
        return @"";
    }
    
    _IS_REPLY=NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [_receiveStr setString:@""];
    [self sendCmd:cmd];
    [NSThread detachNewThreadSelector:@selector(waitSignal:) toTarget:self withObject:semaphore];
    //等待(阻塞线程)
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    return [_receiveStr copy];;
}
-(void)waitSignal:(dispatch_semaphore_t )semaphore{
    double count=0.0;
    while (count<self.timeout) {
        [NSThread sleepForTimeInterval:0.02];
        count+=0.02;
        if(self.IS_REPLY) break;
    }
    dispatch_semaphore_signal(semaphore);
}
#pragma mark ---GCDAsyncSocket Delegate---
// 有新的socket向服务器链接自动回调
-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    self.isConnected=YES;
    
    [self.socketArray addObject:newSocket];
    NSString *msg=[NSString stringWithFormat:@"Accept new client:%@ ip:%@",newSocket,[newSocket connectedHost]];
    [self printLog:msg];
    // 如果下面的方法不写 只能接收一次socket链接
    
    [newSocket readDataWithTimeout:-1 tag:300];
    
}
// 网络连接成功后  自动回调
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    self.isConnected=YES;
    if ([self.mode isEqualToString:@"client"]) {
        //_socket = sock;
        NSString *msg=[NSString stringWithFormat:@"connected server:ip:%@ port:%d",host,port];
        [self printLog:msg];
        //[self logUpdate:msg];
        // 继续读取socket数据
        [sock readDataWithTimeout:-1 tag:300];
        return;
    }
    NSString *msg=[NSString stringWithFormat:@"connected client:ip:%@ port:%d",host,port];
    [self printLog:msg];
}
// 收到消息后回调
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [self.delegate receiveDataFromSocket:data socket:sock];
    
    NSString *recStr=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self.receiveStr setString:recStr];
    self.IS_REPLY = YES;
    // 继续读取socket数据
    [sock readDataWithTimeout:-1 tag:300];
}

/*重连
 
 实现代理方法
 
 -(void)onSocketDidDisconnect:(GCDAsyncSocket *)sock
 {
 NSLog(@"sorry the connect is failure %@",sock.userData);
 if (sock.userData == SocketOfflineByServer) {
 // 服务器掉线，重连
 [self socketConnectHost];
 }
 else if (sock.userData == SocketOfflineByUser) {
 // 如果由用户断开，不进行重连
 return;
 }
 
 }
 */
// 连接断开时  服务器自动回调
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err
{
    if ([self.mode isEqualToString:@"client"] ) {
        self.isConnected=NO;
        
        [self printLog:@"[alarm]****Disconnect****"];
        self.socket=nil;
        return;
    }
    NSString *msg=[NSString stringWithFormat:@"Client:%@ disconnect!",sock];
    [self printLog:msg];
    [self.socketArray removeObject:sock];
    if ([self.socketArray count] == 0) {
        self.isConnected=NO;
    }
}

// 向用户发出的消息  自动回调
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSString *msg=[NSString stringWithFormat:@"send to [%@] successful",[sock connectedHost]];
    [self printLog:msg];
}
/*
 //read data timeout callback
 - (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
 elapsed:(NSTimeInterval)elapsed
 bytesDone:(NSUInteger)length{
 [self logUpdate:@"[RX]Read data timeout!"];
 [sock readDataWithTimeout:-1 tag:300];
 return 0.05;
 }
 
 - (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag
 elapsed:(NSTimeInterval)elapsed
 bytesDone:(NSUInteger)length{
 
 [self logUpdate:@"[TX]Send data timeout!"];
 return -1;
 }
 */
-(void)printLog:(NSString *)log{
    CTLog(CTLOG_LEVEL_INFO, @"[socket]%@",log);
    
}

- (void)receiveDataFromSocket:(nonnull NSDate *)data socket:(nonnull GCDAsyncSocket *)socket{
    
}

@end
