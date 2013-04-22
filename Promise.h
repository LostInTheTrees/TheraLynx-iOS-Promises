/*******************************************************************
 iOS Promises
 
 Promise.h

 Copyright Bob Carlson, TheraLynx LLC, 2013, All rights reserved.
 
 This work is licensed under the Creative Commons Attribution-
 ShareAlike 3.0 Unported License. To view a copy of this license, 
 visit http://creativecommons.org/licenses/by-sa/3.0/ or send a 
 letter to Creative Commons, 444 Castro Street, Suite 900, 
 Mountain View, California, 94041, USA.
 
 Under this licence you may use this work and redistribute
 deriviatives of this work as long as you make available any
 changes and credit the use of the work by attributing the work to
 "Bob Carlson, TheraLynx LLC".
 *******************************************************************/
#import <Foundation/Foundation.h>
#import "QLog.h"

@interface Promise : NSObject

@property (readwrite, strong, nonatomic) Promise*         next;
@property (readwrite, weak,   nonatomic) Promise*         prev;
@property (readwrite, strong, nonatomic) dispatch_queue_t queue;
@property (readwrite,         nonatomic) NSInteger        debug;
@property (readwrite, strong, nonatomic) NSString*        name;


/*******************************************************************
 promiseWithName creates a new Promise with the name property set 
 *******************************************************************/
+ (Promise*) promiseWithName: (NSString*) name;

/*******************************************************************
 resolvedWith: and resolvedWithError: create Promises that trigger 
 as soon as a "next" Promise is set
 *******************************************************************/
+ (Promise*)      resolvedWith: (id)        result;

+ (Promise*) resolvedWithError: (NSInteger) code
                   description: (NSString*) desc;

/*******************************************************************
 getError creates an NSError for use in resolve()
 *******************************************************************/
+ (NSError*)          getError: (NSInteger) code
                   description: (NSString*) desc;

/*******************************************************************
 Resolve triggers a Promise with the result object
 If an NSError is passed, the error block is called
 
 Reject triggers a Promise with an NSError object
 The NSError is created from parameters
 *******************************************************************/
- (void) resolve: (id)        result;

- (void)  reject: (NSInteger) code
     description: (NSString*) desc;

/*******************************************************************
 then: and then:error: attach success and error blocks to a 
 Promise. At the same time, they create a new Promise that will 
 be satisfied by the object returned by the blocks.
 
 If the error block is triggered, but the error block is omitted, 
 then the error automatically cascades to the next Promise, if any.
 
 At least in a debug build, any error unhandled by an error block
 should cause an exception.
 *******************************************************************/
- (Promise*) then: (id (^)(id result))      successBlock;

- (Promise*) then: (id (^)(id result))      successBlock
            error: (id (^)(NSError* error)) errorBlock;

/*******************************************************************
 These methods cause the blocks to run on the specified global queues.
 *******************************************************************/
- (void) runOnMainQueue;
- (BOOL) willRunOnMainQueue;
// Test whether this Promise's blocks will run on the main queue

- (void) runDefault;
- (void) runLowPriority;
- (void) runHighPriority;

@end
