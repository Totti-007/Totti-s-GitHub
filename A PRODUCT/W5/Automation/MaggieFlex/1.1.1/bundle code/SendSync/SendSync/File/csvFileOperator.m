//
//  csvFileOperator.m
//  LeftButtonFlexCompassSenorTest
//
//  Created by linanlin on 2017/5/10.
//  Copyright © 2017年 linanlin. All rights reserved.
//

#import "csvFileOperator.h"
@interface csvFileOperator ()
@end
@implementation csvFileOperator
static csvFileOperator*csvFileManger=nil;
+(instancetype)ShareCsvFileOPerator
{
    if (csvFileManger==nil) {
        csvFileManger=[[csvFileOperator alloc]init];
    }
    return csvFileManger;
}
//-(NSString*)dataFilePathWith:(NSString*)fileName
//{
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    return [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.csv",fileName]];
//    
//}
-(void)saveRecordWith:(NSString *)Record fileName:(NSString *)fileName andCsvHeader:(NSString *)csvHeader
{
    
     /*创建文件夹*/
     NSString *folderPath = [fileName componentsSeparatedByString:@"/Summary"][0];
     if (![[NSFileManager defaultManager] fileExistsAtPath:folderPath]) {
          [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
          
     }

     
     /*创建文件*/
     
     
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
        [[NSFileManager defaultManager] createFileAtPath: fileName contents:nil attributes:nil];
        
        NSFileHandle *handle=[NSFileHandle fileHandleForWritingAtPath: fileName ];
        //say to handle where's the file fo write
        [handle truncateFileAtOffset:[handle seekToEndOfFile]];
        //position handle cursor to the end of file
        [handle writeData:[csvHeader dataUsingEncoding:NSUTF8StringEncoding]];
        [handle closeFile];
        
    }
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath: fileName ];
    //say to handle where's the file fo write
    [handle truncateFileAtOffset:[handle seekToEndOfFile]];
    //position handle cursor to the end of file
    [handle writeData:[Record dataUsingEncoding:NSUTF8StringEncoding]];
    [handle closeFile];

}



-(void)createFileWithPath:(NSString *)fileName Records:(NSString *)Records{
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
        [[NSFileManager defaultManager] createFileAtPath: fileName contents:nil attributes:nil];
        
        NSFileHandle *handle=[NSFileHandle fileHandleForWritingAtPath: fileName ];
        //say to handle where's the file fo write
        [handle truncateFileAtOffset:[handle seekToEndOfFile]];
        //position handle cursor to the end of file
        [handle closeFile];
    }
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath: fileName ];
    //say to handle where's the file fo write
    [handle truncateFileAtOffset:[handle seekToEndOfFile]];
    //position handle cursor to the end of file
    [handle writeData:[Records dataUsingEncoding:NSUTF8StringEncoding]];
    [handle closeFile];
}


@end
