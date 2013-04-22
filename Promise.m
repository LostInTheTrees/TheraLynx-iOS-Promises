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

@property (readwrite,         nonatomic) NSInteger ptype; // 0 - normal, 1 - pre-triggered
@property (readwrite,         nonatomic) NSInteger generation; // Debug modifier for name
@property (readwrite, strong, nonatomic) id        result;
@property (readwrite, strong, nonatomic) id      (^successBlock) (id       result);
@property (readwrite, strong, nonatomic) id      (^errorBlock)   (NSError* error);

@end

@implementation Promise {
    NSString* _name;
    int       _generation;
}

/*******************************************************************
 Create a "pre-resolved" Promise with a result object
 The result object can be nil or an NSError
 *******************************************************************/
+ (Promise*) resolvedWith: (id) result
{
    Promise* p = [[Promise alloc] init];
    p.ptype = 1;
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

+ (Promise*) promiseWithName: (NSString*) name
{
    Promise* p = [[Promise alloc] init];
    p.name = name;
    return p;
}

- (Promise*) init
{
    assert( (self = [super init]) );
    if (_debug) [QLOG(@"")];
    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.name = @"-";
    return self;
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
    if (_successBlock) d = [d stringByAppendingFormat: @" (then)"];
    if (_errorBlock) d = [d stringByAppendingFormat: @" (error)"];
    if ([self willRunOnMainQueue]) d = [d stringByAppendingFormat: @" (main)"];
    if (start == self) d = [d stringByAppendingFormat: @" *****"];
    if (self.next) d= [NSString stringWithFormat: @"%@ ->\n%@", d, self.next.description];
    return d;
}

- (NSString*) description: (id) start
{
    if (self.prev) return [self.prev description: start];
    else return [self describeChain: start];
}

- (NSString*) description
{
    return [self description: self];
}

/*******************************************************************
 runOnMainQueue
 
 Ensure that this Promise block runs on the main queue
 Default queue is background
 *******************************************************************/
- (void) runOnMainQueue
{
    if (_debug>1) [QLOG(@"%@"), self.name];
    self.queue = dispatch_get_main_queue();
}

- (BOOL) willRunOnMainQueue
{
     return (self.queue == dispatch_get_main_queue());
}

- (void) runDefault
{
    if (_debug>1) [QLOG(@"%@"), self.name];
    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}

- (void) runLowPriority
{
    if (_debug>1) [QLOG(@"%@"), self.name];
    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
}

- (void) runHighPriority
{
    if (_debug>1) [QLOG(@"%@"), self.name];
    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
}

- (void) dealloc
{
    if (_debug>1) [QLOG(@"%@"), self.name];
}

/*******************************************************************
 Set the dependent Promise for this Promise
 When a promise has completed, the returned result, if any, will
 be used to resolve the "next" Promise.
 *******************************************************************/
- (void) setNext: (Promise*) next
{
    if (_debug>1) [QLOG(@"Set Next\n%@"), self.description];
    _next = next;
    next.prev = self;
    if (_ptype == 1) [self resolve: self.result];
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
    
    if (_debug) [QLOG(@"%@"), self.name];
    if (_ptype == 2) {
        [_next resolve: result];
        return;
    }
    if ([result isKindOfClass: [Promise class]]) {
        if (_debug>1) [QLOG(@"%@ Resolved with a new Promise"), self.name];
        Promise* promise = (Promise*) result;
        promise.next = self.next;
        // Whatever Promise is waiting for this one (self.next) will
        // be triggered by the new promise when it is resolved.
        // The current Promise does not resolve self.next.
        // The job has been turned over to the new Promise.
        return;
    }
    success = ![result isKindOfClass: [NSError class]];
    if (success) {
        // Success
        if (_successBlock == nil) {
            if (_next != nil) [_next resolve: result];
            return;
        }
    } else {
        // Error
        if (_errorBlock == nil) {
            if (_next != nil) [_next resolve: result];
            else assert(NO); // Errors must be handled, at least during development
            return;
        }
    }
    dispatch_async(self.queue, ^(void) {
        id newReturn;
        if (success) {
            if (_debug>1) [QLOG(@"%@ Success Block"), self.name];
            newReturn = _successBlock(result);
        } else {
            if (_debug>1) [QLOG(@"%@ Error Block"), self.name];
            newReturn = _errorBlock((NSError*) result);
        }
        // Promise?
        if ([newReturn isKindOfClass: [Promise class]]) {
            if (_debug>1) [QLOG(@"%@ New Promise returned"), self.name];
            Promise* promise = (Promise*) newReturn;
            promise.ptype = 2;
            promise.next = self.next;
            // Whatever Promise is waiting for this one (self.next) will
            // be triggered by the new promise when it is resolved.
            // The current Promise does not resolve self.next.
            // The job has been turned over to the new Promise.
            return;
        }
        // It's a result or an error
        if (_debug>1) [QLOG(@"%@ Resolving Next"), self.name];
        [self.next resolve: newReturn];
    });
}

/*******************************************************************
 Create an NSError and use it to resolve this Promise.
 *******************************************************************/
- (void)  reject: (NSInteger) code
     description: (NSString*) desc
{
    if (_debug) [QLOG(@"%@"), self.name];
    [self resolve: [Promise resolvedWith: [Promise getError: code
                                                  description: desc]]];
}

/*******************************************************************
 Attach success and error blocks to an existing promise.
 Create a new Promise that will be fulfilled by these blocks.
 The new Promise is set to run on the same queue as this Promise.
 The user can cahnge that after the new Promise is recieved.
 *******************************************************************/
- (Promise*) then: (id (^)(id        result)) successBlock
             error: (id (^)(NSError*  error))  errorBlock
{
    if (_debug) [QLOG(@"%@"), self.name];
    self.successBlock = successBlock;
    self.errorBlock = errorBlock;
    Promise* p = [[Promise alloc] init];
    p.queue = self.queue;
    p.debug = self.debug;
    p.name = _name;
    p.generation = self.generation + 1;
    self.next = p;
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
@end
