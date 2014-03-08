//
//  PFCloud+Promise.m
//  PT1
//
//  Created by Bob Carlson on 2014-02-07.
//
//

#import "PFCloud+Promise.h"

@implementation PFCloud (Promise)

+ (Promise*) promise_callFunction: (NSString*)     function
                   withParameters: (NSDictionary*) parameters
{
    Promise* p0 = [Promise promiseWithName: @"findObjects"];
    [self callFunctionInBackground: function
                    withParameters: parameters
                            target: p0
                          selector: @selector(parseObject:error:)];
    return p0;
}

@end
