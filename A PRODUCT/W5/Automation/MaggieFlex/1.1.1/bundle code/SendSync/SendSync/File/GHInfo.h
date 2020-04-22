//
//  GHInfo.h
//  LCRFixture
//
//  Created by 王宗祥 on 2017/11/4.
//  Copyright © 2017年 wuzhen Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GHInfo : NSObject
{
    NSString* GHConfigFile;
}
#pragma mark --message  show on UI 
@property (strong,atomic) NSString* strGHinfoUI;
@property (strong,atomic) NSString* strSITE;
@property (strong,atomic) NSString* strPRODUCT;
@property (strong,atomic) NSString* strBUILD;
@property (strong,atomic) NSString* strLINE;
@property (strong,atomic) NSString* strSTATION;
@property (strong,atomic) NSString* strTSID;
@property (strong,atomic) NSString* SFC_URL;
-(id)init:(bool)debug;
-(NSString*)getGHitem:(NSString*)key DBG:(bool)debug;
-(NSString*)getStationLogItems;
@end
