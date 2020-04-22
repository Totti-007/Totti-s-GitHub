//
//  SFC.m
//  LCRFixture
//
//  Created by 王宗祥 on 2017/11/4.
//  Copyright © 2017年 wuzhen Li. All rights reserved.
//

#import "SFC.h"
#import "GHInfo.h"
//#import "AlertTool.h"
//#import "SaveDataTool.h"
static NSString* CK_UOP= @"unit_process_check";

@interface SFC ()
@property (nonatomic,strong) GHInfo *gh;
@end

@implementation SFC
-(GHInfo *)gh
{
    if (_gh==nil) {
        _gh=[[GHInfo alloc]init:NO];
    }
    return _gh;
}

-(NSString*)checkSFCStateWithSN:(NSString *)SN
{
//    if([[self.gh getGHitem:@"SFC_QUERY_UNIT_ON_OFF" DBG:NO] isEqualToString:@"OFF"])
//    {
//        self.ERROR_MESSAGE = @"UOP Disbled In GH.";
//        self.ERROR_NUMBER = SFC_OK;
//        return @"Local Setting:SFC_QUERY_UNIT_ON_OFF";
//    }
    
    NSString* output = [[NSString alloc]init];
    self.gh.strSTATION = [self.gh getGHitem:@"STATION_ID" DBG:NO];
     /*在这里组装一个键值对,需要再现在更改一下 Key->value*/
     if(![self post:[NSString stringWithFormat:@"c=QUERY_RECORD&sn=%@&p=LISA",SN] OUTPUT:&output]){
          return self.ERROR_MESSAGE;
     }else{
          return output;
     }
}

-(NSString*)getInfoWithSN:(NSString *)SN
{
    NSString* output = [[NSString alloc]init];
    self.gh.strSTATION = [self.gh getGHitem:@"STATION_ID" DBG:NO];
    /*在这里组装一个键值对,需要再现在更改一下 Key->value*/
    if(![self post:[NSString stringWithFormat:@"c=QUERY_RECORD&sn=%@&p=CONFIG",SN] OUTPUT:&output]){
        return self.ERROR_MESSAGE;
    }else{
        return output;
    }
}

-(NSString*)checkSN:(NSString *)SN
{
    NSString* output = [[NSString alloc]init];
    self.gh.strSTATION = [self.gh getGHitem:@"STATION_ID" DBG:NO];
    /*在这里组装一个键值对,需要再现在更改一下 Key->value*/
    /* sn=%@&c=QUERY_RECORD&tsid=%@&p=unit_process_check */
    if(![self post:[NSString stringWithFormat:@"c=QUERY_RECORD&sn=%@&tsid=%@&p=UNIT_PROCESS_CHECK",SN,self.gh.strSTATION] OUTPUT:&output]){
        return self.ERROR_MESSAGE;
    }else{
        return output;
    }
}

-(NSString*)getInfoWithStationID
{
    return self.gh.strSTATION;
}

-(bool)post:(NSString*)post OUTPUT:(NSString**)output
{
    NSURLResponse * response = nil;
    NSError * error = nil;
    self.ERROR_NUMBER = SFC_OK;
    
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    //You need to send the actual length of your data. Calculate the length of the post string.
    NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    
    // Create a Urlrequest with all the properties like HTTP method, http header field with length of the post string. Create URLRequest object and initialize it.
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    //Set the Url for which your going to send the data to that request.
     
    [request setURL:[NSURL URLWithString:self.gh.SFC_URL]];
    
    //Now, set HTTP method (POST or GET). Write this lines as it is in your code.
    [request setHTTPMethod:@"POST"];
    //Set HTTP header field with length of the post data.
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    //Also set the Encoded value for HTTP header Field.
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    //Set the HTTPBody of the urlrequest with postData.
    [request setHTTPBody:postData];
    //set connection timeout
    [request setTimeoutInterval:5];
    NSData* data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    if (error == nil)
    {
        *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"SFC post Url Return=%@", *output);
        [self getResponseCode:*output];
        return true;
    }
    else{
        NSLog(@"SFC post Connection Failed=%@", error);
     
        self.ERROR_NUMBER = SFC_CONNECTION_FAILED;
        self.ERROR_MESSAGE = ([error.userInfo valueForKey:@"NSLocalizedDescription"] != nil) ? [error.userInfo valueForKey:@"NSLocalizedDescription"] : [NSString stringWithFormat:@"%@", error];
         return false;
    }
    
}
-(void)getResponseCode:(NSString*)resp
{
    self.ERROR_MESSAGE = resp;
    self.ERROR_NUMBER = SFC_RESPONSE_NOT_FOUND;
    if([resp containsString:@"SFC_OK"])
    {
        self.ERROR_NUMBER = 0;
        self.ERROR_MESSAGE = @"";
        return;
    }
    if([resp containsString:@"SFC_ERROR"])
    {
        self.ERROR_NUMBER = 1;
        return;
    }
    if([resp containsString:@"SFC_FATAL_ERROR"])
    {
        self.ERROR_NUMBER = 2;
        return;
    }
    if([resp containsString:@"SFC_DATA_FORMAT_ERROR"])
    {
        self.ERROR_NUMBER = 3;
        return;
    }
    if([resp containsString:@"SFC_INVALID_COMMAND_ERROR"])
    {
        self.ERROR_NUMBER = 4;
        return;
    }
    if([resp containsString:@"SFC_UNKNOWN_RESPONSE"])
    {
        self.ERROR_NUMBER = 13;
        return;
    }
}
@end
