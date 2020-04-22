//
//  SerialPortTool.m
//  Framework
//

#import "SerialPortTool.h"
#import "ORSSerialPort.h"

@interface SerialPortTool()<ORSSerialPortDelegate>
@property(nonatomic,strong) ORSSerialPort *serialPort;
@property(nonatomic,strong) NSString * reponseEndMark;
@property(nonatomic,strong) NSString * dataReponseEndMark;
@property(atomic,strong) NSString*response;
@property(nonatomic,strong) NSMutableString *responseBuffer;
@property(nonatomic,assign) double timeout;
@property(nonatomic,assign)BOOL isSimulated;

#define KOpened @"Opened"
#define KClosed @"Closed"
#define KInterval 1
#define KTimeoutText @"Error:timeout,Pls check the serial-port"
#define KRemovedText @"Error:Removed,Serial-port removed from system"
#define KClosedText @"Error:Serial port not opened"

@end

@implementation SerialPortTool

-(NSMutableString *)responseBuffer{
     if (_responseBuffer == nil) {
          _responseBuffer = [NSMutableString string];
     }
     return _responseBuffer;
}

-(BOOL)openSerialPortWithPath:(NSString *)path congfig:(NSDictionary *)config{
     self.serialPort = [[ORSSerialPort alloc] initWithPath:path];
     self.reponseEndMark = config[@"reponseEndMark"] == nil?@"\r\n":config[@"reponseEndMark"];
     self.dataReponseEndMark = config[@"dataReponseEndMark"] == nil?@"\r\n":config[@"dataReponseEndMark"];
     self.timeout = config[@"timeout"] == nil ? 3.0:[config[@"timeout"] doubleValue];
     NSNumber *baud=config[@"baudRate"] == nil? @(9600) : config[@"baudRate"];
     self.serialPort.baudRate =baud;
    //flow control pins
    self.serialPort.usesRTSCTSFlowControl = config[@"RTSCTSFC"] == nil? NO : [config[@"RTSCTSFC"] boolValue];
    self.serialPort.usesDTRDSRFlowControl=config[@"DTRDSRFC"] == nil? NO:[config[@"DTRDSRFC"] boolValue];
    self.serialPort.usesDCDOutputFlowControl=config[@"DCDOFC"]==nil? NO:[config[@"DCDOFC"] boolValue];

     self.serialPort.delegate = self;
     CTLog(CTLOG_LEVEL_INFO, @"serial path：%@ baud:%@",path,baud);
    self.isSimulated=config[@"isSimulated"]==nil? NO:[config[@"isSimulated"] boolValue];
    if(self.isSimulated) {
        CTLog(CTLOG_LEVEL_INFO, @"*****Alarm! this is simulated serial port,just for offline testing!****");
        return YES;
    }
     [self.serialPort open];
    
     double timeout = 0.0;
     
     while (1) {
          timeout = timeout + KInterval/1000.0;
          usleep(KInterval*1000);
          if ([self.response containsString:KOpened]||[self.response containsString:KClosed]){
              self.serialPort.RTS=config[@"RTS"]==nil? NO:[config[@"RTS"] boolValue];
              self.serialPort.DTR=config[@"DTR"]==nil? NO:[config[@"DTR"] boolValue];
              break;
          }
          
          if (timeout > self.timeout) {
               //NSLog(@"连接超时");
               break;
          }
     }
     
     return self.serialPort.isOpen;
}


-(NSString*)sendAndRecWithConfig:(NSDictionary *)config{
    if (self.isSimulated) {
        return config[@"ACK"] == nil? @"Ack of simulated":config[@"ACK"];
    }
    self.reponseEndMark = config[@"reponseEndMark"] == nil?@"\r\n":config[@"reponseEndMark"];
    self.dataReponseEndMark = config[@"dataReponseEndMark"] == nil?@"\r\n":config[@"dataReponseEndMark"];
    self.timeout = config[@"timeout"] == nil ? 2.0:[config[@"timeout"] doubleValue];
    NSString *command=config[@"cmd"]==nil? @"":config[@"cmd"];
     if (![command containsString:@"\r\n"]) {
          command = [NSString stringWithFormat:@"%@\r\n",command];
     }
     NSData *data = [command dataUsingEncoding:NSASCIIStringEncoding];
     self.response = @"";
    if(![self.serialPort sendData:data]) return KClosedText;
     double timeout = 0.0;
     while (1) {
          timeout = timeout + KInterval/1000.0;
          usleep(KInterval*1000);
         
         if ([self.response containsString:self.reponseEndMark]||
             [self.response containsString:self.dataReponseEndMark]){
             
             CTLog(CTLOG_LEVEL_INFO,@"response=%@",self.response);
             break;
          }
          
          if (timeout > self.timeout) {
               //NSLog(@"连接超时");
               if (self.response.length == 0) {
                 self.response = KTimeoutText;
               }
               break;
          }
     }

     return self.response;
}

-(BOOL)justSendCommandWithConfig:(NSDictionary *)config{
    if (self.isSimulated) {
        return YES;
    }
    self.response=@"";
    NSString *command=config[@"cmd"];
    if (![command containsString:@"\r\n"]) {
        command = [NSString stringWithFormat:@"%@\r\n",command];
    }
    NSData *data = [command dataUsingEncoding:NSASCIIStringEncoding];
    return [self.serialPort sendData:data];
}
-(NSString *)justReceivedWithConfig:(NSDictionary *)config{
    if (self.isSimulated) {
        return config[@"ACK"] == nil? @"Ack of simulated":config[@"ACK"];
    }
    self.reponseEndMark = config[@"reponseEndMark"] == nil?@"\r\n":config[@"reponseEndMark"];
    self.dataReponseEndMark = config[@"dataReponseEndMark"] == nil?@"\r\n":config[@"dataReponseEndMark"];
    self.timeout = config[@"timeout"] == nil ? 2.0:[config[@"timeout"] doubleValue];
    
    double timeout = 0.0;
    while (1) {
        timeout = timeout + KInterval/1000.0;
        usleep(KInterval*1000);
        
        if ([self.response containsString:self.reponseEndMark]||
            [self.response containsString:self.dataReponseEndMark]){
            
            CTLog(CTLOG_LEVEL_INFO,@"response=%@",self.response);
            break;
        }
        
        if (timeout > self.timeout) {
            //NSLog(@"连接超时");
            if (self.response.length == 0) {
                self.response = KTimeoutText;
            }
            break;
        }
    }
    return self.response;
}

-(BOOL)close{
    if(self.serialPort.isOpen){
        return  [self.serialPort close];
    }
    return YES;
}


#pragma mark ----ORSSerialPortDelegate-------

-(void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data{
     
     NSString *str=[[NSString alloc]initWithData:data encoding:NSASCIIStringEncoding];
     
     if (str == nil) {
          return;
     }
    
     [self.responseBuffer appendString:str];
//        CTLog(CTLOG_LEVEL_INFO,@"self.reponseEndMark=%@===========================self.responseBuffer=%@",self.reponseEndMark,self.responseBuffer);
//    
     if ([self.responseBuffer containsString:self.reponseEndMark]||[self.responseBuffer containsString:self.dataReponseEndMark]) {
         
          CTLog(CTLOG_LEVEL_INFO,@"--------------------------self.responseBuffer=%@",self.responseBuffer);
         
          self.response = [self.responseBuffer mutableCopy];
          self.responseBuffer = nil;
     }
    
}


-(void)serialPortWasOpened:(ORSSerialPort *)serialPort{
     self.response = KOpened;
}

-(void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort{
     self.response = KRemovedText;
}

@end
