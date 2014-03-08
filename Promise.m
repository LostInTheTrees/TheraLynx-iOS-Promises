/*******************************************************************
 iOS Promises
 
 Promise.m
 
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

#import <CoreData/CoreData.h>
#import "Promise.h"
#import "UnitTest.h"

@interface Promise ()

@property (readwrite,         nonatomic) NSInteger resolutionType;
#define RTVIRGIN      0 // No resolution determined yet
#define RTBLOCKS      1 // Block(s) attached
#define RTITERATE     2 // Block(s) attached, a returned promise becomes the prev of this one
#define RTPASSTHROUGH 3 // Returned, result passes through to Next
#define RTAGGREGATED  4 // Result is delivered to an aggregate Promise in Next
#define RTAFTER       5 // An aggregate, triggers when all Promises are complete
#define RTCANCELLED   6 // This Promise has been cancelled

@property (readwrite,         nonatomic) BOOL      alreadyResolved;
@property (readwrite,         nonatomic) BOOL      aggregated;
@property (readwrite, strong, nonatomic) id        result;

@property (readwrite, strong, nonatomic) PromiseSuccessBlock   successBlock;
@property (readwrite, strong, nonatomic) PromiseErrorBlock     errorBlock;

@property (readwrite, strong, nonatomic) PromiseIterationBlock iterationBlock;

@property (readwrite, strong, nonatomic) PromiseAfterBlock     afterBlock;
@property (readwrite, strong, nonatomic) PromiseAfterBlock     afterErrorBlock;

@property (readwrite, strong, nonatomic) PromiseCancelBlock    cancelBlock;

// After - aggregated promises
@property (readwrite,         nonatomic) NSInteger             aggregatedErrors;
@property (readwrite, strong, nonatomic) NSMutableDictionary*  dictOfResults;
@property (readwrite, strong, nonatomic) NSDictionary*         dictOfPromises;
// dictOfPromises functions as the "prev" pointer for "after" Promises

@property (readwrite, copy,   nonatomic) NSString* aggregationIndex;
// The aggregationIndex indicates that when non-zero this promise is aggregated

// For use with iterate
@property (readwrite,         nonatomic) NSInteger iterationStep;

// For use with rerun
@property (readwrite,         nonatomic) BOOL      runningBlock;
@property (readwrite,         nonatomic) BOOL      rerunCalled;


@end

@implementation Promise

@synthesize name = _name;

//  #ifdef UNITTEST
/*******************************************************************
 Sets a Unit Testing delegate for all Promises
 *******************************************************************/
+ (id <UnitTest>) utDelegate: (id) delegate
{
    static id <UnitTest> _utDelegate;
    if (delegate) {
        _utDelegate = delegate;
        return nil;
    } else {
        return _utDelegate;
    }
}
//  #endif

/*******************************************************************
 Generate a serial number for each promise
 *******************************************************************/
+ (NSInteger) serialNumber
{
    static NSInteger nextSerialNumber;
    return ++nextSerialNumber;
}

/*******************************************************************
 promiseWithName creates a new Promise with the name property set
 *******************************************************************/
+ (Promise*) promiseWithName: (NSString*) name
{
    Promise* p = [[Promise alloc] init];
    p.name = name;
    return p;
}

/*******************************************************************
 Create a "pre-resolved" Promise with a result object
 The result object can be nil or an NSError
 *******************************************************************/
+ (Promise*) resolvedWith: (id) result
{
    Promise* p = [[Promise alloc] init];
    p.alreadyResolved = YES;
    p.result = result;
    return p;
}

+ (Promise*) resolved
{
    return [Promise resolvedWith: nil];
}

/*******************************************************************
 Create a "pre-resolved" Promise with a created NSError object
 *******************************************************************/
+ (Promise*) resolvedWithError: (NSInteger) code
                   description: (NSString*) desc
{
    return [Promise resolvedWith: [self getError: code
                                      description: desc]];
}


/*******************************************************************
 Set or get the default error domain for NSErrors created by Promise.
 Pass nil to Get the domain, pass a string to set it.
 *******************************************************************/
+ (NSString*) errorDomain: (NSString*) ed
{
    static NSString* _errorDomain;
    if (ed) _errorDomain = ed;
    if (!_errorDomain) _errorDomain = @"User"; // default error domain
    return _errorDomain;
}


/*******************************************************************
 Create an NSError and return it, using the default error domain
 *******************************************************************/
+ (NSError*) getError: (NSInteger) code
          description: (NSString*) desc
{
    return [[NSError alloc] initWithDomain: [Promise errorDomain: nil]
                                      code: code
                                  userInfo: @{ NSLocalizedDescriptionKey : NSLocalizedString(desc, nil)}];
}



- (Promise*) init
{
    assert( (self = [super init]) );
    //#ifdef UNITTEST
    id <UnitTest> ut = [Promise utDelegate: nil];
    if (ut) [ut allocation];
    //#endif
    if (_debug) QNSLOG(@"");
    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.name = @"-";
    self.serialNumber = [Promise serialNumber];
    self.resolutionType = RTVIRGIN;
    self.alreadyResolved = NO;
    self.runningBlock = NO;
    self.rerunCalled = NO;
    self.context = nil;
    self.iterationStep = 0;
    return self;
}

- (void) dealloc
{
    if (_debug>1)
        QNSLOG(@"%@", self.name);
    
#ifdef UNITTEST
    id <UnitTest> ut = [Promise utDelegate: nil];
    if (ut) [ut deallocation];
#endif
}

- (void) setName: (NSString*) name
{
    _name = name;
}

- (NSString*) name
{
    return [NSString stringWithFormat: @"%@(%d)", _name, _serialNumber];
}

+ (NSString*) nameKey
{
    static NSString* key;
    if (!key) {
        key = @"promise queue name key";
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_queue_set_specific(queue, (__bridge const void *)(key), @"Default", NULL);
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        dispatch_queue_set_specific(queue, (__bridge const void *)(key), @"Low", NULL);
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_queue_set_specific(queue, (__bridge const void *)(key), @"High", NULL);
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_queue_set_specific(queue, (__bridge const void *)(key), @"Lowest", NULL);
        queue = dispatch_get_main_queue();
        dispatch_queue_set_specific(queue, (__bridge const void *)(key), @"Main", NULL);
    }
    return key;
}

+ (NSString*) queueName
{
    return (__bridge NSString *)(dispatch_get_specific((__bridge const void *)([Promise nameKey])));
}

+ (NSString*) queueName: (dispatch_queue_t) queue
{
    NSString* s = (__bridge NSString *)(dispatch_queue_get_specific(queue, (__bridge const void *)([Promise nameKey])));
    if (!s) s = @"";
    return s;
}

- (NSString*) describeChain: (id) start
{
    NSString* d = self.name;
    if (_resolutionType == RTVIRGIN) d = [d stringByAppendingFormat: @" VIRGIN"];
    if (_resolutionType == RTBLOCKS) d = [d stringByAppendingFormat: @" NORMAL"];
    if (_resolutionType == RTITERATE) d = [d stringByAppendingFormat: @" ITERATE"];
    if (_resolutionType == RTPASSTHROUGH) d = [d stringByAppendingFormat: @" PASSTHROUGH"];
    if (_resolutionType == RTAGGREGATED) d = [d stringByAppendingFormat: @" AGGREGATED"];
    if (_resolutionType == RTAFTER) d = [d stringByAppendingFormat: @" AFTER"];
    if (_successBlock) d = [d stringByAppendingFormat: @" (then)"];
    if (_errorBlock) d = [d stringByAppendingFormat: @" (error)"];
    if (self.queue) d = [d stringByAppendingFormat: @" (%@)", [Promise queueName: self.queue]];
    if (start == self) d = [d stringByAppendingFormat: @" *****"];
    if (self.next) d= [NSString stringWithFormat: @"%@ ->\n%@", d, [self.next describeChain: start]];
    //QNSLOG(@"%@", d);
    return d;
}

- (NSString*) description: (id) start
{
    //QNSLOG(@"%@ prev %@ next %@", self.name, self.prev.name, self.next.name);
    if (self.prev) return [self.prev description: start];
    else return [self describeChain: start];
}

- (NSString*) description
{
    //QNSLOG(@"%@", self.name);
    return [self description: self];
}

/*******************************************************************
 runOnMainQueue

 Ensure that this Promise block runs on the queue associated with 
 the context.
 *******************************************************************/
- (void) runInContext: (NSManagedObjectContext*) context
{
    if (_debug>1) QNSLOG(@"%@", self.name);
    self.context = context;
}

/*******************************************************************
 runOnMainQueue
 
 Ensure that this Promise block runs on the main queue
 Default queue is background
 *******************************************************************/
- (void) runOnMainQueue
{
    if (_debug>1) QNSLOG(@"%@", self.name);
    self.queue = dispatch_get_main_queue();
}

- (void) runDefault
{
    if (_debug>1) QNSLOG(@"%@", self.name);
    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}

- (void) runLowestPriority
{
    if (_debug>1) QNSLOG(@"%@", self.name);
    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
}

- (void) runLowPriority
{
    if (_debug>1) QNSLOG(@"%@", self.name);
    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
}

- (void) runHighPriority
{
    if (_debug>1) QNSLOG(@"%@", self.name);
    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
}

/*******************************************************************
 Set the dependent Promise for this Promise
 When a promise has completed, the returned result, if any, will
 be used to resolve the "next" Promise.
 *******************************************************************/
- (void) setNext: (Promise*) next
{
    if (_debug>1) QNSLOG(@"Set Next %@ -> %@\n%@", self.name, _next.name, self.description);
    _next = next;
    next.prev = self;
    if (_alreadyResolved && self.resolutionType == RTPASSTHROUGH)
        [self resolve: self.result];
}

/*******************************************************************
 rerun:
 
 Rerun the same block when the new promise resolves. Use this to
 construct a for loop pattern. In the block, call rerun method and
 then return nil.

 Should only be called inside a success block.
 *******************************************************************/
- (void) rerun: (Promise*) rerunPromise
{
    if (_debug) QNSLOG(@"%@ Rerun with a new Promise", self.name);
    if (_debug>1) QNSLOG(@"%@", self.description);
    if (!self.runningBlock) return;
    rerunPromise.resolutionType = RTPASSTHROUGH;
    rerunPromise.next = self;
    self.prev = rerunPromise;
    self.rerunCalled = YES;
    return;
}

/*******************************************************************
 Resolve this Promise
 
 - Execute the appropriate block and deal with the returned objects.
 - If a Promise is returned, let the dependent of this Promise be
   resolved by the new PomiOSe in the future.
 - Any other return causes the dependent Promise, if any, to be 
   resolved.
 *******************************************************************/
- (void) resolve: (id) result
{
    BOOL success;
    BOOL after;

    if (_debug > 1) QNSLOG(@"%@ %d %@", self.name, self.resolutionType, [(NSObject*)result description]);
    if ([result isKindOfClass: [Promise class]]) {
        if (_debug>1) QNSLOG(@"%@ Resolved with a new Promise", self.name);
        Promise* promise = (Promise*) result;
        promise.next = self.next;
        // Whatever Promise is waiting for this one (self.next) will
        // be triggered by the new promise when it is resolved.
        // The current Promise does not resolve self.next.
        // The job has been turned over to the new Promise.
        return;
    }
    if (_resolutionType == RTCANCELLED) {
        return;
    } else if (_resolutionType == RTPASSTHROUGH) {
        [_next resolve: result];
        return;
    } else if (_resolutionType == RTVIRGIN) {
        _alreadyResolved = YES;
        _result = result;
        return;
    } else if (_resolutionType == RTAGGREGATED) {
        [self.next aggregateResult: result
                         withIndex: _aggregationIndex];
        return;
    }
    
    // Going to resolve here,
    if (_resolutionType == RTAFTER) {
        // This is an aggregate Promise
        success = NO;
        after = YES;
    } else {
        after = NO;
        success = ![result isKindOfClass: [NSError class]];
        if (!success) {
            // Error
            if (_errorBlock == nil) {
                assert(_next);
                [_next resolve: result];
                return;
            }
        }
    }

    void (^runBlock)(void) =
    ^{
        id newReturn;

        // Call a block and get a return object
        if (after) {
            if (_debug>1) QNSLOG(@"%@ After Block", self.name);
            newReturn = _afterBlock((NSMutableDictionary*) result, self.aggregatedErrors);
        } else if (success) {
            if (_debug>1) QNSLOG(@"%@ Success Block", self.name);
            self.runningBlock = YES;
            if (_resolutionType == RTITERATE) {
                newReturn = _iterationBlock(result, _iterationStep);
                self.iterationStep++;
            } else {
                newReturn = _successBlock(result);
            }
            self.runningBlock = NO;
        } else {
            if (_debug>1) QNSLOG(@"%@ Error Block", self.name);
            self.runningBlock = YES;
            newReturn = _errorBlock((NSError*) result);
            self.runningBlock = NO;
        }
        if (self.rerunCalled) {
            assert(!newReturn);
            self.rerunCalled = NO;
            return;
        }
        // Is the return a Promise?
        if ([newReturn isKindOfClass: [Promise class]]) {
            if (_debug>1) QNSLOG(@"%@ New Promise returned", self.name);
            Promise* promise = (Promise*) newReturn;
            promise.resolutionType = RTPASSTHROUGH;
            if (_resolutionType == RTITERATE) {
                promise.next = self;
                self.prev = promise;
            } else {
                promise.next = self.next;
                // Whatever Promise is waiting for this one (self.next) will
                // be triggered by the new promise when it is resolved.
                // The current Promise does not resolve self.next.
                // The job has been turned over to the new Promise.
            }
            return;
        }
        // It's a result or an error
        if (self.debug>1) QNSLOG(@"%@ Resolving Next", self.name);
        if (self.next) {
            [self.next resolve: newReturn];
        } else {
            // This in case the "next" Promise is not set until after the resolution blocks have returned
            self.result = newReturn;
            self.alreadyResolved = YES;
            self.resolutionType = RTPASSTHROUGH;
        }
    };

    if (self.context) {
        [self.context performBlock: runBlock];
    } else {
        dispatch_async(self.queue, runBlock);
    }
}

/*******************************************************************
 Create an NSError and use it to resolve this Promise.
 *******************************************************************/
- (void)  reject: (NSInteger) code
     description: (NSString*) desc
{
    if (_debug) QNSLOG(@"%@", self.name);
    [self resolve: [Promise resolvedWith: [Promise getError: code
                                                description: desc]]];
}

/*******************************************************************
 Cancel
 *******************************************************************/
- (void) cancel
{
    if (_debug>1) {
        QNSLOG(@"%@  prev %@  next %@", self.name, self.prev.name, self.next.name);
    } else if (_debug) {
        QNSLOG(@"%@", self.name);
    }

    Promise* dependent = _next;
    
    // Now cancel this promise and all of its predecessors
    [self performCancel];
    if (dependent) {
        // If this Promise has dependents,send an error to them
        NSDictionary* desc = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Promise cancelled", nil)};
        NSError* err = [[NSError alloc] initWithDomain: @"Promise"
                                                  code: 9999
                                              userInfo: desc];
        [dependent resolve: err];
    }
}

- (void) performCancel
{
    if (_debug) {
        QNSLOG(@"%@ %@", self.name, [_dictOfPromises description]);
    }
    Promise* predecessor = _prev;
    _resolutionType = RTCANCELLED;
    if (_cancelBlock) _cancelBlock(); // Run the Cancel Block
    _cancelBlock = nil;
    _next = nil;
    _prev = nil;
    _successBlock = nil;
    _errorBlock = nil;
    _afterBlock = nil;
    _afterErrorBlock = nil;
    _dictOfResults = nil;
    if (_dictOfPromises) {
        if (_debug>1) {
            QNSLOG(@"%@", [[_dictOfPromises allKeys] description]);
        }
        for (id key in [_dictOfPromises allKeys]) {
            Promise* p = [_dictOfPromises objectForKey: key];
            [p performCancel]; // For an After Promise, cancel each predecessor not yet resolved
        }
        _dictOfPromises = nil;
    } else if (predecessor) {
        [predecessor performCancel];
    }
}

- (void) cancel: (PromiseCancelBlock) cancelBlock
{
    _cancelBlock = cancelBlock;
}

/*******************************************************************
 Attach success and error blocks to an existing promise.
 Create a new Promise that will be fulfilled by these blocks.
 The new Promise is set to run on the same queue as this Promise.
 The user can change that after the new Promise is received.
 *******************************************************************/
- (Promise*) then: (PromiseSuccessBlock) successBlock
            error: (PromiseErrorBlock)   errorBlock
{
    if (_debug) QNSLOG(@"%@", self.name);
    self.resolutionType = RTBLOCKS;
    self.successBlock = successBlock;
    self.errorBlock = errorBlock;
    Promise* p = [[Promise alloc] init];
    p.queue = self.queue;
    p.debug = self.debug;
    p.name = _name;
    self.next = p; // Must be last
    if (self.alreadyResolved) [self resolve: _result];
    return p;
}

/*******************************************************************
 For when no error block is needed.
 *******************************************************************/
- (Promise*) then: (PromiseSuccessBlock) successBlock
{
    return [self then: successBlock
                error: nil];
}

/*******************************************************************
 For use when the then block should return to the main Q
 *******************************************************************/
- (Promise*) thenMainQ: (PromiseSuccessBlock) successBlock
                 error: (PromiseErrorBlock)   errorBlock
{
    [self runOnMainQueue];
    return [self then: successBlock
                error: errorBlock];
}

- (Promise*) thenMainQ: (PromiseSuccessBlock) successBlock
{
    [self runOnMainQueue];
    return [self then: successBlock
                error: nil];
}

/*******************************************************************
 For when results and NSErrors are to be passed to the same block.
 *******************************************************************/
- (Promise*) thenError: (PromiseBlock) promiseBlock
{
    return [self then: promiseBlock
                error: (PromiseErrorBlock) promiseBlock];
}

- (Promise*) thenErrorMainQ: (PromiseBlock) promiseBlock
{
    [self runOnMainQueue];
    return [self then: promiseBlock
                error: (PromiseErrorBlock) promiseBlock];
}

/*******************************************************************
 Attach an iteration block to an existing promise.
 Create a new Promise that will be fulfilled by these blocks.
 The new Promise is set to run on the same queue as this Promise.
 The user can change that after the new Promise is received.
 *******************************************************************/
- (Promise*) iterate: (PromiseIterationBlock) iterationBlock
{
    if (_debug) QNSLOG(@"%@", self.name);
    self.resolutionType = RTITERATE;
    self.iterationBlock = iterationBlock;
    self.errorBlock = nil;
    Promise* p = [[Promise alloc] init];
    p.queue = self.queue;
    p.debug = self.debug;
    p.name = _name;
    self.next = p; // Must be last
    if (self.alreadyResolved) [self resolve: _result];
    return p;
}

/*******************************************************************
 after creates a promise that is resolved when all promises in the
 arrayOfPromises are resolved. None of these promises should already
 have Success and/or Error blocks attached. In any case they will
 not be called.
 
 When an "after" Promise is resolved, the result passed to its
 block is a disctionary of result objects that matches the array
 of Promises. The result from the second Promise in the array is
 found at [results objectForKey: @(2)].
 *******************************************************************/
+ (Promise*) after: (NSDictionary*)     dictOfPromises
                do: (PromiseAfterBlock) block
{
    Promise* p0 = [Promise promiseWithName: @""];
    return [p0 after: dictOfPromises
                  do: block];

}

- (Promise*) after: (NSDictionary*)     dictOfPromises
                do: (PromiseAfterBlock) block
{
    int i = 0;
    
    if (_debug) QNSLOG(@"%@", self.name);
    
    self.resolutionType = RTAFTER;
    self.afterBlock = block;
    self.dictOfResults = [NSMutableDictionary new];
    self.dictOfPromises = dictOfPromises;
    self.aggregatedErrors = 0;
    // _prev is nil;
    // Prep the aggregated Promises
    for (NSString* promiseIndex in dictOfPromises) {
        i++;
        // Make a space for the result, place a marker so we can know when a result has been posted
        [_dictOfResults setObject: [Promise class] // used as a unique marker
                           forKey: promiseIndex];

        Promise* p = [dictOfPromises objectForKey: promiseIndex];
        p.resolutionType = RTAGGREGATED;
        p.next = self;
        p.aggregationIndex = promiseIndex;
    }
    if (_debug>1) QNSLOG(@"\n%@\n%@", self.description, [dictOfPromises description]);

    // Prep the dependent Promise
    Promise* p0 = [Promise promiseWithName: @"after dependent"];
    p0.queue = self.queue;
    p0.debug = self.debug;
    p0.name = _name;
    self.next = p0; // Must be last
    self.resolutionType = RTAFTER;

    if (!self.dictOfPromises.count) [self resolve: self.dictOfResults];
    return p0;
}

/*******************************************************************
 aggregate
 *******************************************************************/
- (void) aggregateResult: (id)        result
               withIndex: (NSString*) index
{
    @synchronized(self) {
        if (self.debug) QNSLOG(@"%@ %@ %d\n%@", self.name, index, self.resolutionType,
                               [(NSObject*) result description]);
        if ([result isKindOfClass: [NSError class]]) {
            _aggregatedErrors++;
        }

        if (result) {
            [_dictOfResults setObject: result
                               forKey: index];
        } else {
            [_dictOfResults setObject: [NSNull null]
                               forKey: index];
        }
        for (id key in [_dictOfResults allKeys]) {
            id obj = [_dictOfResults objectForKey: key];
            if (obj == [Promise class]) {
                // One of our markers is still present, don't resolve the "after" yet
                return;
            }
        }
        if (self.debug) QNSLOG(@"%@ %@ Ready\n%@", self.name, index, self.dictOfResults.description);
        _dictOfPromises = nil;
        [self resolve: self.dictOfResults];
    }
}

@end
