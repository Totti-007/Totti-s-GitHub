//
//  PlistOperator.m
//  Framework
//
//  Created by Robin on 2018/11/13.
//  Copyright © 2018年 RobinCode. All rights reserved.
//

#import "PlistOperator.h"


#define Kpath @"/Users/gdlocal/Library/Atlas/Configs/Reference.plist"
//#define Kpath @"/Users/ew/Library/Atlas/Configs/Reference.plist"

@implementation PlistOperator

-(void)setPlistValue:(NSString*)value forKey:(NSString*)key{
    
    @synchronized (self) {
        
        NSFileManager *manager = [NSFileManager defaultManager];
        
        if (![manager fileExistsAtPath:Kpath]) {
            //ShowAlert
            return;
        }
        NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:Kpath];
        
        [dic setValue:value forKey:key];
        
        CTLog(CTLOG_LEVEL_INFO,@"dic setValue:value forKey:key ==%@",dic[key]);
        //偶尔出现写入失败，多写几次
        [dic writeToFile:Kpath atomically:YES];
        [dic writeToFile:Kpath atomically:YES];
        [dic writeToFile:Kpath atomically:YES];
        if([dic writeToFile:Kpath atomically:YES]){
            
            CTLog(CTLOG_LEVEL_INFO,@"Write to file successfully");
            
        }else{
            CTLog(CTLOG_LEVEL_INFO,@"Write to file fail");
        }
        
        //从文件中读取出来
        NSDictionary * dic1 = [[NSDictionary alloc] initWithContentsOfFile:Kpath];
        CTLog(CTLOG_LEVEL_INFO,@"dic1:key ==%@",dic1[key]);
        
    }
}

-(NSString *)readValueForKey:(NSString *)key
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:Kpath];
    
    return [dictionary objectForKey:key];
}

@end
