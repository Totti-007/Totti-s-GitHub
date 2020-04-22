//
//  GHInfo.m
//  LCRFixture
//
//  Created by 王宗祥 on 2017/11/4.
//  Copyright © 2017年 wuzhen Li. All rights reserved.
//

#import "GHInfo.h"

@implementation GHInfo

static NSString* CK_GHConfig    = @"/vault/data_collection/test_station_config/gh_station_info.json";
static NSString* CK_GHDebug     = @"/vault/data_collection/test_station_config/gh_station_info_debug.json";
static NSString* CK_GHinfo      = @"ghinfo";
-(id)init
{
    return [self init:false];
}
// init the GH info
-(id)init:(bool)debug{
    
    if (self = [super init]) {
        
        GHConfigFile = CK_GHConfig;
        if(debug)
        {
            NSFileManager* fm = [NSFileManager defaultManager];
            if ([fm fileExistsAtPath:CK_GHDebug] && [fm isReadableFileAtPath:CK_GHDebug]) {
                GHConfigFile = CK_GHDebug;
            }
        }
        
        self.strGHinfoUI = @"";
        if ([[NSFileManager defaultManager] fileExistsAtPath:GHConfigFile]) {
            NSString* jsonString = [[NSString alloc] initWithContentsOfFile:GHConfigFile encoding:NSUTF8StringEncoding error:nil];
            NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary* allKeysValues = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
            if ([[allKeysValues allKeys] containsObject:CK_GHinfo]){
                //NSMutableString *strGHinfoUI = [[NSMutableString alloc]init];
                NSDictionary *allValues = [allKeysValues valueForKey:CK_GHinfo];
                
                if ([[allValues allKeys] containsObject:@"SITE"]) { // SITE
                    self.strGHinfoUI = [NSMutableString stringWithFormat:@"%@SITE: %@\n",self.strGHinfoUI,[allValues valueForKey:@"SITE"]];
                    self.strSITE = [allValues valueForKey:@"SITE"];
                }
                
                if ([[allValues allKeys] containsObject:@"PRODUCT"]){ // PRODUCT
                    self.strGHinfoUI = [NSMutableString stringWithFormat:@"%@PRODUCT: %@\n",self.strGHinfoUI,[allValues valueForKey:@"PRODUCT"]];
                    self.strPRODUCT = [allValues valueForKey:@"PRODUCT"];
                }
                
                if ([[allValues allKeys] containsObject:@"BUILD_STAGE"]){ // BUILD_STAGE
                    self.strGHinfoUI = [NSMutableString stringWithFormat:@"%@BUILD_STAGE: %@\n",self.strGHinfoUI,[allValues valueForKey:@"BUILD_STAGE"]];
                    self.strBUILD = [allValues valueForKey:@"BUILD_STAGE"];
                }
                
                if ([[allValues allKeys] containsObject:@"LINE_NAME"]){ // LINE_NAME
                    self.strGHinfoUI = [NSMutableString stringWithFormat:@"%@LINE_NAME: %@\n",self.strGHinfoUI,[allValues valueForKey:@"LINE_NAME"]];
                    self.strLINE= [allValues valueForKey:@"LINE_NAME"];
                }
                
                if ([[allValues allKeys] containsObject:@"STATION_NUMBER"]){ // LINE_NAME
                    self.strGHinfoUI = [NSMutableString stringWithFormat:@"%@STATION_ID: %@",self.strGHinfoUI,[allValues valueForKey:@"STATION_NUMBER"]];
                    self.strSTATION = [allValues valueForKey:@"STATION_NUMBER"];
                }
                if ([[allValues allKeys] containsObject:@"SFC_URL"]){ // SFC_URL
                    self.strGHinfoUI = [NSMutableString stringWithFormat:@"%@STATION_ID: %@",self.strGHinfoUI,[allValues valueForKey:@"STATION_ID"]];
                    self.SFC_URL = [allValues valueForKey:@"SFC_URL"];
                }
                NSLog(@"SITE=%@, PRODUCT=%@, BUILD=%@, LINE=%@, STATION=%@", self.strSITE, self.strPRODUCT, self.strBUILD, self.strLINE, self.strSTATION);
                
            }
        }
        
    }
    
    return self;
}

-(NSString*)getStationLogItems
{
    return [NSString stringWithFormat:@"%@,%@", self.strSTATION, self.strSITE];
}

-(NSString*)getGHitem:(NSString*)key
{
    return [self getGHitem:key DBG:false];
}
-(NSString*)getGHitem:(NSString*)key DBG:(bool)debug
{
    
    GHConfigFile = CK_GHConfig;
    if(debug)
        GHConfigFile = CK_GHDebug;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:GHConfigFile]) {
        NSString* jsonString = [[NSString alloc] initWithContentsOfFile:GHConfigFile encoding:NSUTF8StringEncoding error:nil];
        NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* allKeysValues = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
        if ([[allKeysValues allKeys] containsObject:CK_GHinfo]){
            NSDictionary *allValues = [allKeysValues valueForKey:CK_GHinfo];
            
            if ([[allValues allKeys] containsObject:key]) {
                return [allValues valueForKey:key];
            }
        }
    }
    
    return @"No GH Info Found!";
}

@end
