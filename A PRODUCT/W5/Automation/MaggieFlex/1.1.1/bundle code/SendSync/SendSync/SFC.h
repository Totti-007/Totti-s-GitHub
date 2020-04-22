//
//  SFC.h
//  LCRFixture
//
//  Created by 王宗祥 on 2017/11/4.
//  Copyright © 2017年 wuzhen Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#define SFC_OK 0
#define SFC_ERROR 1
#define SFC_FATAL_ERROR 2
#define SFC_DATA_FORMAT_ERROR 3
#define SFC_INVALID_COMMAND_ERROR 4
#define SFC_UNKNOWN_RESPONSE 13

#define SFC_CONNECTION_FAILED 9900
#define SFC_RESPONSE_NOT_FOUND 9901
#define SFC_OUT_OF_PROCESS 9902
#define SFC_NO_AVAILABLE_SN 9903
#define SFC_WORKORDER_NOT_OK 9904
#define ERR_SERIALBURNED 9905
@interface SFC : NSObject{
       int SFC_ID;
}
@property (atomic) int ERROR_NUMBER;
@property (retain, atomic) NSString* ERROR_MESSAGE;
@property (retain, atomic) NSString* SERIAL_NUMBER;
-(NSString*)checkSFCStateWithSN:(NSString *)SN;
-(NSString*)getInfoWithSN:(NSString *)SN;
-(NSString*)checkSN:(NSString *)SN;
-(NSString*)getInfoWithStationID;

@end
