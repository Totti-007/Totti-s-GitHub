//
//  AsyncSocket.h
//  SocketAutoBundle
//
//  Created by WeidongCao on 2019/12/25.
//  Copyright © 2019 Weidong Cao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AsyncSocketDelegate <NSObject>

-(void)receiveDataFromSocket:(NSData *)data socket:(GCDAsyncSocket *)socket;

@end

@interface AsyncSocket : NSObject<GCDAsyncSocketDelegate,AsyncSocketDelegate>

@property (strong, nonatomic) NSString *mode;
@property (strong, nonatomic) NSString *ip;
@property (assign) int port;
@property (strong, nonatomic) id<AsyncSocketDelegate> delegate;

-(BOOL)open;
-(BOOL)close;
-(BOOL)sendCmd:(NSString *)cmd;
-(NSString *)query:(NSString *)cmd timeout:(double )to;

@end

NS_ASSUME_NONNULL_END
