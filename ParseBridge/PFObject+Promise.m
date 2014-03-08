//
//  PFObject+Promise.m
//  PT1
//
//  Created by Bob Carlson on 2013-09-12.
//
//

#import "PFObject+Promise.h"

@implementation PFObject (Promise)

/*******************************************************************
 promise_deleteAll
 
 Returns Promise for nil
 *******************************************************************/
+ (Promise*) promise_deleteAll: (NSArray*) objects
{
    Promise* p0 = [Promise promiseWithName: @"PFObject deleteAll"];
    [self deleteAllInBackground: objects
                         target: p0
                       selector: @selector(parseError:)];
    return p0;
} // promise_deleteAll

/*******************************************************************
 promise_fetchAll
 
 Returns Promise for an array of PFObject
 *******************************************************************/
+ (Promise*) promise_fetchAll: (NSArray*) objects
{
    Promise* p0 = [Promise promiseWithName: @"PFObject fetchAll"];
    [self fetchAllInBackground: objects
                        target: p0
                      selector: @selector(parseObject:error:)];
    return p0;
}

/*******************************************************************
 promise_fetchAllIfNeeded
 
 Returns Promise for an array of PFObject
 *******************************************************************/
+ (Promise*) promise_fetchAllIfNeeded: (NSArray*) objects
{
    Promise* p0 = [Promise promiseWithName: @"PFObject fetchAllIfNeeded"];
    [self fetchAllIfNeededInBackground: objects
                                target: p0
                              selector: @selector(parseObject:error:)];
    return p0;
}

+ (Promise*) promise_fetchAllClassesIfNeeded: (NSArray*) objects // Promises an array of PFObject
{
    NSMutableDictionary* objectLists = [self dictify: objects];
    NSMutableDictionary* promiseList = [NSMutableDictionary new];

    for (NSString* pfClass in objectLists) {
        // for each entry create a request with a promise returned
        NSArray* objectListForClass = [objectLists objectForKey: pfClass];
        Promise* p0 = [PFObject promise_fetchAllIfNeeded: objectListForClass];
        [promiseList setObject:p0 forKey: pfClass];
    }
    Promise* p1 = [Promise promiseWithName: @""];
    Promise* p2 = [p1 after: promiseList
                         do: ^id(NSMutableDictionary *results, NSInteger errors)
        {
            return [self undictify: results];
        }];
    return p2;
}


/*******************************************************************
 promise_delete
 
 Returns Promise for a BOOL object
 *******************************************************************/
- (Promise*) promise_delete
{
    Promise* p0 = [Promise promiseWithName: @"PFObject delete"];
    [self deleteInBackgroundWithTarget: p0
                              selector: @selector(parseObject:error:)];
    return p0;
}

/*******************************************************************
 promise_save
 
 Returns Promise for a BOOL object
 *******************************************************************/
- (Promise*) promise_save
{
    Promise* p0 = [Promise promiseWithName: @"PFObject save"];
    [self saveInBackgroundWithTarget: p0
                            selector: @selector(parseObject:error:)];
    return p0;
}

/*******************************************************************
 promise_saveAll
 
 Returns Promise for nil
 *******************************************************************/
+ (Promise*) promise_saveAll: (NSArray*) objects
{
    Promise* p0 = [Promise promiseWithName: @"PFObject saveAll"];
    [self saveAllInBackground: objects
                       target: p0
                     selector: @selector(parseError:)];
    return p0;
}

/*******************************************************************
 promise_refresh
 
 Returns Promise for a PFObject
 *******************************************************************/
- (Promise*) promise_refresh;
{
    Promise* p0 = [Promise promiseWithName: @"PFObject refresh"];
    [self refreshInBackgroundWithTarget: p0
                               selector: @selector(parseObject:error:)];
    return p0;
}

/*******************************************************************
 promise_fetch
 
 Returns Promise for a PFObject
 *******************************************************************/
- (Promise*) promise_fetch
{
    Promise* p0 = [Promise promiseWithName: @"PFObject fetch"];
    [self fetchInBackgroundWithTarget: p0
                               selector: @selector(parseObject:error:)];
    return p0;
}

/*******************************************************************
 promise_fetchIfNeeded
 
 Returns Promise for a PFObject
 *******************************************************************/
- (Promise*) promise_fetchIfNeeded
{
    Promise* p0 = [Promise promiseWithName: @"PFObject fetchIfNeeded"];
    [self fetchIfNeededInBackgroundWithTarget: p0
                                     selector: @selector(parseObject:error:)];
    return p0;
}

+ (NSMutableDictionary*) dictify: (NSArray*) objects
{
    NSMutableDictionary* objectLists = [NSMutableDictionary new];
    for (PFObject* pf in objects) {
        NSArray* pfArray= [objectLists objectForKey: pf.parseClassName];
        if (!pfArray) pfArray = [NSArray array];
        pfArray = [pfArray arrayByAddingObject: pf];
        [objectLists setObject: pfArray
                        forKey:pf.parseClassName];
    }
    return objectLists;
}

+ (NSArray*) undictify: (NSDictionary*) dict
{
    NSArray* returns = [NSArray array];
    for (NSArray* n in [dict allValues]) {
        if ([n isKindOfClass: [NSArray class]])
            returns = [returns arrayByAddingObjectsFromArray: n];
    }
    return returns;
}

+ (NSMutableDictionary*) dictifyByPID: (NSArray*) objects
{
    NSMutableDictionary* objectLists = [NSMutableDictionary new];
    for (PFObject* pf in objects) {
        [objectLists setObject: pf
                        forKey: pf.objectId];
    }
    return objectLists;
}

+ (NSMutableDictionary*) redictifyByPID: (NSDictionary*) dict
{
    return [self dictifyByPID: [self undictify: dict]];
}
@end
