//
//  PlistOperator.h
//  Framework
//
//  Created by Robin on 2018/11/13.
//  Copyright © 2018年 RobinCode. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreTestFoundation/CoreTestFoundation.h>

@interface PlistOperator : NSObject

-(void)setPlistValue:(NSString*)value forKey:(NSString*)key;
-(NSString *)readValueForKey:(NSString *)key;
@end
