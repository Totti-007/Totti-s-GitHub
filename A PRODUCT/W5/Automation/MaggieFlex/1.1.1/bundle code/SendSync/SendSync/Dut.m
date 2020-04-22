/*!
 *  Copyright 2019 Apple Inc. All rights reserved.
 *
 *  APPLE NEED TO KNOW CONFIDENTIAL
 */

#import "Dut.h"
#import "WDSyncSocket.h"
#import "Function.h"
#import "GetTimeDay.h"
#import "SFC.h"
#import "csvFileOperator.h"
#import "Folder.h"
#import "PlistOperator.h"

static int i = 0;
static int timer = 0;

#define KDelay     @"Delay"
#define KTestName  @"TestName"
#define KCommand   @"Command"
#define KChoose    @"Choose"

@interface Dut()

@property(nonatomic,strong) WDSyncSocket     * wdSyncSocket;
@property(nonatomic,strong) NSString         * ip;
@property(nonatomic,strong) NSString         * length;
@property(nonatomic,strong) NSString         * softwareversion;
@property(nonatomic,assign) int              port;
@property(nonatomic,strong) PlistOperator    * plistOperator;

@property(nonatomic,assign) BOOL             isShortOK;        //是否有短路
@property(nonatomic,strong) Function         * function;
@property(nonatomic,strong) Folder           * fold;
@property(nonatomic,strong) NSString         * SN;
@property(nonatomic,strong) NSString         * ID;
@property(nonatomic,strong) SFC              * sfc;
@property(nonatomic,strong) NSString         * Path;
@property(nonatomic,strong) NSString         * DataPath;
@property(nonatomic,strong) NSString         * SummaryPath;    //生成总数据文件
@property(nonatomic,strong) GetTimeDay       * timeDay;
@property(nonatomic,strong) NSString         * Unit;           //测试产品的单元
@property(nonatomic,strong) NSMutableDictionary * valueDictionary;
@property(nonatomic,strong) NSMutableArray   * NullTestData; //空测获取的8次值
@property(nonatomic,assign) BOOL               TestResult;

@property(nonatomic,strong) NSMutableString  * FailItems;
@property(nonatomic,strong) NSString         * ErrorDescription;
@property(nonatomic,strong) NSString         * startTime;
@property(nonatomic,strong) csvFileOperator  * fileOperator; //写入csv文件


@end

@implementation Dut

- (instancetype)init
{
    self = [super init];

    if (self)
    {
    }

    return self;
}

-(GetTimeDay *)timeDay{
    
    if (_timeDay == nil) {
        
        _timeDay = [GetTimeDay shareInstance];
    }
    
    return _timeDay;
    
}

-(PlistOperator *)plistOperator
{
    if (_plistOperator == nil)
    {
        _plistOperator=[[PlistOperator alloc]init];
    }
    return _plistOperator;
}

-(Folder *)fold{
    
    if (_fold == nil) {
        
        _fold = [Folder shareInstance];
    }
    
    return _fold;
    
}

-(NSMutableDictionary *)valueDictionary
{
    if (_valueDictionary == nil) {
        
        _valueDictionary = [[NSMutableDictionary alloc] init];
    }
    
    return _valueDictionary;
}

-(csvFileOperator *)fileOperator{
    
    if (_fileOperator==nil) {
        
        _fileOperator = [csvFileOperator ShareCsvFileOPerator];
    }
    return _fileOperator;
}

-(NSMutableArray *)NullTestData{
    
    if (_NullTestData==nil) {
        
        _NullTestData = [[NSMutableArray alloc] initWithCapacity:10];
    }
    
    return _NullTestData;
}


-(WDSyncSocket *)wdSyncSocket
{
    if (_wdSyncSocket == nil) {
        
        _wdSyncSocket = [[WDSyncSocket alloc]init];
    }
    
    return _wdSyncSocket;
}


- (BOOL)setupWithContext:(CTContext *)context error:(NSError *__autoreleasing *)error
{
     self.ip = context.parameters[@"ip"];
     self.port = [context.parameters[@"port"] intValue];
     self.length = context.parameters[@"fixtureUart"];
 
     self.isShortOK          = NO;
     self.TestResult         = YES;

     self.function = [[Function alloc] init];
     self.sfc      = [[SFC alloc]init];
    
     NSString  * path        = context.parameters[@"DataPath"];
     NSString  * unit        = context.parameters[@"unitID"];
    
     self.Unit         = unit;
     self.DataPath           = [NSString stringWithFormat:@"%@/%@/",path,[self.timeDay getCurrentDay]];
     self.SummaryPath        = [NSString stringWithFormat:@"%@/Summary",self.DataPath];
    self.FailItems = [[NSMutableString alloc]initWithCapacity:20];
    
     [[NSUserDefaults standardUserDefaults]setObject:@"YES" forKey:@"clickButton"];
    
     return YES;
}

- (BOOL)teardownWithContext:(CTContext *)context error:(NSError *__autoreleasing *)error
{
    
    //释放网口
    if (_wdSyncSocket) {
        
        [_wdSyncSocket disConnectToServer];
    }
    
    [[NSUserDefaults standardUserDefaults]setObject:@"" forKey:@"clickButton"];
    CTLog(CTLOG_LEVEL_INFO,@"=============Dut using teardown");
    
    return YES;
}

- (CTCommandCollection *)commmandDescriptors
{
    CTCommandCollection *collection = [CTCommandCollection new];

    CTCommandDescriptor *command = [[CTCommandDescriptor alloc] initWithName:@"sendCommand" selector:@selector(sendCommand:) description:@"send Command"];
    [collection addCommand:command];
    
    //生成文件
    command = [[CTCommandDescriptor alloc] initWithName:@"writeCsvFile" selector:@selector(writeCsvFile:) description:@"writeCsvFile"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"openSocket" selector:@selector(openSocket:) description:@"openSocket"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"GetSN" selector:@selector(GetSN:) description:@"Get SN"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"CheckSN" selector:@selector(CheckSN:) description:@"Check SN"];
    [collection addCommand:command];
    
    //检查config
    command =  [[CTCommandDescriptor alloc] initWithName:@"check_config" selector:@selector(check_config:) description:@"check config"];
    [collection addCommand:command];
    
    command =  [[CTCommandDescriptor alloc] initWithName:@"CheckGRRSN" selector:@selector(CheckGRRSN:) description:@"Check GRR SN"];
    [collection addCommand:command];
    
    
    //获取Lisa SN
    command =  [[CTCommandDescriptor alloc] initWithName:@"LISASN" selector:@selector(LISASN:) description:@"LISA SN"];
    [collection addCommand:command];
    
    //获取S_BUILD
    command =  [[CTCommandDescriptor alloc] initWithName:@"S_BUILD" selector:@selector(S_BUILD:) description:@"S BUILD"];
    [collection addCommand:command];
    
    //获取BUILD_EVENT
    command =  [[CTCommandDescriptor alloc] initWithName:@"BUILD_EVENT" selector:@selector(BUILD_EVENT:) description:@"BUILD EVENT"];
    [collection addCommand:command];
    
    //获取BUILD_MATRIX_CONFIG
    command =  [[CTCommandDescriptor alloc] initWithName:@"BUILD_MATRIX_CONFIG" selector:@selector(BUILD_MATRIX_CONFIG:) description:@"BUILD MATRIX CONFIG"];
    [collection addCommand:command];
    
    //获取STATION_ID
    command =  [[CTCommandDescriptor alloc] initWithName:@"STATION_ID" selector:@selector(STATION_ID:) description:@"STATION ID"];
    [collection addCommand:command];
    
    //获取softwareversion
    command =  [[CTCommandDescriptor alloc] initWithName:@"SoftwareVersion" selector:@selector(SoftwareVersion:) description:@"Software Version"];
    [collection addCommand:command];

    return collection;
}


#pragma mark---------获取SN
- (void)GetSN:(CTTestContext *)context
{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error)
     {
         self.SN = context.parameters[@"SN"];
         CTLog(CTLOG_LEVEL_INFO,@"GetSN:context.output = %@",self.SN);
         
         self.Path = [NSString stringWithFormat:@"%@%@",self.DataPath,self.SN];
         //生成文件夹的路径
         if ([self.fold Folder_Creat:self.Path])
         {
             CTLog(CTLOG_LEVEL_ALERT,@"Folder Creat Success =%@",self.Path);
         }
         else
         {
             CTLog(CTLOG_LEVEL_ALERT,@"Folder Creat Fail =%@",self.Path);
         }
         
         return CTRecordStatusPass;
     }];
}

- (void)CheckSN:(CTTestContext *)context
{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error)
     {
         self.SN = context.parameters[@"SN"];
         CTLog(CTLOG_LEVEL_ALERT,@"CheckSN=%@",[self.sfc getInfoWithSN:self.SN]);
         if([[self.sfc checkSN:self.SN] containsString:@"unit_process_check=OK"])
         {
             context.output = @"OK";
         }
         else
         {
             context.output = [self.sfc checkSN:self.SN];
         }
         
         return CTRecordStatusPass;
     }];
}


-(void)check_config:(CTTestContext *)context{
    
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        self.SN = context.parameters[@"SN"];
        NSString * respone = [self.sfc getInfoWithSN:self.SN];
        NSArray * array = [respone componentsSeparatedByString:@"\n"];
        CTLog(CTLOG_LEVEL_ALERT,@"Check Config Array: %@",array);
        
        if([[array lastObject] containsString:@"_"])
        {
            NSArray * resultArray = [[array lastObject]componentsSeparatedByString:@"_"];
            if([[resultArray firstObject] containsString:@"NULL"] || [[resultArray lastObject]containsString:@"NULL"] || [respone containsString:@"SN ERROR"])
            {
                CTLog(CTLOG_LEVEL_ALERT,@"Check Fail");
                context.output = respone;
            }
            else
            {
                CTLog(CTLOG_LEVEL_ALERT,@"check Success");
                context.output = @"OK";
                
            }
        }
        else
        {
            CTLog(CTLOG_LEVEL_ALERT,@"Check Fail");
            context.output = respone;
        }
        
        return CTRecordStatusPass;
        
    }];
}

-(void)CheckGRRSN:(CTTestContext *)context{
    
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        self.SN = context.parameters[@"SN"];
        if(self.SN.length == 17 /*&& [self.SN containsString:@"DLC"] && [self.SN containsString:@"KQV"]*/)
        {
            CTLog(CTLOG_LEVEL_ALERT,@"check Success");
            context.output = @"OK";
        }
        else
        {
            CTLog(CTLOG_LEVEL_ALERT,@"Check Fail");
            context.output = [NSString stringWithFormat:@"SN is %@",self.SN];
        }
        return CTRecordStatusPass;
        
    }];
}

#pragma mark---------open测试版
- (void)openSocket:(CTTestContext *)context
{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        self.startTime = [self.timeDay getCurrentSecond];
        
        while (1) {
            
            BOOL  isSocketConnect  = [self.wdSyncSocket connectToServerIPAddress:self.ip port:self.port timeout:1.0 terminator:@"OK@_@" dataTerminator:@"DA@_@"];
            
            if (isSocketConnect) {
                
                CTLog(CTLOG_LEVEL_ALERT,@"self.unit===%@,Network Connect Success!",self.Unit);
                
                while(YES)
                {
                    //复位测试板子
                    NSString * resetCommand = [self.wdSyncSocket sendCommand:[NSString stringWithFormat:@"%@\r\n",@"reset_measureboard"] timeout:1.0];
                
                    if ([resetCommand containsString:@"OK@_@\r\n"]) {
                    
                        CTLog(CTLOG_LEVEL_ALERT,@"self.unit===%@,Measure Board  Reset Success!",self.Unit);
                        i = 0;
                        break;
                    }
                    else
                    {
                        CTLog(CTLOG_LEVEL_ALERT,@"self.unit===%@,Measure Board  Reset Fail!",self.Unit);
                        i++;
                        if(i >= 4)
                        {
                
                            return CTRecordStatusError;
                        }
                        else
                        {
                            [NSThread sleepForTimeInterval:0.01];
                        }
                    }
                }
                
                while(YES)
                {
                    //检测测试板是否Ready
                    [NSThread sleepForTimeInterval:0.01];
                    NSString * readyCommand = [self.wdSyncSocket sendCommand:[NSString stringWithFormat:@"%@\r\n",@"check_measureboard_ready?"] timeout:1.0];
                
                    if ([readyCommand containsString:@"OK@_@\r\n"]) {
                    
                        CTLog(CTLOG_LEVEL_ALERT,@"self.unit===%@,Measure Board  is Ready!",self.Unit);
                        i = 0;
                        break;
                    }
                    else
                    {
                        CTLog(CTLOG_LEVEL_ALERT,@"self.unit===%@,Measure Board  isn't Ready!",self.Unit);
                        i++;
                        if(i >= 4)
                        {
                            return CTRecordStatusError;
                        }
                        else
                        {
                            [NSThread sleepForTimeInterval:0.01];
                        }
                    }
                }
                
                break;
            }
            else
            {
                CTLog(CTLOG_LEVEL_ALERT,@"self.unit===%@,Network Connect Fail!",self.Unit);
                i++;
                if(i >= 4)
                {
                    return CTRecordStatusError;
                }
                else
                {
                    CTLog(CTLOG_LEVEL_ALERT,@"self.unit===%@,Network Connectting...",self.Unit);
                }
            }
            
        }
        
        return CTRecordStatusPass;
    }];
}

#pragma mark---------测试版发送命令
- (void)sendCommand:(CTTestContext *)context
{
        float delay = [context.parameters[KDelay] floatValue];
        NSString * testName      =  context.parameters[KTestName];
        NSString * command       =  context.parameters[KCommand];
        
        [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
            
            //正式发送数据
            NSString *response;
            
            if (self.isShortOK&&[command containsString:@"ON"]) {
                
                response =@"0.0000";
            }
            else{
                response=[self.wdSyncSocket sendCommand:context.parameters[KCommand] timeout:5];
                if(response == nil || [response isEqualToString:@""])
                {
                    response=[self.wdSyncSocket sendCommand:context.parameters[KCommand] timeout:5];
                }
                
                CTLog(CTLOG_LEVEL_INFO,@"=============response = %@,==============",response);
            }
            
            if([response containsString:@"Timeout"])
            {
                timer ++;
                if(timer >= 3)
                {
                    timer = 0;
                    return CTRecordStatusError;
                }
            }
            
            usleep(delay*1000);
            
            if([response containsString:@"DA@_@"]){
                
                //对数据进行判断处理
                if ([testName isEqualToString:@"SHORT"]) {
                    NSString  * responeData = [self.function rangeofString:response Prefix:[NSString stringWithFormat:@"%@ ",command] Suffix:@" DA@_@\r\n"];
                    
                    NSString  * result  =[self.function returnResultWithSourceData:responeData withPath:self.Path];
                    context.output = result;
                    
                    if ([result containsString:@"50000"]) {
                        self.isShortOK = YES;
                    }
                }
                //将数据存储到字典中
                else if ([context.parameters[KChoose] isEqualToString:@"SaveToDictionary"]) {
                    
                    NSString  * simpleResponse = [self.function rangeofString:response Prefix:[NSString stringWithFormat:@"%@ ",command] Suffix:@" DA@_@\r\n"];
                    CTLog(CTLOG_LEVEL_INFO,@"Unit:%@,SaveToDictionary:testName = %@;command= %@, simpleResponse:%@",self.Unit,testName,command,simpleResponse);
                    NSArray   *  arr =[simpleResponse componentsSeparatedByString:@","];
                    [self.valueDictionary setObject:arr[0] forKey:[NSString stringWithFormat:@"%@_average",testName]];
                    [self.valueDictionary setObject:arr[1] forKey:[NSString stringWithFormat:@"%@_rms",testName]];
                    [self.valueDictionary setObject:arr[2] forKey:[NSString stringWithFormat:@"%@_max",testName]];
                    [self.valueDictionary setObject:arr[3] forKey:[NSString stringWithFormat:@"%@_min",testName]];
                    [self.valueDictionary setObject:arr[4] forKey:[NSString stringWithFormat:@"%@_vpp",testName]];
                    
                    //存储之前的平均值
                    
                    NSString * data = [arr objectAtIndex:0];
                    if([data containsString:@"-"])
                    {
                        data = [data substringFromIndex:1];
                    }
                    
                    [self.NullTestData addObject:data];
                    CTLog(CTLOG_LEVEL_INFO,@"self.NullTestData = %@",self.NullTestData);
                    //返回第一个值===平均值
                    context.output = data;
                    
                }
                
                //获取黑卡和白卡的值，然后减去之前的值
                else if ([context.parameters[KChoose] isEqualToString:@"SubtractNullTestValue"]){
                    
                    if([response isEqualToString:@""] || response == nil)
                        response = @"0.0000";
                    
                    NSString  * simpleResponse = [self.function rangeofString:response Prefix:[NSString stringWithFormat:@"%@ ",command] Suffix:@"DA@_@\r\n"];
                    CTLog(CTLOG_LEVEL_INFO,@"SubtractNullTestValue:testName = %@;command= %@, simpleResponse:%@",testName,command,simpleResponse);
                    //获取当前的平均值
                    NSArray   *  arr =[simpleResponse componentsSeparatedByString:@","];
                    NSString  * index = [testName substringWithRange:NSMakeRange(testName.length-1, 1)];
                    float  nullTestValue = [[self.NullTestData objectAtIndex:[index intValue]] floatValue];
                    //相减
                    NSString  * value = [NSString stringWithFormat:@"%.3f", [[arr objectAtIndex:0] floatValue] - nullTestValue];
                    
                    if([value containsString:@"-"])
                    {
                        value = [value substringFromIndex:1];
                    }
                    
                    CTLog(CTLOG_LEVEL_INFO, @"SubtractNullTestValue:index=%@,NullTestValue=%f,value:%f,value-NullTestValue=%@*****",index,nullTestValue,[[arr objectAtIndex:0] floatValue],value);
                    
                    float num = value.floatValue;
                    context.output = [NSString stringWithFormat:@"%.3f",num];
                }
                else
                {
                    NSString * str = [self.function rangeofString:response Prefix:[NSString stringWithFormat:@"%@ ",command] Suffix:@" DA@_@\r\n"];
                    if([str containsString:@"NIL"] || [str isEqualToString:@""])
                        context.output = @"0.0";
                    else
                        context.output = str;
                    
                    CTLog(CTLOG_LEVEL_INFO,@"response==== DA@_@ :response=%@",context.output);
                }
                
                //判断下测试结果
                [self GetTestResult:context];
            }
            else if ([response containsString:@"OK@_@"]){
                
                CTLog(CTLOG_LEVEL_INFO,@"response==== OK@_@ :response=%@",response);
            }
            else
            {
                CTLog(CTLOG_LEVEL_INFO,@"response usual:response=%@",response);
                //判断下测试结果
                context.output = @"-9999999";
                [self GetTestResult:context];
            }

         
         return CTRecordStatusPass;
    }];
    
}

#pragma mark---------生成总文件
-(void)writeCsvFile:(CTTestContext *)context{
    
    CTLog(CTLOG_LEVEL_INFO, @"Context Msg:%@",context.unit.unitTransports);
    CTLog(CTLOG_LEVEL_INFO, @"Call Function: writeCsvFile");
    
    NSString *  TitleName =@"Product,SerialNumber,Station ID,Test Pass/Fail Status,List of Failing Tests,Error Description,StartTime,EndTime,TesterID,Version,Operator,OPEN_GND_J0300.19-J0300.20,OPEN_GND_J0300.20-J0300.21,OPEN_GND_J0300.21-J0300.22,OPEN_GND_J0300.19-WP0201,LISA_TO_PMU_BTN_L_J0300.14-WP0200,SHORT,D_U0202_VDD,D_U0202_ENA,D_U0202_RX0,D_U0202_RX1,D_U0202_RX2,D_U0202_RX3,D_U0202_RX4,D_U0202_RX5,D_U0202_RX6,D_U0202_RX7,ESD_DZ0201+,ESD_DZ0201-,STL,IRLED_VF,VOS_CH0,VOS_CH1,VOS_CH2,VOS_CH3,VOS_CH4,VOS_CH5,VOS_CH6,VOS_CH7,LISA_CURRUENT,BLACK_CH0,BLACK_CH1,BLACK_CH2,BLACK_CH3,BLACK_CH4,BLACK_CH5,BLACK_CH6,BLACK_CH7,WHITE_CH0,WHITE_CH1,WHITE_CH2,WHITE_CH3,WHITE_CH4,WHITE_CH5,WHITE_CH6,WHITE_CH7,C0209,C0202,C0204,CF_SIG_VOUT_P,CF_SIG_VOUT_N,CF_SIG_VOUT_I";
    
    NSString *  upLimit  = @"Upper Limit---->,,,,,,,,,,,10,10,10,10,10,9999999,1.1,1.1,1.1,1.1,1.1,1.1,1.1,1.1,1.1,1.1,11.5,11.5,10,2,35,35,35,35,35,35,35,35,10,30,30,30,30,30,30,30,30,800,800,800,800,800,800,800,800,0.682,0.319,0.319,1.5,-1.1,15";
    
    NSString *  lowLimit = @"Lower Limit---->,,,,,,,,,,,0,0,0,0,0,3000000,0.2,0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3,5,5,0,1,1,1,1,1,1,1,1,1,0.1,0,0,0,0,0,0,0,0,280,280,280,280,280,280,280,280,0.329,0.154,0.154,1.1,-1.5,6";
    
    NSString *  Units = @"Measurement Unit---->,,,,,,,,,,,ohm,ohm,ohm,ohm,ohm,ohm,V,V,V,V,V,V,V,V,V,V,V,V,ohm,V,mV,mV,mV,mV,mV,mV,mV,mV,mA,mV,mV,mV,mV,mV,mV,mV,mV,mV,mV,mV,mV,mV,mV,mV,mV,uF,uF,uF,V,V,uA";
    
    NSString   * headTile = [NSString stringWithFormat:@"%@\n%@\n%@\n%@",TitleName,upLimit,lowLimit,Units];
    NSArray  * values = context.parameters[@"values"];
    
    NSMutableString  *  valueStr = [[NSMutableString alloc] initWithCapacity:10];
    for (NSString * str in values) {
        
        [valueStr appendFormat:@"%@,",str];
    }
    CTLog(CTLOG_LEVEL_INFO,@"GetFromDictionary:valueStr= %@",valueStr);
    
    NSString  *  DataStr;
    if ([valueStr containsString:@"value"]) {
        DataStr = [valueStr stringByReplacingOccurrencesOfString:@"value" withString:@""];
    }
    
    if(self.FailItems.length > 1)
    {
        [self.FailItems deleteCharactersInRange:NSMakeRange(self.FailItems.length-1, 1)];
    }
    self.ErrorDescription = @"NA";
    i = 0;
    NSString  * writeStr = [NSString stringWithFormat:@"\nW1a,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@%@",self.SN,[self.sfc getInfoWithStationID],self.TestResult?@"PASS":@"FAIL",self.FailItems,self.ErrorDescription,self.startTime,[self.timeDay getCurrentSecond],[self.Unit substringFromIndex:4],self.softwareversion,@"",DataStr];
    
    [context runTest:^CTRecordStatus(NSError *__autoreleasing *failureInfo) {
        
        if(self.length.length > 2)
        {
            [self.fileOperator saveRecordWith:writeStr fileName:[NSString stringWithFormat:@"%@_Unit1.csv",self.SummaryPath] andCsvHeader:headTile];
        }
        else
        {
            [self.fileOperator saveRecordWith:writeStr fileName:[NSString stringWithFormat:@"%@_Unit2.csv",self.SummaryPath] andCsvHeader:headTile];
        }
        return CTRecordStatusPass;
        
    }];
}

#pragma mark---------增加判断测试结果方法
-(void)GetTestResult:(CTTestContext*)context{
    
    CTLog(CTLOG_LEVEL_INFO,@"GetTestResult:testName:%@,Max=%@,Min=%@,output==========%@",context.parameters[KTestName],context.parameters[@"Max"],context.parameters[@"Min"],context.output);
    
    
    if ((([context.output floatValue]<[context.parameters[@"Min"] floatValue])||
         ([context.output floatValue]>[context.parameters[@"Max"] floatValue]))|| [context.output containsString:@"NIL"] || [context.output containsString:@"-9999999"]) {
        
        CTLog(CTLOG_LEVEL_INFO,@"Test Fail Item ===:testName:%@,Max=%@,Min=%@,output==========%@",context.parameters[KTestName],context.parameters[@"Max"],context.parameters[@"Min"],context.output);
        
        [self.FailItems appendFormat:@"%@|",context.parameters[KTestName]];
        self.TestResult = NO;
    }
    else
    {
        CTLog(CTLOG_LEVEL_ALERT,@"Item Pass");
    }
}

#pragma mark-------获得LISA SN
-(void)LISASN:(CTTestContext *)context{
    
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        NSString * respone = [self.sfc checkSFCStateWithSN:self.SN];
        NSArray * array = [respone componentsSeparatedByString:@"\n"];
        CTLog(CTLOG_LEVEL_ALERT,@"Lisa SN Array: %@",array);
        
        if([[[array lastObject]lowercaseString]containsString:@"error"])
        {
            return CTRecordStatusError;
        }
        context.output = [array lastObject];
        
        CTLog(CTLOG_LEVEL_ALERT,@"Receive Lisa SN: %@",[array lastObject]);
        return CTRecordStatusPass;
    }];
}


#pragma mark-------获得S_BUILD
-(void)S_BUILD:(CTTestContext *)context{
    
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        NSString * respone = [self.sfc getInfoWithSN:self.SN];
        NSArray * array = [respone componentsSeparatedByString:@"\n"];
        CTLog(CTLOG_LEVEL_ALERT,@"S_BUILD Array: %@",array);
        
        NSArray * resultArray = [[array lastObject]componentsSeparatedByString:@"_"];
        NSString * str = [NSString stringWithFormat:@"%@_%@",[resultArray firstObject],[resultArray lastObject]];
        
        context.output = str;
        
        CTLog(CTLOG_LEVEL_ALERT,@"Receive S_BUILD: %@",str);
        return CTRecordStatusPass;
    }];
}

#pragma mark-------获得BUILD_EVENT
-(void)BUILD_EVENT:(CTTestContext *)context{
    
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        NSString * respone = [self.sfc getInfoWithSN:self.SN];
        NSArray * array = [respone componentsSeparatedByString:@"\n"];
        CTLog(CTLOG_LEVEL_ALERT,@"BUILD_EVENT Array: %@",array);
        
        NSArray * resultArray = [[array lastObject]componentsSeparatedByString:@"_"];
        
        context.output = [resultArray firstObject];
        
        CTLog(CTLOG_LEVEL_ALERT,@"Receive BUILD_EVENT: %@",[resultArray firstObject]);
        return CTRecordStatusPass;
    }];
}

#pragma mark-------获得BUILD_MATRIX_CONFIG
-(void)BUILD_MATRIX_CONFIG:(CTTestContext *)context{
    
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        NSString * respone = [self.sfc getInfoWithSN:self.SN];
        NSArray * array = [respone componentsSeparatedByString:@"\n"];
        CTLog(CTLOG_LEVEL_ALERT,@"BUILD_MATRIX_CONFIG Array: %@",array);
        
        NSArray * resultArray = [[array lastObject]componentsSeparatedByString:@"_"];
        
        context.output = [resultArray lastObject];
        
        CTLog(CTLOG_LEVEL_ALERT,@"Receive BUILD_MATRIX_CONFIG: %@",[resultArray lastObject]);
        return CTRecordStatusPass;
    }];
}



#pragma mark-------获得STATION_ID
-(void)STATION_ID:(CTTestContext *)context{
    
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        NSArray * array = [[self.sfc getInfoWithStationID]componentsSeparatedByString:@"_"];
        NSString * str = [array objectAtIndex:2];
        
        context.output = str;
        return CTRecordStatusPass;
    }];
}

//传递softwareversion
-(void)SoftwareVersion:(CTTestContext *)context{
    
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        self.softwareversion = context.parameters[@"softwareversion"];
        CTLog(CTLOG_LEVEL_ALERT,@"softwareversion :%@",self.softwareversion);
        return CTRecordStatusPass;
    }];
}




@end
