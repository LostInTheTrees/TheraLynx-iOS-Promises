//
//  PFFile+Promise.m
//  PT1
//
//  Created by Bob Carlson on 2013-10-23.
//
//

#import "PFFile+Promise.h"

@implementation PFFile (Promise)

- (Promise*) promise_getData // Promises a BOOL, success/failure
{
    Promise* p0 = [Promise promiseWithName: @"promise_getData"];

    [self getDataInBackgroundWithBlock: [p0 pfDataResultBlock]];

    //    [self getDataInBackgroundWithTarget: p0
    //                           selector: @selector(parseObject:error:)];
    return p0;
}

- (Promise*) promise_save // Promises a BOOL, success/failure
{
    Promise* p0 = [Promise promiseWithName: @"promise_pffile_save"];

    [self saveInBackgroundWithBlock: [p0 pfBooleanResultBlock]];

    //    [self saveInBackgroundWithTarget: p0
    //                            selector: @selector(parseObject:error:)];
    return p0;
}

- (NSString*) originalName: (NSString*) marker
{
    NSArray* a = [[self name] componentsSeparatedByString: marker];
    if (a.count != 2) return self.name;
    return [marker stringByAppendingString: a[1]];
}

@end
