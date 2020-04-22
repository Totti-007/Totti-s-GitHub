//
//  SerialPortTool.h
//  Framework
//


#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import <CoreTestFoundation/CoreTestFoundation.h>
/*
 把ORSSerialPort包装成同步的,便于代码的维护
 
 */

@interface SerialPortTool : NSObject
/*
 @param: path -> serialPort Path example :/dev/cu.usbserial-A107R7CU
 @param: config -> dictionary , like key-value. timeout-2.0, reponseEndMark -"\r\n"
 return : open result. YES Or NO, fail and success.
 */

-(BOOL)openSerialPortWithPath:(NSString*)path congfig:(NSDictionary*)config;

/*
 @param:command -> the command you will send
 return response -> wait the response 
 */

-(NSString*)sendAndRecWithConfig:(NSDictionary *)config;

-(BOOL)justSendCommandWithConfig:(NSDictionary *)config;
-(NSString *)justReceivedWithConfig:(NSDictionary *)config;
/*
 close Serial-port
 return :close result
 */
-(BOOL)close;




@end
