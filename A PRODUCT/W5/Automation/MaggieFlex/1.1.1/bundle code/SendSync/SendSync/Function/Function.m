//
//  Function.m
//  TestFunction
//
//  Created by mac on 22/12/2018.
//  Copyright © 2018 piaoxu. All rights reserved.
//

#import "Function.h"
#import "GetTimeDay.h"


@implementation Function

-(NSString *)rangeofString:(NSString *)String Prefix:(NSString *)prefix Suffix:(NSString *)suffix{
    //OC获取中间的字符串
    NSString *middleStr;
    //到该字符结束
    NSRange range;
    range.location = [String rangeOfString:prefix].location + prefix.length;
    range.length = [String rangeOfString:suffix].location - range.location;
    middleStr = [NSString stringWithFormat:@"%@", [String substringWithRange:range]];
    NSLog(@"%@",middleStr);
    
    return middleStr;
}


-(NSString *)returnResultOfData:(NSString *)sourceString Uplimit:(NSString *)upLimit  LowLimit:(NSString *)lowLimit{
    
    self.FailTestItemDataString  = [[NSMutableString alloc] initWithCapacity:10];
    
    BOOL TestResult = YES;
    
    double value = 0;;
    //1.对数据进行切割
    NSArray  * arr = [sourceString componentsSeparatedByString:@"\r\n"];
    
    
    //对数据进行比较
    for (int i=0; i<[arr count]-1; i++) {
        
        //取出第二个数值
         // CTLog(CTLOG_LEVEL_INFO,@"111111=========取出测试值value:%f，[arr objectAtIndex:i]=%@",value,[arr objectAtIndex:i]);
         value = [[[[arr objectAtIndex:i] componentsSeparatedByString:@"="] objectAtIndex:1] doubleValue];
        
        
        
        if (value<[lowLimit doubleValue]||value>[upLimit doubleValue]) {
            
            [self.FailTestItemDataString appendString:[arr objectAtIndex:i]];
            TestResult = NO;
            
             CTLog(CTLOG_LEVEL_INFO,@"失败的测试项:%@",[arr objectAtIndex:i]);
        }
    }
    
    
    
    if ([self.FailTestItemDataString length]>0) {
        
        //写入某个文件中
    }

    //return TestResult?@"pass":@"fail";
    
     return TestResult?@"5000000":@"0";
}



//返回数据
-(NSString *)returnResultWithSourceData:(NSString *)SourceData withPath:(NSString *)path{
    
    NSString  * returnStr;
    
    if ([SourceData containsString:@","] || [SourceData containsString:@"NIL"] || SourceData == nil) { //存在短路
        
        returnStr = @"0";
        
    }else{
        
        returnStr = @"5000000";
    }
    //将数据写入csv文件
    [SourceData writeToFile:[NSString stringWithFormat:@"%@/%@.txt",path,[[GetTimeDay shareInstance] getFileTime]] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    return returnStr;

}



@end
