//
//  PFQuery+Promise.h
//  PT1
//
//  Created by Bob Carlson on 2013-09-12.
//
//

#import <Parse/Parse.h>
#import "PromiseParseBridge.h"

@interface PFQuery (Promise)

+ (Promise*)  promise_getObjectInClass: (NSString*) clss
                                withId: (NSString*) pid;  // Promises a PFObject

+ (Promise*) promise_getObjectsInClass: (NSString*) clss
                               withIds: (NSArray*)  pids; // Promises an array of PFObject

//+ (Promise*) promise_getObjectsWithIds: (NSArray*)  pids; // Promises an array of PFObject

- (Promise*) promise_getObjectWithId: (NSString*) pid; // Promises a PFObject
- (Promise*) promise_findObjects;                      // Promises an array of PFObject
- (Promise*) promise_countObjects;                     // Promises an NSNumber
- (Promise*) promise_getFirstObject;                   // Promises a PFObject


@end
