//
//  unitTestPromise.m
//  unitTestPromise
//
//  Created by Bob Carlson on 2013-04-22.
//
//

#import "unitTestPromise.h"
#import <XCTest/XCTest.h>

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
    if (allocDebug) NSLog(@"");
    objectCount++;
}

- (void) deallocation;
{
    objectCount--;
    if (allocDebug) NSLog(@"");
    if (!objectCount) {
        NSLog(@"***** Object Count is Zero");
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
    queueL = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    queueD = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
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
    NSLog(@"**************** %@", __METHOD);

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
        XCTFail(@"Test1 returned an error %@", returnedResult.description);
    }

    if (![(NSString*) returnedResult isEqualToString: @"result"]) {
        XCTFail(@"Test1 did not return the correct result");
    }
    if (objectCount != 0) {
        XCTFail(@"Test1: Objects not deallocated: %d", objectCount);
    }
    
}

- (void) test02_ResolveWithError
// Single Promise, resolved with an Error
{
    NSLog(@"**************** %@", __METHOD);
    
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
        XCTFail(@"Test1 did not run the error block %@", returnedResult.description);
    }
    
    if ([(NSError*) returnedResult code] != 101) {
        XCTFail(@"Test1 did not return the correct code - %d", [(NSError*) returnedResult code]);
    }
}

- (void) test03_StringOfPromises
// String of Promises
{
    NSLog(@"**************** %@", __METHOD);

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
        XCTFail(@"Test3 returned an error %@", returnedResult.description);
    }

    if (![(NSString*) returnedResult isEqualToString: @"result12"]) {
        XCTFail(@"Test3 did not return the correct result");
    }
}

- (void) test03a_Queues
// String of Promises
{
    NSLog(@"**************** %@", __METHOD);
    
    __block NSObject* returnedResult;

    Promise* promise0 = [self returnResult: @"result"
                                     after: 10
                                     named: @"3A-0"];
    // Default Priorty

    Promise* promise1 =
    [promise0 then:^id(id result) {
        NSLog(@"Expected Queue: Default, Actual: %@", [Promise queueName]);
        NSString* newResult = [(NSString*) result stringByAppendingString: @"1"];
        return [self returnResult: newResult
                            after: 10
                            named: @"3A-1"];
    }];

    [promise1 runHighPriority];
    Promise* promise2 =
    [promise1 then:^id(id result) {
        NSLog(@"Expected Queue: High, Actual: %@", [Promise queueName]);
        NSString* newResult = [(NSString*) result stringByAppendingString: @"2"];
        return [self returnResult: newResult
                            after: 10
                            named: @"3A-2"];
    }];

    [promise2 runLowPriority];
    Promise* promise3 =
    [promise2 then:^id(id result) {
        NSLog(@"Expected Queue: Low, Actual: %@", [Promise queueName]);
        NSString* newResult = [(NSString*) result stringByAppendingString: @"3"];
        return [self returnResult: newResult
                            after: 10
                            named: @"3A-3"];
    }];

    Promise* promise4 =
    [promise3 thenMainQ: ^id(id result) {
        NSLog(@"Expected Queue: Main, Actual: %@", [Promise queueName]);
        returnedResult = result;
        [self completeTest];
        return nil;
    } error:^id(NSError* error) {
        returnedResult = error;
        [self completeTest];
        return nil;
    }];
    
    
    // Run main loop
    while (asyncNotComplete) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    if (![(NSString*) returnedResult isEqualToString: @"result123"]) {
        XCTFail(@"Test03a did not return the correct result");
    }
}

- (void) test04_PropagateErrorThroughString
// String of Promises, propagating an error result
{
    NSLog(@"**************** %@", __METHOD);
    
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
        XCTFail(@"Test4 did not run the error block %@", returnedResult.description);
    }
    
    if ([(NSError*) returnedResult code] != 101) {
        XCTFail(@"Test4 did not return the correct code - %d", [(NSError*) returnedResult code]);
    }
}

- (void) test05_DeepNesting
// Deep nesting of Promises
{
    NSLog(@"**************** %@", __METHOD);
    
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
        XCTFail(@"Test5 returned an error %@", returnedResult.description);
    }
    
    if (![(NSString*) returnedResult isEqualToString: @"result01234AB"]) {
        XCTFail(@"Test5 did not return the correct result");
    }
}

- (void) test06_PropagateErrorThroughNest
// Deep nest of Promises, propagating an error result
{
    NSLog(@"**************** %@", __METHOD);
    
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
        XCTFail(@"Test6 did not run the error block %@", returnedResult.description);
    }
    
    if ([(NSError*) returnedResult code] != 6) {
        XCTFail(@"Test6 did not return the correct code - %d", [(NSError*) returnedResult code]);
    }
}

- (void) test07_ResolvedWtih
// Test use of resolvedWith
{
    NSLog(@"**************** %@", __METHOD);
    
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
        XCTFail(@"Test7 returned an error %@", returnedResult.description);
    }
    
    if (![(NSString*) returnedResult isEqualToString: @"result012A"]) {
        XCTFail(@"Test7 did not return the correct result - %@", returnedResult.description);
    }
}

- (void) test08_After
// Wait for a set of Promises
{
    NSLog(@"**************** %@", __METHOD);
    
    __block NSObject* returnedResult;
    __block int blockThatRan;
    
    NSMutableDictionary* dictP = [NSMutableDictionary new];
    dictP[@"A"] = [self returnResult: @"resultA"
                               named: @"test8A"];
    
    dictP[@"B"] = [self returnResult: @"resultB"
                               named: @"test8B"];
    
    dictP[@"C"] = [self returnResult: nil
                               named: @"test8C"];
    
    dictP[@"D"] = [self returnResult: [Promise getError: 9 description: @"Error 9"]
                               named: @"test8D"];

    Promise* promise0 = [Promise promiseWithName: @"After"];
    Promise* promise1 = [promise0 after: dictP
                                     do:^id(NSMutableDictionary *results, NSInteger errors) {
                                         // Check results
                                         id rA = [results objectForKey: @"A"];
                                         id rB = [results objectForKey: @"B"];
                                         id rC = [results objectForKey: @"C"];
                                         id rD = [results objectForKey: @"D"];
                                         id newReturn = [NSNumber numberWithBool: YES];
                                         if (errors != 1) {
                                             NSLog(@"Error count is %d, should be 1");
                                         }
                                         if (![rA isEqualToString: @"resultA"]) {
                                             NSLog(@"Failed A");
                                             newReturn = [NSNumber numberWithBool: NO];
                                         }
                                         if (![rB isEqualToString: @"resultB"]) {
                                             NSLog(@"Failed B");
                                             newReturn = [NSNumber numberWithBool: NO];
                                         }
                                         if ([rC class] != [NSNull class]) { // Should be nil
                                             NSLog(@"Failed C");
                                             newReturn = [NSNumber numberWithBool: NO];
                                         }
                                         if (![rD isKindOfClass: [NSError class]]) { // Should be an NSError
                                             NSLog(@"Failed D");
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
        XCTFail(@"Test8 returned an error %@", returnedResult.description);
    }
    
    if (![returnedResult isKindOfClass: [NSNumber class]]) {
        XCTFail(@"Test8 did not return a BOOL NSNumber");
    }
    
    if (![(NSNumber*) returnedResult isEqualToNumber: [NSNumber numberWithBool: YES]]) {
        XCTFail(@"Test8 returned NO");
    }
} // test8_ResolvedWithError

- (void) test09_ResolvedWithError
// Test use of resolvedWithError
{
    NSLog(@"**************** %@", __METHOD);
    
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
        XCTFail(@"Test9 did not run the error block %@", returnedResult.description);
    }
    
    if ([(NSError*) returnedResult code] != 101) {
        XCTFail(@"Test9 did not return the correct code - %@", returnedResult.description);
    }
} // test 9


- (void) test10_CancelString
// Cancel a set of Promises
{
    NSLog(@"**************** %@", __METHOD);
    
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
        XCTFail(@"Test10 %d blocks ran despite being cancelled", blocksRan);
    }
    if (!cancelBlockRan) {
        XCTFail(@"Test10 Cancel block did not run");
    }
    if (!errorBlockRan) {
        XCTFail(@"Test10 Error block did not run");
    }
} // test10

- (void) test11_CancelAfter
// Cancel a set of Promises including an After
{
    NSLog(@"**************** %@", __METHOD);
    
    __block int blocksRan = 0;
    __block BOOL cancelBlockRan;
    
    Promise* promiseA0 = [self stringOf3Promises];
    [promiseA0 cancel:^{
        cancelBlockRan = YES;
    }];

    NSMutableDictionary* dictP = [NSMutableDictionary new];
    dictP[@"A1"] = [promiseA0 then:^id(id result) {
                                        ++blocksRan;
                                        return [self returnResult: @"resultA1"
                                                            after: 30
                                                            named: @"test11A1"];
                                    }];

    dictP[@"B"] = [self returnResult: @"resultB"
                               after: 30
                               named: @"test11B"];
    
    dictP[@"C"] = [self returnResult: nil
                               after: 30
                               named: @"test11C"];
    
    dictP[@"D"] = [self returnResult: [Promise getError: 9 description: @"Error 9"]
                               after: 30
                               named: @"test11D"];

    Promise* promise0 = [Promise promiseWithName: @"After"];
    Promise* promise1 = [promise0 after: dictP
                                     do:^id(NSMutableDictionary *results, NSInteger errors) {
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
        XCTFail(@"Test11 %d blocks ran despite being cancelled", blocksRan);
    }
    
    if (!cancelBlockRan) {
        XCTFail(@"Test11 Cancel block did not run");
    }
    
} // test11

// Test use of reject:description
// Test use of return to main queue
// Test willRunOnMainQueue

- (Promise*) stringOf3Promises
// String of Promises
{
    if (deepDebug) NSLog(@"");
    
    Promise* promise0 = [self returnResult: @"result"
                                     after: 10
                                     named: @"StringOf3A"];
    
    Promise* promise1 =
    [promise0 then:^id(id result) {
        NSString* newResult = [(NSString*) result stringByAppendingString: @"1"];
        return [self returnResult: newResult
                            after: 10
                            named: @"StringOf3B"];
    }];

    Promise* promise2 =
    [promise1 then:^id(id result) {
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
    
    if (deepDebug) NSLog(@"%@", localName);
    if (n>0) {
        Promise* p0 = [self goDeep: n-1
                            result: result
                             named: localName
                        resolution: res];
        
        p= [p0 then:^id(id result) {
            NSString* newResult = [(NSString*) result stringByAppendingFormat: @"%d", n];
            if (deepDebug) NSLog(@"goDeep Block %d - %@", n, newResult);
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
            if (deepDebug) NSLog(@"goDeep Block %d - %@", n, newResult);
            return [self returnResult: newResult
                                after: 5 * n
                                named: [@"return" stringByAppendingFormat: @"%d", n]];
        }];
    }
    if (deepDebug) NSLog(@"%@ Exit Promise:\n%@", localName, [p description]);
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
    //NSLog(@"q: %d   Q: %@",q, [Promise queueName: queue]);

    if (res == RESOLVEWITH) {
        if (deepDebug)
            NSLog(@"Resolved with %@", [result description]);
        Promise* p = [Promise resolvedWith: result];
        p.name = @"resolvedWith ";
        return p;
    } else if (res == RESOLVEWITHERROR) {
        if (deepDebug)
            NSLog(@"Resolved with Error 101");
        Promise* p = [Promise resolvedWithError: 101 description: @"error dec"];
        p.name = @"resolvedWith Error101";
        return p;
    }

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, msecs * 1000000);
    dispatch_after(popTime, queue, ^(void){
        if (deepDebug) {
            NSLog(@"ReturnResult Block %@ %d Q: %@ - %@", name, res, [Promise queueName: queue], [result description]);
        } /* else {
            NSLog(@"ReturnResult Block %@ - %@", name, [result description]);
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
