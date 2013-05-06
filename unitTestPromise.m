//
//  unitTestPromise.m
//  unitTestPromise
//
//  Created by Bob Carlson on 2013-04-22.
//
//

#import "unitTestPromise.h"

#define MAIN 0
#define DEFAULT 1
#define LOW 2
#define HIGH 3

#define NORMAL 0
#define RESOLVEWITH 1
#define RESOLVEWITHERROR 2
#define REJECT 3

@implementation unitTestPromise {
    BOOL allocDealloc;

    BOOL asyncNotComplete;
    BOOL deepDebug;
    BOOL allocDebug;

    int32_t objectCount;
    
    dispatch_queue_t queueM;
    dispatch_queue_t queueD;
    dispatch_queue_t queueL;
    dispatch_queue_t queueH;
}

- (void) asyncComplete
{
    asyncNotComplete = NO;
}

- (void) completeTest
{
    [self performSelectorOnMainThread: @selector(asyncComplete)
                           withObject: nil
                        waitUntilDone: NO];
}

- (void) allocation;
{
    if (allocDebug) QNSLOG(@"");
    objectCount++;
}

- (void) deallocation;
{
    objectCount--;
    if (allocDebug) QNSLOG(@"");
    if (!objectCount) {
        QNSLOG(@"***** Object Count is Zero");
    }
}

- (void) setUp
{
    [super setUp];
    // Set-up code here.
    asyncNotComplete = YES;

    allocDealloc = NO;
    if (allocDealloc) [Promise utDelegate: self];
    
    deepDebug = NO;
    allocDebug = NO;
    objectCount = 0;
    queueM = dispatch_get_main_queue();
    queueD = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    queueL = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    queueH = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);

}

- (void) tearDown
{
    // Tear-down code here.
    [super tearDown];
}

- (void) test01_Single_Promise
// Single Promise, resolved normally
{
    QNSLOG(@"**************** %@", __METHOD);

    __block NSObject* returnedResult;
    __block int blockThatRan;
    
    __block Promise* promise = [self returnResult: @"result"
                                            named: @"test1"];
    [promise then:^id(id result) {
        blockThatRan = 0;
        returnedResult = result;
        [self completeTest];
        return nil;
    } error:^id(NSError* error) {
        blockThatRan = 1;
        returnedResult = error;
        [self completeTest];
        return nil;
    }];
    
    // Run main loop
    while (asyncNotComplete) {
        [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantFuture]];
    }
    
    if (blockThatRan) {
        STFail(@"Test1 returned an error %@", returnedResult.description);
    }

    if (![(NSString*) returnedResult isEqualToString: @"result"]) {
        STFail(@"Test1 did not return the correct result");
    }
    if (objectCount != 0) {
        STFail(@"Test1: Objects not deallocated: %d", objectCount);
    }
    
}

- (void) test02_ResolveWithError
// Single Promise, resolved with an Error
{
    QNSLOG(@"**************** %@", __METHOD);
    
    __block NSObject* returnedResult;
    __block int blockThatRan;
    
    NSError* error = [Promise getError: 101
                     description: @"error desc"];
    
    Promise* promise = [self returnResult: error
                                    named: @"test2"];
    [promise then:^id(id result) {
        blockThatRan = 0;
        returnedResult = result;
        [self completeTest];
        return nil;
    } error:^id(NSError* error) {
        blockThatRan = 1;
        returnedResult = error;
        [self completeTest];
        return nil;
    }];
    
    
    // Run main loop
    while (asyncNotComplete) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    if (blockThatRan == 0) {
        STFail(@"Test1 did not run the error block %@", returnedResult.description);
    }
    
    if ([(NSError*) returnedResult code] != 101) {
        STFail(@"Test1 did not return the correct code - %d", [(NSError*) returnedResult code]);
    }
}

- (void) test03_StringOfPromises
// String of Promises
{
    QNSLOG(@"**************** %@", __METHOD);
    
    __block NSObject* returnedResult;
    __block int blockThatRan;
    
    Promise* promise = [self stringOf3Promises];

    [promise then:^id(id result) {
        blockThatRan = 0;
        returnedResult = result;
        [self completeTest];
        return nil;
    } error:^id(NSError* error) {
        blockThatRan = 1;
        returnedResult = error;
        [self completeTest];
        return nil;
    }];
    
    
    // Run main loop
    while (asyncNotComplete) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    if (blockThatRan) {
        STFail(@"Test3 returned an error %@", returnedResult.description);
    }
    
    if (![(NSString*) returnedResult isEqualToString: @"result12"]) {
        STFail(@"Test3 did not return the correct result");
    }
}

- (void) test04_PropagateErrorThroughString
// String of Promises, propagating an error result
{
    QNSLOG(@"**************** %@", __METHOD);
    
    __block NSObject* returnedResult;
    __block int blockThatRan;
    
    NSError* error = [Promise getError: 101
                           description: @"error desc"];
    
    Promise* promise0 = [self returnResult: error
                                     named: @"test4A"];
    
    Promise* promise1 = [promise0 then:^id(id result) {
        NSString* newResult = [(NSString*) result stringByAppendingString: @"1"];
        return [self returnResult: newResult
                            named: @"test4B"];
    }];
    Promise* promise2 = [promise1 then:^id(id result) {
        NSString* newResult = [(NSString*) result stringByAppendingString: @"2"];
        return [self returnResult: newResult
                            named: @"test4C"];
    }];
    
    [promise2 then:^id(id result) {
        blockThatRan = 0;
        returnedResult = result;
        [self completeTest];
        return nil;
    } error:^id(NSError* error) {
        blockThatRan = 1;
        returnedResult = error;
        [self completeTest];
        return nil;
    }];
    
    
    // Run main loop
    while (asyncNotComplete) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    if (blockThatRan == 0) {
        STFail(@"Test4 did not run the error block %@", returnedResult.description);
    }
    
    if ([(NSError*) returnedResult code] != 101) {
        STFail(@"Test4 did not return the correct code - %d", [(NSError*) returnedResult code]);
    }
}

- (void) test05_DeepNesting
// Deep nesting of Promises
{
    QNSLOG(@"**************** %@", __METHOD);
    
    __block NSObject* returnedResult;
    __block int blockThatRan;
    
    Promise* promise0 = [self goDeep: 4
                              result: @"result"
                               named: @"TestDeep"];
    
    Promise* promise1 = [promise0 then:^id(id result) {
        NSString* newResult = [(NSString*) result stringByAppendingString: @"A"];
        return [self returnResult: newResult
                            named: @"test5B"];
    }];
    Promise* promise2 = [promise1 then:^id(id result) {
        NSString* newResult = [(NSString*) result stringByAppendingString: @"B"];
        return [self returnResult: newResult
                            named: @"test5C"];
    }];
    
    [promise2 then:^id(id result) {
        blockThatRan = 0;
        returnedResult = result;
        [self completeTest];
        return nil;
    } error:^id(NSError* error) {
        blockThatRan = 1;
        returnedResult = error;
        [self completeTest];
        return nil;
    }];
    
    // Run main loop
    while (asyncNotComplete) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    if (blockThatRan) {
        STFail(@"Test5 returned an error %@", returnedResult.description);
    }
    
    if (![(NSString*) returnedResult isEqualToString: @"result01234AB"]) {
        STFail(@"Test5 did not return the correct result");
    }
}

- (void) test06_PropagateErrorThroughNest
// Deep nest of Promises, propagating an error result
{
    QNSLOG(@"**************** %@", __METHOD);
    
    __block NSObject* returnedResult;
    __block int blockThatRan;
    
    NSError* error = [Promise getError: 6
                           description: @"error desc"];
    Promise* promise0 = [self goDeep: 4
                              result: error
                               named: @"TestDeep"];
    
    Promise* promise1 = [promise0 then:^id(id result) {
        NSString* newResult = [(NSString*) result stringByAppendingString: @"1"];
        return [self returnResult: newResult
                            named: @"test6B"];
    }];
    Promise* promise2 = [promise1 then:^id(id result) {
        NSString* newResult = [(NSString*) result stringByAppendingString: @"2"];
        return [self returnResult: newResult
                            named: @"test6C"];
    }];
    
    [promise2 then:^id(id result) {
        blockThatRan = 0;
        returnedResult = result;
        [self completeTest];
        return nil;
    } error:^id(NSError* error) {
        blockThatRan = 1;
        returnedResult = error;
        [self completeTest];
        return nil;
    }];
    
    
    // Run main loop
    while (asyncNotComplete) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    if (blockThatRan == 0) {
        STFail(@"Test6 did not run the error block %@", returnedResult.description);
    }
    
    if ([(NSError*) returnedResult code] != 6) {
        STFail(@"Test6 did not return the correct code - %d", [(NSError*) returnedResult code]);
    }
}

- (void) test07_ResolvedWtih
// Test use of resolvedWith
{
    QNSLOG(@"**************** %@", __METHOD);
    
    __block NSObject* returnedResult;
    __block int blockThatRan;
    
    Promise* promise0 = [self goDeep: 2
                              result: @"result"
                               named: @"TestDeep"
                          resolution: RESOLVEWITH];
    
    Promise* promise1 = [promise0 then:^id(id result) {
        NSString* newResult = [(NSString*) result stringByAppendingString: @"A"];
        return [self returnResult: newResult
                            named: @"test6B"];
    }];
    [promise1 then:^id(id result) {
        blockThatRan = 0;
        returnedResult = result;
        [self completeTest];
        return nil;
    } error:^id(NSError* error) {
        blockThatRan = 1;
        returnedResult = error;
        [self completeTest];
        return nil;
    }];
    
    // Run main loop
    while (asyncNotComplete) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    if (blockThatRan) {
        STFail(@"Test7 returned an error %@", returnedResult.description);
    }
    
    if (![(NSString*) returnedResult isEqualToString: @"result012A"]) {
        STFail(@"Test7 did not return the correct result - %@", returnedResult.description);
    }
}

- (void) test08_After
// Wait for a set of Promises
{
    QNSLOG(@"**************** %@", __METHOD);
    
    __block NSObject* returnedResult;
    __block int blockThatRan;
    
    Promise* promiseA = [self returnResult: @"resultA"
                                     named: @"test8A"];
    
    Promise* promiseB = [self returnResult: @"resultB"
                                     named: @"test8B"];
    
    Promise* promiseC = [self returnResult: nil
                                     named: @"test8C"];
    
    Promise* promiseD = [self returnResult: [Promise getError: 9 description: @"Error 9"]
                                     named: @"test8D"];
    
    NSArray* arrayP = [NSArray arrayWithObjects: promiseA, promiseB, promiseC, promiseD, nil];
    Promise* promise0 = [Promise promiseWithName: @"After"];
    Promise* promise1 = [promise0 after: arrayP
                                     do:^id(NSMutableDictionary *results) {
                                         // Check results
                                         id rA = [results objectForKey: @(1)];
                                         id rB = [results objectForKey: @(2)];
                                         id rC = [results objectForKey: @(3)];
                                         id rD = [results objectForKey: @(4)];
                                         id newReturn = [NSNumber numberWithBool: YES];
                                         if (![rA isEqualToString: @"resultA"]) {
                                             QNSLOG(@"Failed A");
                                             newReturn = [NSNumber numberWithBool: NO];
                                         }
                                         if (![rB isEqualToString: @"resultB"]) {
                                             QNSLOG(@"Failed B");
                                             newReturn = [NSNumber numberWithBool: NO];
                                         }
                                         if ([rC class] != [NSNull class]) { // Should be nil
                                             QNSLOG(@"Failed C");
                                             newReturn = [NSNumber numberWithBool: NO];
                                         }
                                         if (![rD isKindOfClass: [NSError class]]) { // Should be an NSError
                                             QNSLOG(@"Failed D");
                                             newReturn = [NSNumber numberWithBool: NO];
                                         }
                                         return newReturn;
                                     }];
    
    [promise1 then:^id(id result) {
        blockThatRan = 0;
        returnedResult = result;
        [self completeTest];
        return nil;
    } error:^id(NSError* error) {
        blockThatRan = 1;
        returnedResult = error;
        [self completeTest];
        return nil;
    }];
    
    
    // Run main loop
    while (asyncNotComplete) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    if (blockThatRan) {
        STFail(@"Test8 returned an error %@", returnedResult.description);
    }
    
    if (![returnedResult isKindOfClass: [NSNumber class]]) {
        STFail(@"Test8 did not return a BOOL NSNumber");
    }
    
    if (![(NSNumber*) returnedResult isEqualToNumber: [NSNumber numberWithBool: YES]]) {
        STFail(@"Test8 returned NO");
    }
} // test8_ResolvedWithError

- (void) test09_ResolvedWithError
// Test use of resolvedWithError
{
    QNSLOG(@"**************** %@", __METHOD);
    
    __block NSObject* returnedResult;
    __block int blockThatRan;
    
    Promise* promise0 = [self goDeep: 2
                              result: @"result"
                               named: @"TestDeep"
                          resolution: RESOLVEWITHERROR];
    
    Promise* promise1 = [promise0 then:^id(id result) {
        NSString* newResult = [(NSString*) result stringByAppendingString: @"A"];
        return [self returnResult: newResult
                            named: @"test9B"];
    }];
    [promise1 then:^id(id result) {
        blockThatRan = 0;
        returnedResult = result;
        [self completeTest];
        return nil;
    } error:^id(NSError* error) {
        blockThatRan = 1;
        returnedResult = error;
        [self completeTest];
        return nil;
    }];
    
    // Run main loop
    while (asyncNotComplete) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    if (blockThatRan == 0) {
        STFail(@"Test9 did not run the error block %@", returnedResult.description);
    }
    
    if ([(NSError*) returnedResult code] != 101) {
        STFail(@"Test9 did not return the correct code - %@", returnedResult.description);
    }
} // test 9


- (void) test10_CancelString
// Cancel a set of Promises
{
    QNSLOG(@"**************** %@", __METHOD);
    
    __block int blocksRan = 0;
    __block BOOL cancelBlockRan;
    __block BOOL errorBlockRan = NO;
    
    Promise* promiseA0 = [self stringOf3Promises];
    [promiseA0 cancel:^{
        cancelBlockRan = YES;
    }];
    promiseA0.name = @"PromiseA";
    
    Promise* promiseA1 = [promiseA0 then:^id(id result) {
        ++blocksRan; // Should not run after cancel
        return [self returnResult: @"result1"
                            after: 30
                            named: @"test10A1"];
    }];
    
    [promiseA1 then:^id(id result) {
        [self completeTest];
        return nil;
    } error:^id(NSError* error) {
        if (error.code == 9999) {
            // Expected
            errorBlockRan = YES;
        } else {
            ++blocksRan;
        }
        [self completeTest];
        return nil;
    }];
    [promiseA0 cancel];
    
    // Run main loop
    while (asyncNotComplete) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    if (blocksRan) {
        STFail(@"Test10 %d blocks ran despite being cancelled", blocksRan);
    }
    if (!cancelBlockRan) {
        STFail(@"Test10 Cancel block did not run");
    }
    if (!errorBlockRan) {
        STFail(@"Test10 Error block did not run");
    }
} // test10

- (void) test11_CancelAfter
// Cancel a set of Promises including an After
{
    QNSLOG(@"**************** %@", __METHOD);
    
    __block int blocksRan = 0;
    __block BOOL cancelBlockRan;
    
    Promise* promiseA0 = [self stringOf3Promises];
    [promiseA0 cancel:^{
        cancelBlockRan = YES;
    }];
    
    Promise* promiseA1 = [promiseA0 then:^id(id result) {
        ++blocksRan;
        return [self returnResult: @"resultA1"
                            after: 30
                            named: @"test11A1"];
    }];
    
    Promise* promiseB = [self returnResult: @"resultB"
                                     after: 30
                                     named: @"test11B"];
    
    Promise* promiseC = [self returnResult: nil
                                     after: 30
                                     named: @"test11C"];
    
    Promise* promiseD = [self returnResult: [Promise getError: 9 description: @"Error 9"]
                                     after: 30
                                     named: @"test11D"];
    
    NSArray* arrayP = [NSArray arrayWithObjects: promiseA1, promiseB, promiseC, promiseD, nil];
    
    Promise* promise0 = [Promise promiseWithName: @"After"];
    Promise* promise1 = [promise0 after: arrayP
                                     do:^id(NSMutableDictionary *results) {
                                         ++blocksRan;
                                         return nil;
                                     }];
    [promise1 then:^id(id result) {
        ++blocksRan;
        [self completeTest];
        return nil;
    } error:^id(NSError* error) {
        ++blocksRan;
        return nil;
    }];
    
    // Wait .5 s to make sure cancelled blocks have not run
    Promise* wait = [self returnResult: @"result"
                                 after: 500
                                 named: @"wait"];
    [wait then:^id(id result) {
        [self completeTest];
        return nil;
    } error:^id(NSError* error) {
        ++blocksRan; // Error is not expected
        [self completeTest];
        return nil;
    }];
    
    // Cancel it all
    [promise1 cancel];
    
    // Run main loop
    while (asyncNotComplete) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    if (blocksRan) {
        STFail(@"Test11 %d blocks ran despite being cancelled", blocksRan);
    }
    
    if (!cancelBlockRan) {
        STFail(@"Test11 Cancel block did not run");
    }
    
} // test11

// Test use of reject:description
// Test use of return to main queue
// Test willRunOnMainQueue

- (Promise*) stringOf3Promises
// String of Promises
{
    if (deepDebug) QNSLOG(@"");
    
    Promise* promise0 = [self returnResult: @"result"
                                     after: 10
                                     named: @"StringOf3A"];
    
    Promise* promise1 = [promise0 then:^id(id result) {
        NSString* newResult = [(NSString*) result stringByAppendingString: @"1"];
        return [self returnResult: newResult
                            after: 10
                            named: @"StringOf3B"];
    }];
    Promise* promise2 = [promise1 then:^id(id result) {
        NSString* newResult = [(NSString*) result stringByAppendingString: @"2"];
        return [self returnResult: newResult
                            after: 10
                            named: @"StringOf3C"];
    }];
    return promise2;
}

- (Promise*) goDeep: (int)       n
             result: (id)        result
              named: (NSString*) name
{
    return [self goDeep: n
                 result: result
                  named: name
             resolution: NORMAL];
}

- (Promise*) goDeep: (int)       n
             result: (id)        result
              named: (NSString*) name
         resolution: (int)       res
{
    Promise* p;
    NSString* localName = [name stringByAppendingFormat: @"%d", n];
    
    if (deepDebug) QNSLOG(@"%@", localName);
    if (n>0) {
        Promise* p0 = [self goDeep: n-1
                            result: result
                             named: localName
                        resolution: res];
        
        p= [p0 then:^id(id result) {
            NSString* newResult = [(NSString*) result stringByAppendingFormat: @"%d", n];
            if (deepDebug) QNSLOG(@"goDeep Block %d - %@", n, newResult);
            return [self returnResult: newResult
                                after: 5 * n
                                named: [@"return" stringByAppendingFormat: @"%d", n]];
        }];
    } else {
        Promise* p0 = [self returnResult: result
                                   named: localName
                              resolution: res];
        p= [p0 then:^id(id result) {
            NSString* newResult = [(NSString*) result stringByAppendingFormat: @"%d", n];
            if (deepDebug) QNSLOG(@"goDeep Block %d - %@", n, newResult);
            return [self returnResult: newResult
                                after: 5 * n
                                named: [@"return" stringByAppendingFormat: @"%d", n]];
        }];
    }
    if (deepDebug) QNSLOG(@"%@ Exit Promise:\n%@", localName, [p description]);
    return p;
}

- (Promise*) returnResult: (id)        result
                    named: (NSString*) name
{
    return [self returnResult: result
                        after: 5
                        named: name
                            q: DEFAULT
                   resolution: NORMAL];
}

- (Promise*) returnResult: (id)        result
                    named: (NSString*) name
               resolution: (int)       res
{
    return [self returnResult: result
                        after: 5
                        named: name
                            q: DEFAULT
                   resolution: res];
}

- (Promise*) returnResult: (id)        result
                    after: (int64_t)   msecs
                    named: (NSString*) name
{
    return [self returnResult: result
                        after: msecs
                        named: name
                            q: DEFAULT
                   resolution: NORMAL];
}

- (Promise*) returnResult: (id)        result
                    after: (int64_t)   msecs
                    named: (NSString*) name
                        q: (NSInteger) q
               resolution: (int)       res
{
    dispatch_queue_t queue;
    Promise* p = [Promise promiseWithName: name];
    if (q == MAIN) { // Main
        queue = queueM;
    } else if (q == DEFAULT) {
        queue = queueD;
    } else if (q == LOW) {
        queue = queueL;
    } else {
        queue = queueH;
    }

    if (res == RESOLVEWITH) {
        if (deepDebug)
            QNSLOG(@"Resolved with %@", [result description]);
        Promise* p = [Promise resolvedWith: result];
        p.name = @"resolvedWith ";
        return p;
    } else if (res == RESOLVEWITHERROR) {
        if (deepDebug)
            QNSLOG(@"Resolved with Error 101");
        Promise* p = [Promise resolvedWithError: 101 description: @"error dec"];
        p.name = @"resolvedWith Error101";
        return p;
    }

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, msecs * 1000000);
    dispatch_after(popTime, queue, ^(void){
        if (deepDebug) {
            dispatch_queue_t q;
            NSString* qname;
            
            q = dispatch_get_current_queue();
            if (q == queueM) qname = @"MAIN";
            if (q == queueD) qname = @"DEFAULT";
            if (q == queueL) qname = @"LOW";
            if (q == queueH) qname = @"HIGH";
            QNSLOG(@"ReturnResult Block %@ %d Q: %@ - %@", name, res, qname, [result description]);
        } /* else {
            QNSLOG(@"ReturnResult Block %@ - %@", name, [result description]);
        } */
        if (res == NORMAL) {
            [p resolve: result];
        } else { // REJECT
            [p reject: 102 description: @"error desc"];
        }
    });
    return p;
}

@end
