/*!
 *  Copyright 2019 Apple Inc. All rights reserved.
 *
 *  APPLE NEED TO KNOW CONFIDENTIAL
 */

/*
 
 
 */

#import "Fixture.h"
#import "WDSyncSocket.h"
#import "PlistOperator.h"

static int i = 0;

@interface Fixture()

@property(nonatomic,strong) WDSyncSocket     * wdSyncSocket;
@property(nonatomic,strong) PlistOperator    * plistOperator;
@property(nonatomic,strong) CTContext        * ctx;
@end

@implementation Fixture

-(WDSyncSocket *)wdSyncSocket
{
    if (_wdSyncSocket == nil) {
        
        _wdSyncSocket = [[WDSyncSocket alloc]init];
    }
    
    return _wdSyncSocket;
}

-(PlistOperator *)plistOperator
{
    if (_plistOperator == nil)
    {
        _plistOperator=[[PlistOperator alloc]init];
    }
    return _plistOperator;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        
    }

    return self;
}

- (BOOL)setupWithContext:(CTContext *)context error:(NSError *__autoreleasing *)error
{
    self.ctx = context;
    
    CTLog(CTLOG_LEVEL_INFO,@"=============Fixture using setup");
    return YES;
}

- (BOOL)teardownWithContext:(CTContext *)context error:(NSError *__autoreleasing *)error
{
    [self.wdSyncSocket sendCommand:[self.plistOperator readValueForKey:@"reset_ctrlboard"] timeout:5.0];
    //释放网口
    if (_wdSyncSocket) {
        
        [_wdSyncSocket disConnectToServer];
    }
    
    CTLog(CTLOG_LEVEL_INFO,@"=============Fixture using teardown");
    
    return YES;
}

- (CTCommandCollection *)commmandDescriptors
{

    CTCommandCollection *collection = [CTCommandCollection new];

    //连接网口
    CTCommandDescriptor *command = [[CTCommandDescriptor alloc] initWithName:@"waitforRealStart" selector:@selector(waitforRealStart:) description:@"wait for Real Start"];
    [collection addCommand:command];
    
    //等待治具双启或设备开始信号
    command = [[CTCommandDescriptor alloc] initWithName:@"waitforFixtureStart" selector:@selector(waitforFixtureStart:) description:@"wait for Fixture Start"];
    [collection addCommand:command];
    
    //复位
    command = [[CTCommandDescriptor alloc] initWithName:@"waitforRealFinsh" selector:@selector(waitforRealFinsh:) description:@"wait for Real Finsh"];
     [collection addCommand:command];
    
    //发送命令
    command = [[CTCommandDescriptor alloc] initWithName:@"mainBoardCommand" selector:@selector(mainBoardCommand:) description:@"main Board Command"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"clickStartButton" selector:@selector(clickStartButton:) description:@"click Start Button"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"removePassNum" selector:@selector(removePassNum:) description:@"removePassNum"];
    [collection addCommand:command];
    
    
    return collection;
}

#pragma mark-------wait for Real Start
- (void)waitforRealStart:(CTTestContext *)context
{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error)
    {
        while (1)
        {

            BOOL  isMainPortConnect = [self.wdSyncSocket connectToServerIPAddress:[self.plistOperator readValueForKey:@"mainBoardIP"] port:[self.plistOperator readValueForKey:@"mainBoardPort"].intValue timeout:5.0 terminator:@"@_@" dataTerminator:@"OK@_@"];
        
            if (isMainPortConnect)
            {
                CTLog(CTLOG_LEVEL_ALERT,@"Main Board Connect Success!");
                break;
            }
            else
            {
                i++;
                if(i >= 2)
                {
                    CTLog(CTLOG_LEVEL_INFO, @"Main Board Connect Fail！");
                
                    return CTRecordStatusError;
                }
                else
                {
                    [NSThread sleepForTimeInterval:0.01];
                }
            }
    }
        return CTRecordStatusPass;
    }];
}

#pragma mark-------wait for Fixture Start
- (void)waitforFixtureStart:(CTTestContext *)context
{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error)
     {
         int i=0;
         while (1)
         {
             sleep(1);
             CTLog(CTLOG_LEVEL_INFO, @"wait for start...");
//             if([[self.wdSyncSocket sendCommand:@"ctrl_start\r\n" timeout:5.0]
//                 containsString:@"OK@_@\r\n"])
//             {
//                 break;
//             }
             
             if([[self.wdSyncSocket sendCommand:@"FIXTURE_START\r\n" timeout:5.0]
                 containsString:@"OK@_@\r\n"])
             {
                 break;
             }
             
             i++;
             if(i == 20)
             {
                 return  CTRecordStatusError;
             }
         }
         return CTRecordStatusPass;
     }];
}


#pragma mark-------wait for Real Finsh
- (void)waitforRealFinsh:(CTTestContext *)context
{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error)
     {
         
         
         [self.wdSyncSocket sendCommand:[self.plistOperator readValueForKey:@"reset_ctrlboard"] timeout:5.0];

//         while (1)
//         {
//             
//             if ([[self.wdSyncSocket sendCommand:[self.plistOperator readValueForKey:@"reset_ctrlboard"] timeout:5.0]
//                  containsString:@"OK@_@\r\n"] )
//             {
//                 break;
//             }
//             else
//             {
//                 i++;
//                 if(i >= 2)
//                 {
//                     CTLog(CTLOG_LEVEL_INFO, @"Finish Test,Cylinder_off Fail");
//            
//                     return CTRecordStatusError;
//                 }
//                 else
//                 {
//                     [NSThread sleepForTimeInterval:0.01];
//                 }
//             }
//         }

         return CTRecordStatusPass;
     }];
}

#pragma mark-------main Board Command
- (void)mainBoardCommand:(CTTestContext *)context
{
    float delay = [context.parameters[@"Delay"] floatValue];
    NSString * command       =  context.parameters[@"Command"];
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        NSString *response = [self.wdSyncSocket sendCommand:command timeout:2.0];
        usleep(1000*delay);
        CTLog(CTLOG_LEVEL_INFO,@"Fixture send:%@,response:%@",command,response);
        return CTRecordStatusPass;
    }];
}

-(void)clickStartButton:(CTTestContext *)context{
    
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            double time = 0.0;
            while(YES)
            {
                //[NSThread sleepForTimeInterval:0.1];
                usleep(100*1000);
                time += 0.1;
                CTLog(CTLOG_LEVEL_INFO,@"********%@*********",[NSString stringWithFormat:@"%.1f",time]);
                if([[NSString stringWithFormat:@"%.1f",time]isEqualToString:@"6.0"])
                {
                    [self handleFixtureStartDetected];
                    
                    break;
                }
                
                if([[[NSUserDefaults standardUserDefaults]objectForKey:@"clickButton"]isEqualToString:@"YES"])
                {
                    break;
                }
                
            }
            
        });
        
        
        return CTRecordStatusPass;
    }];
}

- (void)handleFixtureStartDetected
{
    NSMutableArray *array = [[NSMutableArray alloc]initWithCapacity:2];
    for (int i = 0; i<2;i++) {
        
        NSString *identifier = [NSString stringWithFormat:@"Unit %d",i+1];
        NSDictionary *userInfo = @{@"":@""};
        CTUnitEnvironment environment = CTUnitEnvironment_EFI;
        
        NSArray *unitTransports = @[@""];
        
        NSArray *unitComponentTransports = @[@""];
        
        CTUnit *unit = [[CTUnit alloc] initWithIdentifier:identifier
                                                     uuid:[NSUUID UUID]
                                              environment:environment
                                           unitTransports:unitTransports
                                      componentTransports:unitComponentTransports
                                                 userInfo:userInfo];
        
        [array addObject:unit];
    }
    [self.ctx groupAppeared:@"group1" units:array];
}

- (void)removePassNum:(CTTestContext *)context
{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
      
        [[NSUserDefaults standardUserDefaults]setObject:@""forKey:@"passNum"];
        return CTRecordStatusPass;
    }];
}

@end
