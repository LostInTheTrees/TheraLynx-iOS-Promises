//
//  PFQuery+Promise.m
//  PT1
//
//  Created by Bob Carlson on 2013-09-12.
//
//

#import <Parse/Parse.h>
#import "PFQuery+Promise.h"

@implementation PFQuery (Promise)

/*******************************************************************
 promise_getObjectInClass
 
 Returns a promise for an PFObject
 *******************************************************************/
+ (Promise*) promise_getObjectInClass: (NSString*) clss
                               withId: (NSString*) pid // Promises a PFObject
{
    PFQuery* query = [PFQuery queryWithClassName: clss];
    Promise* p0 = [Promise promiseWithName: @"getObjectWithId"];
    [query getObjectInBackgroundWithId: pid
                                target: p0
                              selector: @selector(parseObject:error:)];
    return p0;
}

+ (Promise*) promise_getObjectsInClass: (NSString*) clss
                               withIds: (NSArray*)  pids // Promises an array of PFObject
{
    PFQuery* query = [PFQuery queryWithClassName: clss];
    [query whereKey: @"objectId" containedIn: pids];
    Promise* p0 = [query promise_findObjects];
    p0.name = @"getObjectsInClass:withIds";
    return p0;
}

- (Promise*) promise_getObjectWithId: (NSString*) pid // Promises a PFObject
{
    Promise* p0 = [Promise promiseWithName: @"getObjectWithId"];
    [self getObjectInBackgroundWithId: pid
                                  target: p0
                                selector: @selector(parseObject:error:)];
    return p0;
}

- (Promise*) promise_findObjects                      // Promises an array of PFObject
{
    Promise* p0 = [Promise promiseWithName: @"findObjects"];
    [self findObjectsInBackgroundWithTarget: p0
                                    selector: @selector(parseObject:error:)];
    return p0;
}

- (Promise*) promise_countObjects                     // Promises an NSNumber
{
    Promise* p0 = [Promise promiseWithName: @"countObjects"];
    [self countObjectsInBackgroundWithTarget: p0
                                     selector: @selector(parseObject:error:)];
    return p0;
}

- (Promise*) promise_getFirstObject                   // Promises a PFObject
{
    Promise* p0 = [Promise promiseWithName: @"getFirstObject"];
    [self getFirstObjectInBackgroundWithTarget: p0
                                      selector: @selector(parseObject:error:)];
    return p0;
}

@end
