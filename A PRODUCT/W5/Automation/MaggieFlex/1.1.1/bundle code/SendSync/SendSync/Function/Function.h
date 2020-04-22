//
//  Function.h
//  TestFunction
//
//  Created by mac on 22/12/2018.
//  Copyright © 2018 piaoxu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreTestFoundation/CoreTestFoundation.h>

@interface Function : NSObject

@property(nonatomic,strong)NSMutableString  *  FailTestItemDataString;

/*
     String: 字符串
     prefix: 前缀
     suffix: 后缀
*/
-(NSString *)rangeofString:(NSString *)String Prefix:(NSString *)prefix Suffix:(NSString *)suffix;


/*
     1.返回测试结果:pass/fail
     2.将失败的测试项，写入某个文件中
*/
-(NSString *)returnResultOfData:(NSString *)sourceString Uplimit:(NSString *)upLimit  LowLimit:(NSString *)lowLimit;


/*
     返回值中包含逗号，直接返回”0“
     否则直接返回5000000
*/
-(NSString *)returnResultWithSourceData:(NSString *)SourceData withPath:(NSString *)path;

@end
