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
#import "UnitTest.h"

typedef id (^PromiseBlock)          (id result);
typedef id (^PromiseSuccessBlock)   (id result);
typedef id (^PromiseErrorBlock)     (NSError* error);
typedef id (^PromiseAfterBlock)     (NSMutableDictionary* results,
                                     NSInteger errors);
typedef id (^PromiseIterationBlock) (id result,
                                     NSInteger step);

typedef void (^PromiseCancelBlock)  (void);

@interface Promise : NSObject

/*******************************************************************
 promise.errorBlock = 
 *******************************************************************/
@property (readwrite, strong, nonatomic) Promise*         next;
@property (readwrite, weak,   nonatomic) Promise*         prev;
@property (readwrite, strong, nonatomic) dispatch_queue_t queue;
@property (readwrite,         nonatomic) NSInteger        debug;
@property (readwrite,         nonatomic) NSInteger        serialNumber;
@property (readwrite, strong, nonatomic) NSString*        name;

/*******************************************************************
 If context is set, any blocks executed by this promise will be
 executed on the queue associated with the context, allowing
 MOs to be easily referenced in the background. 
 *******************************************************************/
@property (readwrite, weak,   nonatomic) NSManagedObjectContext* context;

/*******************************************************************
 promiseWithName creates a new Promise with the name property set 
 *******************************************************************/
+ (Promise*) promiseWithName: (NSString*) name;

/*******************************************************************
 resolvedWith: and resolvedWithError: create Promises that trigger 
 as soon as a "next" Promise is set.
 *******************************************************************/
+ (Promise*)      resolvedWith: (id)        result;
+ (Promise*)      resolved;                          // Promise resolved with nil

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
 
 thenError: and thenErrorMainQ: returns both normal result and
 error result to the same block.
 *******************************************************************/
- (Promise*)      then: (PromiseSuccessBlock) successBlock
                 error: (PromiseErrorBlock)   errorBlock;
- (Promise*)      then: (PromiseSuccessBlock) successBlock;
- (Promise*) thenError: (PromiseBlock)        promiseBlock;

- (Promise*)      thenMainQ: (PromiseSuccessBlock) successBlock
                      error: (PromiseErrorBlock)   errorBlock;
- (Promise*)      thenMainQ: (PromiseSuccessBlock) successBlock;
- (Promise*) thenErrorMainQ: (PromiseBlock)        promiseBlock;

- (void) cancel: (PromiseCancelBlock) cancelBlock;

/*******************************************************************
 iterate:
 
 The iteration block works similarly to a then block, but with a
 difference that allows a sequence of similar operations to be 
 performed serially as in a for loop.
 
 In a then: block, return <promise> means to execute the 'next' 
 promise block when the returned promise is resolved. In an 
 iteration: block, return <promise> means execute the iteration 
 block again when the promise is resolved. The integer 'step'
 provides some context to the block code. It will be set to zero 
 on the first iteration and be incremented by 1 on each successive 
 iteration.
 
 If a non-promise object or nil is returned by the iteration block
 then the loop will be terminated and the object (or nil) will be
 used to resolve the current promise and the object will be passed 
 to the 'next' block.
 *******************************************************************/
- (Promise*) iterate: (id(^)(id result, NSInteger step)) iterationBlock;

/*******************************************************************
 after creates a promise that is resolved when all promises in the
 dictOfPromises are resolved. None of these promises should already
 have Success and/or Error blocks attached. In any case they will
 not be called.
 
 When an "after" Promise is resolved, the result passed to its
 block is a dictionary of result objects that matches the dictionary
 of Promises. The key for the promise is the key for the result.
 
 The signature of the PromiseAfterBlock includes an errors argument.
 It gives the number of results in the dictionary of results that
 are NSErrors.
 *******************************************************************/
+ (Promise*) after: (NSDictionary*)     dictOfPromises
                do: (PromiseAfterBlock) block;

- (Promise*) after: (NSDictionary*)     dictOfPromises
                do: (PromiseAfterBlock) block;

/*******************************************************************
 rerun:
 
 Rerun the same block when the new promise resolves. Use this to 
 construct a for loop pattern. In the block, call rerun method and
 then return nil.
 *******************************************************************/
- (void) rerun: (Promise*) rerunPromise;

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
- (void) runInContext: (NSManagedObjectContext*) context;
- (void) runOnMainQueue;
- (void) runDefault;
- (void) runLowPriority;
- (void) runHighPriority;
- (void) runLowestPriority;

+ (NSString*) queueName;
+ (NSString*) queueName: (dispatch_queue_t) queue;

@end
