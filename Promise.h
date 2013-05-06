/*******************************************************************
 iOS Promises - Version 1.01
 
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
#ifdef UNITTEST
    #import "UnitTest.h"
#endif
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

#ifdef UNITTEST
/*******************************************************************
 Sets a Unit Testing delegate for all Promises
 *******************************************************************/
+ (id <UnitTest>) utDelegate: (id) delegate;
#endif

/*******************************************************************
 then: and then:error: 
 attach success and error blocks to a Promise. At the same time,
 they create a new Promise that will be satisfied by the object 
 returned by the blocks.
 
 If the error block is triggered, but the error block is omitted, 
 then the error automatically cascades to the next Promise, if any.
 
 At least in a debug build, any error unhandled by an error block
 should cause an exception.
 *******************************************************************/
- (Promise*) then: (id   (^)(id result))      successBlock;

- (Promise*) then: (id   (^)(id result))      successBlock
            error: (id   (^)(NSError* error)) errorBlock;

- (void)   cancel: (void (^)())               cancelBlock;

/*******************************************************************
 after creates a promise that is resolved when all promises in the
 arrayOfPromises are resolved. None of these promises should already
 have Success and/or Error blocks attached. In any case they will
 not be called.
 
 When an "all" Promise is resolved, the result passed to its
 block is a dictionary of result objects that matches the array
 of Promises. The result from the second Promise in the array is
 found at [results objectForKey: @(2)].
 
 Note that if an "after" promise is returned from a Success or Error
 block, it becomes a pass-through Promise and the receiving Success
 block must be prepared for an NSMutableDictionary like the "do"
 block.
 
 The error block, if it exists, is called when one or more of the 
 results in the dictionary are NSErrors.
 *******************************************************************/
- (Promise*) after: (NSArray*)                             arrayOfPromises
                do: (id (^)(NSMutableDictionary* results)) block;

- (Promise*) after: (NSArray*)                             arrayOfPromises
                do: (id (^)(NSMutableDictionary* results)) block
             error: (id (^)(NSMutableDictionary* results)) block;

/*******************************************************************
 Resolve triggers a Promise with the result object
 If an NSError is passed, the error block is called
 
 Reject triggers a Promise with an NSError object
 The NSError is created from parameters
 
 cancel causes all processing in the chain of Promises to stop at 
 the first opportunity.
 - walk back the entire Promise chain to the currently "active"
 Promise.
 - Each Promise is the chain is marked cancelled and de-linked 
 so that it should be de-allocated.
 - At the active Promise, if there is a Cancel Block, it is run
 synchronously. If the code that will provide resolution for the 
 Promise is cancellable, it is the Cancel Block's responsibility
 to cancel it.
 - The active Promise is marked as "cancelled". When a Promise
 is resolved, but is marked as cancelled, no further processing takes 
 place.
 *******************************************************************/
- (void) resolve: (id)        result;

- (void)  reject: (NSInteger) code
     description: (NSString*) desc;

- (void)  cancel;

/*******************************************************************
 Queue selection

 These methods cause the blocks to run on the specified global queues.
 *******************************************************************/
- (void) runOnMainQueue;
- (BOOL) willRunOnMainQueue;
// Test whether this Promise's blocks will run on the main queue

- (void) runDefault;
- (void) runLowPriority;
- (void) runHighPriority;

@end
