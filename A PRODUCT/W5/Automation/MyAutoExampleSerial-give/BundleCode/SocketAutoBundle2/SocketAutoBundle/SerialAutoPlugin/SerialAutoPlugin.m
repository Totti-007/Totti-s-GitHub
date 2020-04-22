/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 */

#import "SerialAutoPlugin.h"
#import "ZMQObjC.h"

//station report plugin
#define kStartTime    @"startTime"
#define kUnit         @"unit"
#define kFailures     @"failures"
#define kSerialNumber @"serialNumber"
#define kFailures     @"failures"
#define kRecords      @"records"
#define kTestName     @"testName"

@interface SerialAutoPlugin()
{
    //Queue for reply socket
    dispatch_queue_t _replyQueue;
    NSLock *_lock;
}

@property (nonatomic,strong) ZMQContext *zmqCTX1;
@property (atomic,strong) ZMQSocket *zmqSocket1;

@property (nonatomic,strong) Serial *mySerial;
@property (nonatomic, strong) NSMutableString *serialResponse;
@property (nonatomic,assign) int autoMachineNo;

//test flag 0x00:"IDLE" 0x01:"TESTING" 0x02:"FINISHED;Unit-01:PASS;Unit-02:FAIL"
@property (nonatomic,assign) int _test_flag;
@property (nonatomic,strong) NSString *resultMsg;
@property (nonatomic,strong) NSMutableDictionary *resultDic;
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

@implementation SerialAutoPlugin

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
        self.resultDic = [[NSMutableDictionary alloc] initWithCapacity:1];
        
        _instanceID = [[[NSUUID new] UUIDString] substringToIndex:6];
        _ownedIdentifiers = [NSMutableSet new];
        _testMode=@"normal";
        //station report plugin
        self.allUnitInfo = [NSMutableDictionary new];
        self.unitFininshedCount = 0;
        //zmq pub
        self.zmqCTX1=[[ZMQContext alloc] initWithIOThreads:1];
        
        //serial
        self.mySerial = [[Serial alloc] init];
        self.serialResponse=[NSMutableString new];
        self.autoMachineNo = 1;
        
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
    //Serial
    if (self.mySerial != nil) {
        [self.mySerial close];
    }
    return YES;
}

- (CTCommandCollection *)commmandDescriptors
{
    // Collection contains descriptions of all the commands exposed by a plugin
    CTCommandCollection *collection = [CTCommandCollection new];
    // A command exposes its name, the selector to call, and a short description
    // Selector should take in one object of CTTestContext type
    CTCommandDescriptor *command = [CTCommandDescriptor new];
    // scan
    command = [[CTCommandDescriptor alloc] initWithName:@"scan"
                                               selector:@selector(scan:)
                                            description:@"scan the connected serial"];
    [collection addCommand:command];
    // open
    command = [[CTCommandDescriptor alloc] initWithName:@"open"
                                               selector:@selector(open:)
                                            description:@"open a serial port"];
    
    [command addParameter:@"baud" type:CTParameterDescriptorTypeNumber
             defaultValue:@(9600) allowedValues:nil required:YES
              description:@"the baudrate of serial port"];
    [command addParameter:@"port" type:CTParameterDescriptorTypeString
             defaultValue:@"/dev/tty.serial-1234" allowedValues:nil required:YES
              description:@"the port of serial port"];

    [collection addCommand:command];
    // close
    command = [[CTCommandDescriptor alloc] initWithName:@"close"
                                               selector:@selector(close:)
                                            description:@"close the socket channel"];
    [collection addCommand:command];
    // send
    command = [[CTCommandDescriptor alloc] initWithName:@"send"
                                               selector:@selector(send:)
                                            description:@"send a command pass the serial channel"];
    [command addParameter:@"cmd" type:CTParameterDescriptorTypeString
             defaultValue:nil allowedValues:nil required:YES
              description:@"the command will be send pass serial channel"];
    [collection addCommand:command];
    // query
    command = [[CTCommandDescriptor alloc] initWithName:@"query"
                                               selector:@selector(query:)
                                            description:@"read a reply pass the serial channel"];
    [command addParameter:@"cmd" type:CTParameterDescriptorTypeString
             defaultValue:nil allowedValues:nil required:YES
              description:@"the command will be send pass serial channel"];
    [command addParameter:@"timeOut" type:CTParameterDescriptorTypeNumber
             defaultValue:@(2) allowedValues:nil required:YES
              description:@"the timeout seconds wait for reply of the serial channel"];
    [collection addCommand:command];
    
    return collection;
}

//scan
-(void)scan:(CTTestContext *)context{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        NSArray *serialList=[self.mySerial scan];
        context.output = serialList;
        [self printLog:[serialList description]];
        return CTRecordStatusPass;
    }];
}

//open
-(void)open:(CTTestContext *)context{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        NSDictionary *params=context.parameters;
        
        self.mySerial.port = @"NA";
        self.mySerial.baudrate = params[@"baud"];
        self.mySerial.delegate = self;
        //自动获取mac mini 串口
        NSArray *serialList=[self.mySerial scan];
        for (NSString *port in serialList) {
            if ([port containsString:@"LISAFCT"]) {
                self.mySerial.port = port;
                break;
            }
        }
        [self printLog:[NSString stringWithFormat:@"[SerialAuto]==>>port:%@",self.mySerial.port]];
        if ([self.mySerial.port isEqualToString:@"NA"]) {
            context.output = @"NG";
            return CTRecordStatusFail;
        }
        //判断治具编号
        if ([self.mySerial.port containsString:@"LISAFCT2"]) {
            self.autoMachineNo = 2;
        }
        [self printLog:[NSString stringWithFormat:@"[SerialAuto]==>>Fixture ID:%d",self.autoMachineNo]];
        //打开串口
        BOOL status = [self.mySerial open];
        [self printLog:[NSString stringWithFormat:@"open serial status:%hhd",status]];
        
        if (YES == status) {
            context.output = @"OK";
            return CTRecordStatusPass;
        }
        context.output = @"NG";
        
        return CTRecordStatusFail;
    }];
}

//close
-(void)close:(CTTestContext *)context{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        if ([self.mySerial close]) {
            return CTRecordStatusPass;
        }
        return CTRecordStatusFail;
    }];
}

//send
-(void)send:(CTTestContext *)context{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        NSString *cmd=context.parameters[@"cmd"];
        if ([self.mySerial sendCmd:cmd]) {
            return CTRecordStatusPass;
        }
        return CTRecordStatusFail;
    }];
}

//query
-(void)query:(CTTestContext *)context{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        NSString *cmd=context.parameters[@"cmd"];
        double to=context.parameters[@"timeout"] == nil ? 2.0 : [context.parameters[@"timeout"] doubleValue];
        NSString *response = [self.mySerial query:cmd timeout:to];
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
        unit.userInfo[@"dut_sn"] = [_snDic objectForKey:unitName];
        
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

#pragma mark--- serial delegate
- (void)receivedDataFromSerial:(nonnull NSData *)data {
    NSString *recStr=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self.serialResponse appendString:recStr];
    if ([self.serialResponse hasSuffix:@"\n"]) {
        dispatch_async(_replyQueue, ^{
            NSString *r_data=[self.serialResponse mutableCopy];
            [self replySerialTask:r_data];
        });
        
    }
    
}

-(void)replySerialTask:(NSString *)response{
    self.serialResponse = [NSMutableString new];
    NSString *recStr=response;
    recStr=[recStr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    recStr=[recStr stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    recStr=[recStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *msg=[NSString stringWithFormat:@"[RX]:%@",recStr];
    [self printLog:msg];
    
    NSString *test_status=@"NG";
    NSString *message=[recStr uppercaseString];
    //SN1:DLC123456,SN2:DLC456123\r\n
    if ([message hasPrefix:@"SN1:"] && self._test_flag != 0x01) {
        NSArray *tempArr=[message componentsSeparatedByString:@","];
        if ([tempArr count] == self.numberOfUnits) {
            NSMutableArray *snArr=[NSMutableArray new];
            [snArr addObject:[tempArr[0] componentsSeparatedByString:@":"][1]];
            [snArr addObject:[tempArr[1] componentsSeparatedByString:@":"][1]];
            
            _snDic=[NSMutableDictionary dictionaryWithCapacity:[snArr count]];
            
            if (self.autoMachineNo == 1) {
                [_snDic setObject:snArr[0] forKey:@"Unit-1"];
                [_snDic setObject:snArr[1] forKey:@"Unit-2"];
            }else{
                [_snDic setObject:snArr[1] forKey:@"Unit-1"];
                [_snDic setObject:snArr[0] forKey:@"Unit-2"];
            }
            
             CTLog(CTLOG_LEVEL_INFO, @"===[SerialAuto]===get snDic:%@",_snDic);
            
            [self printLog:[NSString stringWithFormat:@"==>>[SerialAuto]==>>FIX_ID:%d snDic:%@",self.autoMachineNo,[_snDic description]]];
            
            if([[_snDic allKeys] count] == self.numberOfUnits){
                [NSThread detachNewThreadSelector:@selector(testProgressGo) toTarget:self withObject:nil];
                test_status=@"OK";
            }else{
                test_status=@"NG";
            }
        }
        
    }else if([message isEqualToString:@"STATUS"]){
        if (0x00 == self._test_flag) {
            test_status=@"IDLEA";
        }else if(0x01 == self._test_flag){
            test_status=@"TESTING";
        }else if(0x02 == self._test_flag){
            //Status:PASS_,PASS_;
            test_status=[@"Status:" stringByAppendingString:_resultMsg];
        }else{
            test_status=@"UNKNOWN";
        }
    }else{
        test_status=@"CMD ERR";
    }
    
    //NSData *newData=[test_status dataUsingEncoding:NSUTF8StringEncoding];
    //回复 测试状态
    //test_status=[test_status stringByAppendingString:@"\r\n"];
    [self.mySerial sendCmd:test_status];
    
    msg=[NSString stringWithFormat:@"[TX]:%@",test_status];
    [self printLog:msg];
}

-(void)printLog:(NSString *)log{
    CTLog(CTLOG_LEVEL_INFO, @"[SerialAutoPlugin]%@",log);
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
        self.resultDic=[NSMutableDictionary new];
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
    
    [self.resultDic setValue:thisUnitResult forKey:thisUnit.identifier];
    
    if (self.unitFininshedCount == self.numberOfUnits) {
        [self printLog:@"======All units finished!======"];
        //Status:PASS_,PASS_;
        NSString *unitResult = [self.resultDic objectForKey:@"Unit-1"];
        self.resultMsg = [self.resultMsg stringByAppendingFormat:@"%@_,",unitResult];
        unitResult = [self.resultDic objectForKey:@"Unit-2"];
        self.resultMsg = [self.resultMsg stringByAppendingFormat:@"%@_;",unitResult];
        
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
