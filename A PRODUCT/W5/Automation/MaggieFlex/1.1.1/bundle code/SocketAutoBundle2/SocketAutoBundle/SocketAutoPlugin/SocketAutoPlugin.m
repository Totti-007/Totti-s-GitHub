/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 */

#import "SocketAutoPlugin.h"
#import "ZMQObjC.h"

//Call plugin params
#define kMode           @"mode"
#define kIp             @"ip"
#define kPort           @"port"
#define kTimeOut        @"timeOut"
#define kCommand        @"cmd"
#define kDelay          @"delay" //delay seconds after connected
#define kReplyDic       @"replyDic" //the dictionary reply for server mode

//station report plugin
#define kStartTime    @"startTime"
#define kUnit         @"unit"
#define kFailures     @"failures"
#define kSerialNumber @"serialNumber"
#define kFailures     @"failures"
#define kRecords      @"records"
#define kTestName     @"testName"

@interface SocketAutoPlugin()
{
    //Queue for reply socket
    dispatch_queue_t _replyQueue;
    NSLock *_lock;
}

@property (nonatomic,strong) ZMQContext *zmqCTX1;
@property (atomic,strong) ZMQSocket *zmqSocket1;

@property (nonatomic,strong) AsyncSocket *asyncSocket;

//test flag 0x00:"IDLE" 0x01:"TESTING" 0x02:"FINISHED;Unit-01:PASS;Unit-02:FAIL"
@property (atomic,assign) int _test_flag;
@property (nonatomic,strong) NSString *resultMsg;
@property (nonatomic,strong) NSMutableArray *resultArr;
@property (nonatomic,assign) int unitFininshedCount;;

//#------------------------------------------------------------------
//@property (nonatomic,strong) CTContext *myContext;
//generator group
@property (strong, nonatomic) NSString *instanceID;
@property (assign, nonatomic) int numberOfUnits;
@property (assign, nonatomic) int numberOfGroups;
@property (strong, nonatomic) NSMutableSet *ownedIdentifiers;
@property (atomic,strong) NSMutableString *message;
@property (nonatomic,strong) NSMutableDictionary *snDic;
@property (nonatomic,strong) NSString *testMode;

// Internal dictionary tracking all unit info keyed off UUID
@property NSMutableDictionary *allUnitInfo;
@property NSFileHandle *fileHandle;
@property CTContext *context;
@property NSDateFormatter *startFormatter;
@end

@implementation SocketAutoPlugin

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        // enter initialization code here
        _replyQueue=dispatch_queue_create("com.reply.socket", DISPATCH_QUEUE_SERIAL);
        self._test_flag= 0x00; //0x00 -- IDLE; 0x01 -- TESTING; 0x02 -- FINISHED
        _lock=[[NSLock alloc] init];
        _snDic=[[NSMutableDictionary alloc] initWithCapacity:1];
        
        _instanceID = [[[NSUUID new] UUIDString] substringToIndex:6];
        _ownedIdentifiers = [NSMutableSet new];
        _testMode=@"normal";
        //station report plugin
        self.allUnitInfo = [NSMutableDictionary new];
        self.unitFininshedCount = 0;
        //zmq pub
        self.zmqCTX1=[[ZMQContext alloc] initWithIOThreads:1];
    }
    return self;
}

// For plugins that implement this method, Atlas will log the returned CTVersion
// on plugin launch, otherwise Atlas will log the version info of the bundle
// containing the plugin.
 - (CTVersion *)version
 {
     return [[CTVersion alloc] initWithVersion:@"1"
                           projectBuildVersion:@"1"
                              shortDescription:@"Socket module for auto machine"];
 }

- (BOOL)setupWithContext:(CTContext *)context error:(NSError *__autoreleasing *)error
{
    // Do plugin setup work here
    // This context is safe to store a reference of

    // Can also register for event at any time. Requires a selector that takes in one argument of CTEvent type.
    // [context registerForEvent:CTEventTypeUnitAppeared selector:@selector(handleUnitAppeared:)];
    // [context registerForEvent:@"Random event" selector:@selector(handleSomeEvent:)];
    
    /*
     params={
     "LogName":"logname.csv",
     "zmqPubPort":"10051"
     }
     */

    // This context is safe to store a reference of
    self.context = context;
    self.numberOfUnits=1;
    if (context.parameters[@"numberOfUnits"] != nil) {
        self.numberOfUnits = [context.parameters[@"numberOfUnits"] intValue];
    }
    self.numberOfGroups=1;
    if (context.parameters[@"numberOfGroups"] != nil) {
        self.numberOfGroups = [context.parameters[@"numberOfGroups"] intValue];
    }
    
    self.fileHandle = [self createStationReportFile:context];

    self.startFormatter = [NSDateFormatter new];
    [self.startFormatter setDateFormat:@"MM-dd-HH:mm:ss"];
    
    [context registerForEvent:CTEventTypeUnitStart callback:^(CTEvent *event) {
        [self handleUnitStart:event];
    }];
    [context registerForEvent:CTEventTypeUnitFinished callback:^(CTEvent *event) {
        [self handleUnitFinished:event];
    }];
    [context registerForEvent:CTEventTypeTestFinished callback:^(CTEvent *event) {
        [self handleTestFinished:event];
    }];
    
    //zmq publish logs
    NSString *zmqPubPort=@"10051";
    if (context.parameters[@"zmqPubPort"] != nil) {
        zmqPubPort = context.parameters[@"zmqPubPort"];
    }
    [self initZmqPub:zmqPubPort];
    
    return YES;
}
-(void)initZmqPub:(NSString *)port{
    NSString *endpoint=[NSString stringWithFormat:@"tcp://*:%@",port];
    CTLog(CTLOG_LEVEL_INFO, @"[breakpoint]......001");
    self.zmqSocket1=[self.zmqCTX1 socketWithType:ZMQ_PUB];
    CTLog(CTLOG_LEVEL_INFO, @"[breakpoint]......002");
    BOOL didBind=[self.zmqSocket1 bindToEndpoint:endpoint];
    CTLog(CTLOG_LEVEL_INFO, @"[breakpoint]......003");
    if (!didBind) {
        [self.zmqCTX1 terminate];
        CTLog(CTLOG_LEVEL_INFO, @"!!!Failed to bind to endpoint:%@",endpoint);
        
    }else{
        CTLog(CTLOG_LEVEL_INFO, @"zmq pub socket start OK");
        [NSThread sleepForTimeInterval:0.1];
    }
}
- (BOOL)teardownWithContext:(CTContext *)context error:(NSError *__autoreleasing *)error
{
    [self printLog:@"teardown plugin"];

    [self.fileHandle closeFile];
    //zmq
    [self.zmqCTX1 closeSockets];
    [self.zmqCTX1 terminate];
    return YES;
}

- (CTCommandCollection *)commmandDescriptors
{
    // Collection contains descriptions of all the commands exposed by a plugin
    CTCommandCollection *collection = [CTCommandCollection new];
    // A command exposes its name, the selector to call, and a short description
    // Selector should take in one object of CTTestContext type
    CTCommandDescriptor *command = [CTCommandDescriptor new];
    // open
    command = [[CTCommandDescriptor alloc] initWithName:@"open"
                                               selector:@selector(open:)
                                            description:@"Client mode:connect server/Server mode:open self"];
    [command addParameter:kMode type:CTParameterDescriptorTypeString
             defaultValue:@"client" allowedValues:nil required:YES
              description:@"the mode of the socket:client/server"];
    [command addParameter:kIp type:CTParameterDescriptorTypeString
             defaultValue:@"127.0.0.1" allowedValues:nil required:YES
              description:@"the ip address of the socket"];
    [command addParameter:kPort type:CTParameterDescriptorTypeNumber
             defaultValue:@(8001) allowedValues:nil required:YES
              description:@"the port of the socket"];
    [command addParameter:kDelay type:CTParameterDescriptorTypeNumber
             defaultValue:@(1) allowedValues:nil required:NO
              description:@"delay seconds after socket connected"];
    [collection addCommand:command];
    // close
    command = [[CTCommandDescriptor alloc] initWithName:@"close"
                                               selector:@selector(close:)
                                            description:@"close the socket channel"];
    [collection addCommand:command];
    // send
    command = [[CTCommandDescriptor alloc] initWithName:@"send"
                                               selector:@selector(send:)
                                            description:@"send a command pass the socket channel"];
    [command addParameter:kCommand type:CTParameterDescriptorTypeString
             defaultValue:nil allowedValues:nil required:YES
              description:@"the command will be send pass socket channel"];
    [collection addCommand:command];
    // query
    command = [[CTCommandDescriptor alloc] initWithName:@"query"
                                               selector:@selector(query:)
                                            description:@"read a reply pass the socket channel"];
    [command addParameter:kCommand type:CTParameterDescriptorTypeString
             defaultValue:nil allowedValues:nil required:YES
              description:@"the command will be send pass socket channel"];
    [command addParameter:kTimeOut type:CTParameterDescriptorTypeNumber
             defaultValue:@(2) allowedValues:nil required:YES
              description:@"the timeout seconds wait for reply of the socket channel"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"getSNs"
                                               selector:@selector(getSNs:)
                                            description:@"Get SNs message from scan sn form"];
    
    [collection addCommand:command];
    

    return collection;
}

-(void)getSNs:(CTTestContext *)context
{
    if(context.parameters[@"mode"] != nil){
        _testMode=context.parameters[@"mode"];
        CTLog(CTLOG_LEVEL_INFO, @"====[UIManual]===receive test mode:%@",_testMode);
    }
    //manual scan SN *just for testing
    //[self popupScanForm:context];
    
    CTRecordStatus status=CTRecordStatusPass;
    if (_snDic == nil) {
        status=CTRecordStatusFail;
    }
    context.output=_snDic;
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        NSError *err = nil;
        NSError *failureInfoError = [NSError errorWithDomain:@"getSNsError" code:1 userInfo:@{NSLocalizedDescriptionKey : @"fail to get SN message from scan form"}];
        CTRecord *record = [[CTRecord alloc]initPassFailRecordWithNames:@[@"getSNs"]
                                                                 status:status
                                                            failureInfo:failureInfoError
                                                               priority:CTRecordPriorityRequired
                                                              startTime:[NSDate date]
                                                                endTime:[NSDate date]
                                                                  error:&err];
        
        
        [context.records addRecord:record error:&err];
        
        return CTRecordStatusPass;
    }];
    
}
-(void)open:(CTTestContext *)context{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        NSDictionary *params=context.parameters;
        NSString *mode=params[kMode]==nil?@"server":params[kMode];
        NSString *ip=params[kIp]==nil?@"127.0.0.1":params[kIp];
        int port=params[kPort]==nil?8001:[params[kPort] intValue];
        double delay=params[kDelay]==nil?2.0:[params[kDelay] doubleValue];
        
        //async socket channel
        self.asyncSocket = [[AsyncSocket alloc] init];
        self.asyncSocket.ip = ip;
        self.asyncSocket.port = port;
        self.asyncSocket.mode = mode;
        self.asyncSocket.delegate = self;
        
        
        if ([self.asyncSocket open]) {
            return CTRecordStatusPass;
        }
        
        return CTRecordStatusFail;
    }];
}
-(void)close:(CTTestContext *)context{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        if ([self.asyncSocket close]) {
            return CTRecordStatusPass;
        }
        return CTRecordStatusFail;
    }];
}
-(void)send:(CTTestContext *)context{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        NSString *cmd=context.parameters[@"cmd"];
        if ([self.asyncSocket sendCmd:cmd]) {
            return CTRecordStatusPass;
        }
        return CTRecordStatusFail;
    }];
}
-(void)query:(CTTestContext *)context{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        NSString *cmd=context.parameters[@"cmd"];
        double to=context.parameters[@"timeout"] == nil ? 2.0 : [context.parameters[@"timeout"] doubleValue];
        NSString *response = [self.asyncSocket query:cmd timeout:to];
        context.output = response;
        if ([response isEqualToString:@""]) {
            return CTRecordStatusFail;
        }
        return CTRecordStatusPass;
    }];
}

#pragma mark ---trigger start testing

-(void)popupScanForm:(CTContext *)context{
    NSString *cmd=@"show-form";
    NSMutableArray *layout=[NSMutableArray new];
    for (int i=1; i<_numberOfUnits+1; i++) {
        NSString *text=[NSString stringWithFormat:@"Unit-%d",i];
        NSDictionary *label=@{@"type":@"label",@"text":text};
        NSDictionary *type=@{@"type":@"field",@"id":text};
        [layout addObject:label];
        [layout addObject:type];
        
    }
    NSDictionary *params=@{@"type" : @"custom", @"layout" : layout};
    NSError *failureInfo;
    _snDic=[context callAppWithCommand:cmd parameters:params error:&failureInfo];
    CTLog(CTLOG_LEVEL_INFO, @"===[SocketAuto]===scan sn snDic:%@",_snDic);
}
-(void)showStartDialogForm:(CTContext *)context{
    NSString *cmd=@"show-form";
    NSDictionary *params=@{@"type" : @"message", @"message" : @"Start"};
    NSError *failureInfo;
    [context callAppWithCommand:cmd parameters:params error:&failureInfo];
    CTLog(CTLOG_LEVEL_INFO, @"====[SocketAuto]===show start form dialog");
}

# pragma gerenator group
- (NSArray *) createUnits:(int)numUnits withSuffix:(NSString *)suffix
{
    NSMutableArray *units = [NSMutableArray new];
    
    // Creates Requested Number of Units.
    for (int unitItr = 1; unitItr < numUnits+1; unitItr += 1) {
        NSUUID *uuid = [NSUUID new];
        NSString *unitName = [NSString stringWithFormat:@"Unit-%d", unitItr];
        
        //        if (suffix)
        //        {
        //            unitName = [NSString stringWithFormat:@"%@ %@", unitName, suffix];
        //        }
        
        CTUnit *unit = [[CTUnit alloc] initWithIdentifier:unitName
                                                     uuid:uuid
                                              environment:CTUnitEnvironment_custom
                                           unitTransports:nil
                                      componentTransports:nil
                                                 userInfo:nil];
        unit.userInfo[@"slot"] = @(unitItr);
        NSString *ipStr=[NSString stringWithFormat:@"169.254.1.%d",31+unitItr];
        unit.userInfo[@"ip"]=ipStr;
        
        [units addObject:unit];
    }
    
    return units;
}
-(void)testProgressGo{
    [self setupDisappearFunc];
    [NSThread sleepForTimeInterval:0.5];
    [self setupGeneratorFunc];
}

-(void)setupGeneratorFunc{
    @autoreleasepool
    {
        NSMutableArray *groups = [NSMutableArray new];
        for (int groupItr = 1; groupItr < self.numberOfGroups+1; groupItr++)
        {
            NSString *unitSuffix = [NSString stringWithFormat:@"(%@)", self.instanceID];
            NSString *groupID = [NSString stringWithFormat:@"Group-%d", groupItr];
            NSArray *units = [self createUnits:self.numberOfUnits withSuffix:unitSuffix];
            [self.context groupAppeared:groupID units:units];
            [groups addObject:groupID];
        }
        [self addIdentifiers:groups];
        CTLog(CTLOG_LEVEL_INFO, @"====[UIManual]======finish setupGeneratorFunc");
    }
    
}
-(void)setupDisappearFunc{ 
    @autoreleasepool {
        [self printLog:[self.ownedIdentifiers description]];
        int64_t delayIntervalNano = (int64_t)(0.1 * (double)NSEC_PER_SEC);
        for (NSString *identifier in self.ownedIdentifiers) {
            if ([self containIdentifier:identifier]) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayIntervalNano), dispatch_get_main_queue(), ^{
                    [self removeIdentifier:identifier];
                    [self.context groupDisappeared:identifier];
                });
            }
        }
    }
//    @autoreleasepool {
//        for (NSString *identifier in self.ownedIdentifiers) {
//            [self removeIdentifier:identifier];
//
//            [self.context groupDisappeared:identifier];
//        }
//    }
    
}
- (void) addIdentifiers:(NSArray *)identifierList
{
    @synchronized (self.ownedIdentifiers) {
        [self.ownedIdentifiers addObjectsFromArray:identifierList];
    }
}
- (void) removeIdentifier:(NSString *)identifier
{
    @synchronized (self.ownedIdentifiers) {
        [self.ownedIdentifiers removeObject:identifier];
    }
}

- (BOOL) containIdentifier:(NSString *)identifier
{
    @synchronized (self.ownedIdentifiers) {
        return [self.ownedIdentifiers containsObject:identifier];
    }
}

#pragma mark--- Asyncsocket delegate
- (void)receiveDataFromSocket:(nonnull NSData *)data socket:(nonnull GCDAsyncSocket *)socket{
    dispatch_async(_replyQueue, ^{
        NSData *r_data=[data mutableCopy];
        [self replySerialTask:r_data socket:socket];
    });
}

-(void)replySerialTask:(NSData *)data socket:(GCDAsyncSocket *)socket{
    NSString *recStr=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    recStr=[recStr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    recStr=[recStr stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    recStr=[recStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *msg=[NSString stringWithFormat:@"[RX]:%@",recStr];
    [self printLog:msg];
    
    NSString *test_status=@"NG";
    NSString *message=[recStr uppercaseString];
    if ([message hasPrefix:@"SN:"] && self._test_flag != 0x01) {
        NSString *tmpStr=[message componentsSeparatedByString:@":"][1];
        NSArray *snArr=[tmpStr componentsSeparatedByString:@";"];
        _snDic=[NSMutableDictionary dictionaryWithCapacity:[snArr count]];
        for (int i=0; i<[snArr count]; i++) {
            if ([snArr[i] length] > 0) {
                [_snDic setObject:snArr[i] forKey:[NSString stringWithFormat:@"Unit-%d",i+1]];
            }
        }
         CTLog(CTLOG_LEVEL_INFO, @"===[SocketAuto]===get snDic:%@",_snDic);
        //generate group for starting test
        [NSThread detachNewThreadSelector:@selector(testProgressGo) toTarget:self withObject:nil];
        //[self setupGeneratorFunc];
        //[self testProgressGo];
        test_status=@"OK";
    }else if([message isEqualToString:@"STATUS"]){
        if (0x00 == self._test_flag) {
            test_status=@"IDLE";
        }else if(0x01 == self._test_flag){
            test_status=@"TESTING";
        }else if(0x02 == self._test_flag){
            test_status=[@"FINISHED;" stringByAppendingString:_resultMsg];
        }else{
            test_status=@"UNKNOWN";
        }
    }else{
        test_status=@"CMD ERR";
    }
    
    NSData *newData=[test_status dataUsingEncoding:NSUTF8StringEncoding];
    //回复 测试状态
    [socket writeData:newData withTimeout:3 tag:300];
    //[self.asyncSocket sendCmd:test_status];
    
    msg=[NSString stringWithFormat:@"[TX]:%@",test_status];
    [self printLog:msg];
}

-(void)printLog:(NSString *)log{
    CTLog(CTLOG_LEVEL_INFO, @"[SocketAutoPlugin]%@",log);
    NSData *dataMsg = [log dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    BOOL ok = [self.zmqSocket1 sendData:dataMsg withFlags:0];
    if (!ok) {
        CTLog(CTLOG_LEVEL_INFO, @"failed to pub msg:%@",log);
    }
}
#pragma mark-- -- -- station report plugin

- (NSFileHandle *)attemptFileOpen:(NSString *)fileName
{
    CTLog(CTLOG_LEVEL_INFO, @"Attempting to open file: %@", fileName);

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:fileName];
    
    BOOL fileIsExist = YES;
    // Attempt to create the file once
    if(!fileHandle)
    {
        [[NSFileManager defaultManager] createFileAtPath:fileName contents:nil attributes:nil];
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:fileName];
        fileIsExist = NO;
    }

    [fileHandle seekToEndOfFile];
    if (NO == fileIsExist) {
        // serialNum, result, failure message, Time started, totalTime, slot-ID, UUID
        [self writeString:@"serialNum, result, failure message, Time started, totalTime, slot-ID, UUID\n" toFile:fileHandle];
    }
    return fileHandle;
}
- (NSFileHandle *)createStationReportFile:(CTContext *)context
{
    //NSString *logPath = [context.workingDirectory path];
    NSString *strYYYYMM=[self getCurrentMonth];
    NSString *strYYYYMMDD=[self getCurrentDate];
    NSString *strYYYYMMDDHH=[self getCurrentHourSuffix];
    NSString *logPath = [NSString stringWithFormat:@"/vault/Atlas/AutoLogs/%@/%@",strYYYYMM,strYYYYMMDD];
    NSString *toAppend = context.parameters[@"LogName"];
    
    BOOL isDir = NO;
    NSError *errMsg;
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL bDirExist = [fm fileExistsAtPath:logPath isDirectory:&isDir];
    if (!(bDirExist == YES && isDir == YES))
    {
        if (NO == [fm createDirectoryAtPath:logPath withIntermediateDirectories:YES attributes:nil error:&errMsg]){
            [self printLog:@"ERROR!Can't create directory!"];
        }
            //return NO;
    }

    if (!toAppend)
    {
        toAppend = @"autoLogs--";

        NSDateFormatter *formatter = [NSDateFormatter new];
        [formatter setDateFormat:@"MM-dd--HH-mm-ss"];

        toAppend = [toAppend stringByAppendingString:[formatter stringFromDate:[NSDate date]]];
        toAppend = [toAppend stringByAppendingString:@".csv"];
    }
    toAppend = [NSString stringWithFormat:@"%@_%@",strYYYYMMDDHH,toAppend];
    logPath = [logPath stringByAppendingPathComponent:toAppend];

    NSFileHandle *handle = [self attemptFileOpen:logPath];
    CTLog(CTLOG_LEVEL_INFO, @"==>>logPath:%@",logPath);
    
    return handle;
}

- (NSMutableDictionary *)safelyGetUnitDictionary:(CTUnit *)thisUnit
{
    if (self.allUnitInfo[thisUnit.uuid])
    {
        return self.allUnitInfo[thisUnit.uuid];
    }

    NSMutableDictionary *unitInfo = [NSMutableDictionary new];

    unitInfo[kStartTime] = [NSDate date];
    unitInfo[kUnit] = thisUnit;
    unitInfo[kFailures] = [NSMutableArray new];

    self.allUnitInfo[thisUnit.uuid] = unitInfo;

    return unitInfo;
}

- (void)handleTestFinished:(CTEvent *)eventInfo
{
    //[self printLog:@"[auto]----CTEventTypeTestFinished"];
    // CTEventUnitKey
    // CTEventContextUUIDKey
    // CTEventTestNameKey
    // CTEventTestRecordsKey
    NSMutableDictionary *thisUnitInfo = [self safelyGetUnitDictionary:[eventInfo getUnit]];
    CTRecordSet *thisRecordSet = eventInfo.userInfo[CTEventTestRecordsKey];

    CTRecordStatus status = thisRecordSet.overallRecordStatus;
    if (!thisRecordSet || status == CTRecordStatusFail || status == CTRecordStatusError || status == CTRecordStatusUnitPanic || status == CTRecordStatusNotSet)
    {
        NSMutableArray *failures = thisUnitInfo[kFailures];
        [failures addObject:@{kRecords:thisRecordSet ? thisRecordSet : [NSNull null],
                              kTestName:eventInfo.userInfo[CTEventTestNameKey]}];
    }

    if (thisRecordSet.deviceAttributes[CTDeviceAttributeSerialNumber])
    {
        thisUnitInfo[kSerialNumber] = thisRecordSet.deviceAttributes[CTDeviceAttributeSerialNumber];
    }

}

- (void)handleUnitStart:(CTEvent *)eventInfo
{
    [self printLog:@"[auto]----CTEventTypeUnitStart"];
    
    CTUnit *thisUnit = [eventInfo getUnit];
    NSString *info=[NSString stringWithFormat:@"Unit started: %@ %@",thisUnit.identifier,thisUnit.uuid];
    CTLog(CTLOG_LEVEL_DEBUG, @"%@",info);
    [self printLog:info];

    // Will automatically configure with the "start unit" settings
    [self safelyGetUnitDictionary:thisUnit];
    
    if (0x00 == self._test_flag || 0x02 == self._test_flag) {
        self._test_flag = 0x01;
        self.unitFininshedCount = 0;
        self.resultMsg = @"";
    }
}

- (void)handleUnitFinished:(CTEvent *)eventInfo
{
    [self printLog:@"[auto]----CTEventTypeUnitFinished"];
    
    CTUnit *thisUnit = [eventInfo getUnit];

    NSMutableDictionary *thisUnitInfo = [self safelyGetUnitDictionary:thisUnit];

    [self reportSequenceFinished:thisUnitInfo];

    // Clear out the entry
    self.allUnitInfo[thisUnit.uuid] = nil;

    self.unitFininshedCount += 1;
    NSString *thisUnitResult = @"FAIL";
    if ([thisUnitInfo[kFailures] count] == 0){
        thisUnitResult = @"PASS";
    }
    NSString *info = [NSString stringWithFormat:@"Unit finished:%@ %@",[eventInfo getUnit].identifier,thisUnitResult];
    CTLog(CTLOG_LEVEL_DEBUG, @"%@",info);
    [self printLog:info];
    
    NSString *tempStr=[NSString stringWithFormat:@"%@:%@;",thisUnit.identifier,thisUnitResult];
    self.resultMsg = [self.resultMsg stringByAppendingString:tempStr];
    if (self.unitFininshedCount == self.numberOfUnits) {
        [self printLog:@"======All units finished!======"];
        [self printLog:self.resultMsg];
        self._test_flag = 0x02;
    }
}

- (BOOL)reportSequenceFinished:(NSDictionary *)unitDictionary
{

    CTUnit *thisUnit = unitDictionary[kUnit];
    NSString *startTime = [self.startFormatter stringFromDate:unitDictionary[kStartTime]];
    NSString *timeElapsed = [NSString stringWithFormat:@"%1.2f", [[NSDate date] timeIntervalSinceDate:unitDictionary[kStartTime]]];
    NSString *uuid = [thisUnit.uuid UUIDString];
    NSString *serialNum = unitDictionary[kSerialNumber];
    NSString *identifier = thisUnit.identifier;

    // serialNum, result, failure message, Time started, totalTime, slot-ID, UUID
    NSMutableString *singleLine = [NSMutableString new];
    
    if ([serialNum isEqualToString:@""] || [serialNum isEqual:nil]) {
        serialNum = @"NA";
    }
    [self appendCSVValue:serialNum toString:singleLine];
    [self addAllFailures:unitDictionary[kFailures] toString:singleLine];
    [self appendCSVValue:startTime toString:singleLine];
    [self appendCSVValue:timeElapsed toString:singleLine];
    [self appendCSVValue:identifier toString:singleLine];
    [self appendCSVValue:uuid toString:singleLine];

    [singleLine appendString:@"\n"];

    return [self writeString:singleLine toFile:self.fileHandle];
}

- (void)addAllFailures:(NSArray *)allFailures toString:(NSMutableString *)thisLine
{
    if ([allFailures count] == 0)
    {
        // TODO: Log relaxed pass differently
        [self appendCSVValue:@"PASS," toString:thisLine];
        return;
    }

    // TODO: Log different failures
    [self appendCSVValue:@"FAIL" toString:thisLine];

    for (NSDictionary *failure in allFailures)
    {
        [self appendCSVValue:failure[kTestName] toString:thisLine];
    }
}

- (void)appendCSVValue:(NSString *)newValue toString:(NSMutableString *)thisLine
{
    // TODO: Nice spacing for more readable CSV's?
    if (newValue)
    {
        [thisLine appendString:newValue];
    }
    [thisLine appendString:@","];
}

- (BOOL)writeString:(NSString *)str toFile:(NSFileHandle *)fileHandle
{
    if (!fileHandle)
    {
        return NO;
    }

    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    @try
    {
        @synchronized (fileHandle)
        {
            [fileHandle writeData:data];
        }
    }
    @catch (NSException *exception)
    {
        CTLog(CTLOG_LEVEL_ERR, @"Failed to write data to non-nil file handle");
        return NO;
    }

    return YES;
}
//2019_01
- (NSString *) getCurrentMonth
{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY_MM"];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    return currentTime;
}
//2019_01_21
- (NSString *) getCurrentDate
{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY_MM_dd"];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    return currentTime;
}
//2019_01_21_10
-(NSString *)getCurrentHourSuffix{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY_MM_dd_HH"];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    return currentTime;
}


@end
