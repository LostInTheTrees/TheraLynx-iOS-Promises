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

#import "Promise.h"

@interface Promise ()

@property (readwrite,         nonatomic) NSInteger resolutionType;
#define RTVIRGIN      0 // No resolution determined yet
#define RTBLOCKS      1 // Block(s) attached
#define RTPASSTHROUGH 2 // Returned, result passes through to Next
#define RTAGGREGATED  3 // Result is delivered to an aggregate Promise in Next
#define RTAFTER       4 // An aggregate, triggers when all Promises are complete

@property (readwrite,         nonatomic) BOOL      alreadyResolved;
@property (readwrite,         nonatomic) BOOL      aggregated;
@property (readwrite,         nonatomic) NSInteger generation; // Debug modifier for name
@property (readwrite, strong, nonatomic) id        result;
@property (readwrite, strong, nonatomic) id      (^successBlock) (id       result);
@property (readwrite, strong, nonatomic) id      (^errorBlock)   (NSError* error);
@property (readwrite, strong, nonatomic) id      (^afterBlock)   (NSMutableDictionary* results);

@property (readwrite, strong, nonatomic) NSMutableDictionary*  dictOfResults;
@property (readwrite,         nonatomic) NSInteger aggregationIndex;
// The aggregationIndex indicates that when non-zero this promise is aggregated

@end

@implementation Promise {
    NSString* _name;
    int       _generation;
}

#ifdef UNITTEST
/*******************************************************************
 Sets a Unit Testing delegate for all Promises
 *******************************************************************/
+ (id) utDelegate: (id) delegate
{
    static id _utDelegate;
    if (delegate) {
        _utDelegate = delegate;
        return nil;
    } else {
        return _utDelegate;
    }
}
#endif

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
#ifdef UNITTEST
    if ([Promise utDelegate: nil]) [[Promise utDelegate: nil] allocation];
#endif
    if (_debug) QNSLOG(@"");
    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.name = @"-";
    self.resolutionType = RTVIRGIN;
    self.alreadyResolved = NO;
    return self;
}

- (void) dealloc
{
    if (_debug>1) QNSLOG(@"%@", self.name);
    
#ifdef UNITTEST
    if ([Promise utDelegate: nil]) [[Promise utDelegate: nil] deallocation];
#endif
}

- (void) setName: (NSString*) name
{
    _name = name;
    _generation = 0;
}

- (NSString*) name
{
    return [NSString stringWithFormat: @"%@.%d", _name, _generation];
}

- (NSString*) describeChain: (id) start
{
    NSString* d = self.name;
    if (_resolutionType == RTVIRGIN) d = [d stringByAppendingFormat: @" VIRGIN"];
    if (_resolutionType == RTBLOCKS) d = [d stringByAppendingFormat: @" BLOCKS"];
    if (_resolutionType == RTPASSTHROUGH) d = [d stringByAppendingFormat: @" PASSTHROUGH"];
    if (_resolutionType == RTAGGREGATED) d = [d stringByAppendingFormat: @" AGGREGATED"];
    if (_resolutionType == RTAFTER) d = [d stringByAppendingFormat: @" AFTER"];
    if (_successBlock) d = [d stringByAppendingFormat: @" (then)"];
    if (_errorBlock) d = [d stringByAppendingFormat: @" (error)"];
    if ([self willRunOnMainQueue]) d = [d stringByAppendingFormat: @" (main)"];
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
 
 Ensure that this Promise block runs on the main queue
 Default queue is background
 *******************************************************************/
- (void) runOnMainQueue
{
    if (_debug>1) QNSLOG(@"%@", self.name);
    self.queue = dispatch_get_main_queue();
}

- (BOOL) willRunOnMainQueue
{
     return (self.queue == dispatch_get_main_queue());
}

- (void) runDefault
{
    if (_debug>1) QNSLOG(@"%@", self.name);
    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
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
    if (_alreadyResolved && self.resolutionType == RTPASSTHROUGH) [self resolve: self.result];
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
    
    if (_debug) QNSLOG(@"%@ %d", self.name, self.resolutionType);
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
    if (_resolutionType == RTPASSTHROUGH) {
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
        if (success) {
            // Success
            assert(_successBlock);
        } else {
            // Error
            if (_errorBlock == nil) {
                assert(_next);
                [_next resolve: result];
                return;
            }
        }
    }
    dispatch_async(self.queue, ^(void) {
        id newReturn;

        // Call a block and get a return object
        if (after) {
            if (_debug>1) QNSLOG(@"%@ After Block", self.name);
            newReturn = _afterBlock(self.dictOfResults);
        } else if (success) {
            if (_debug>1) QNSLOG(@"%@ Success Block", self.name);
            newReturn = _successBlock(result);
        } else {
            if (_debug>1) QNSLOG(@"%@ Error Block", self.name);
            newReturn = _errorBlock((NSError*) result);
        }
        // Is the return a Promise?
        if ([newReturn isKindOfClass: [Promise class]]) {
            if (_debug>1) QNSLOG(@"%@ New Promise returned", self.name);
            Promise* promise = (Promise*) newReturn;
            promise.resolutionType = RTPASSTHROUGH;
            promise.next = self.next;
            // Whatever Promise is waiting for this one (self.next) will
            // be triggered by the new promise when it is resolved.
            // The current Promise does not resolve self.next.
            // The job has been turned over to the new Promise.
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
    });
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
 Attach success and error blocks to an existing promise.
 Create a new Promise that will be fulfilled by these blocks.
 The new Promise is set to run on the same queue as this Promise.
 The user can change that after the new Promise is received.
 *******************************************************************/
- (Promise*) then:  (id (^)(id        result)) successBlock
             error: (id (^)(NSError*  error))  errorBlock
{
    if (_debug) QNSLOG(@"%@", self.name);
    self.resolutionType = RTBLOCKS;
    self.successBlock = successBlock;
    self.errorBlock = errorBlock;
    Promise* p = [[Promise alloc] init];
    p.queue = self.queue;
    p.debug = self.debug;
    p.name = _name;
    p.generation = self.generation + 1;
    self.next = p; // Must be last
    if (_result) [self resolve: _result];
    return p;
}

/*******************************************************************
 For when no error block is needed.
 *******************************************************************/
- (Promise*) then: (id (^)(id result)) successBlock
{
    return [self then: successBlock
                error: nil];
}

/*******************************************************************
 after creates a promise that is resolved when all promises in the
 arrayOfPromises are resolved. None of these promises should already
 have Success and/or Error blocks attached. In any case they will
 not be called.
 
 When an "all" Promise is resolved, the result passed to its
 block is a disctionary of result objects that matches the array
 of Promises. The result from the second Promise in the array is
 found at [results objectForKey: @(2)].
 *******************************************************************/
- (Promise*) after: (NSArray*)                             arrayOfPromises
                do: (id (^)(NSMutableDictionary* results)) block
{
    int i = 0;
    
    self.resolutionType = RTAFTER;
    self.afterBlock = block;
    self.dictOfResults = [NSMutableDictionary new];
    // Prep the aggregated Promises
    for (Promise* p in arrayOfPromises) {
        i++;
        [_dictOfResults setObject: [Promise class] // used as a unique marker
                           forKey: @(i)];
        p.resolutionType = RTAGGREGATED;
        p.next = self;
        p.aggregationIndex = i;
    }
    if (self.debug>1) QNSLOG(@"\n%@\n%@", [self description], [_dictOfResults description]);

    // Prep the dependent Promise
    Promise* p0 = [[Promise alloc] init];
    p0.queue = self.queue;
    p0.debug = self.debug;
    p0.name = _name;
    p0.generation = self.generation + 1;
    self.next = p0; // Must be last
    return p0;
}

/*******************************************************************
 aggregate
 *******************************************************************/
- (void) aggregateResult: (id) result
               withIndex: (NSInteger) index
{
    @synchronized(self) {
        if (self.debug) QNSLOG(@"%@ %d %d", self.name, index, self.resolutionType);
        if (result) {
            [_dictOfResults setObject: result
                               forKey: @(index)];
        } else {
            [_dictOfResults setObject: [NSNull null]
                               forKey: @(index)];
        }
        for (id key in [_dictOfResults allKeys]) {
            id obj = [_dictOfResults objectForKey: key];
            if (obj == [Promise class]) {
                // One of our markers is still present, don't resolve the "after" yet
                return;
            }
        }
        if (self.debug>1) QNSLOG(@"%@ %d Ready", self.name, index);
        [self resolve: self.dictOfResults];
    }
}

@end
