/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 */

#import "TE_Password.h"

@implementation TE_Password

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        // enter initialization code here
    }
    
    return self;
}


- (BOOL)setupWithContext:(CTContext *)context error:(NSError *__autoreleasing *)error
{
    
    [[NSUserDefaults standardUserDefaults]setObject:@""forKey:@"passNum"];
    return YES;
}

- (BOOL)teardownWithContext:(CTContext *)context error:(NSError *__autoreleasing *)error
{
    return YES;
}

- (CTCommandCollection *)commmandDescriptors
{
    CTCommandCollection *collection = [CTCommandCollection new];

    CTCommandDescriptor * command = [[CTCommandDescriptor alloc] initWithName:@"CheckPassNum" selector:@selector(CheckPassNum:) description:@"Check PassNum"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"PreservePassNum" selector:@selector(PreservePassNum:) description:@"Preserve PassNum"];
    [collection addCommand:command];

    
    return collection;
}

- (void)CheckPassNum:(CTTestContext *)context
{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        if([[[NSUserDefaults standardUserDefaults]objectForKey:@"passNum"]isEqualToString:@"tungsten"])
        {
            context.output = @"OK";
        }
        else
        {
            context.output = @"NULL";
        }
        
        return CTRecordStatusPass;
    }];
}

- (void)PreservePassNum:(CTTestContext *)context
{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        [[NSUserDefaults standardUserDefaults]setObject:context.parameters[@"PassNum"] forKey:@"passNum"];
        
        return CTRecordStatusPass;
    }];
}



@end
