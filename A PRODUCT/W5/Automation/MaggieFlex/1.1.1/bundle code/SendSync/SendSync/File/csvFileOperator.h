//
//  csvFileOperator.h
//  LeftButtonFlexCompassSenorTest
//
//  Created by linanlin on 2017/5/10.
//  Copyright © 2017年 linanlin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface csvFileOperator : NSObject

/*
 创建CSV的单例对象,全局。
 */
+(instancetype)ShareCsvFileOPerator;

/*
 创建CSV新的一条测试记录。
 @param Record 测试的记录，像 @"%@,%@,%@,%@,%@,%@,%@,%@,%@\n" 格式，需要与csvHeader字段相对应。
 @param fileName 文件名字 一般是每天一个CSV，用项目名称加上时间拼接成字符串。
 @param csvHeader CSV的头字段，在创建文件的时候创建一次。
 */


-(void)saveRecordWith:(NSString*)Record fileName:(NSString*)fileName andCsvHeader:(NSString*)csvHeader ;

/*
  目的: 用于创建文件，内容在atlas中写入
  @param : 生成文件夹的路径
 
*/
-(void)createFileWithPath:(NSString *)fileName Records:(NSString *)Records;


@end
