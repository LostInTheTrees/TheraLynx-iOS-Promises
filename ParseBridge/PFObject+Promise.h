//
//  PFObject+Promise.h
//  PT1
//
//  Created by Bob Carlson on 2013-09-12.
//
//

#import <Parse/Parse.h>
#import "PromiseParseBridge.h"

@interface PFObject (Promise)

+ (Promise*) promise_saveAll:                 (NSArray*) objects;
+ (Promise*) promise_deleteAll:               (NSArray*) objects;

+ (Promise*) promise_fetchAll:                (NSArray*) objects;
+ (Promise*) promise_fetchAllIfNeeded:        (NSArray*) objects;
//           cannot be used with a mixed array
+ (Promise*) promise_fetchAllClassesIfNeeded: (NSArray*) objects;
//           can be used with a mixed array


/*******************************************************************
 Dictionary keyed by parse class name

 dictify takes an array of PFObject and makes a dictionary
 of arrays of PFObject, the keys are PFObject class names
 *******************************************************************/
+ (NSMutableDictionary*)        dictify: (NSArray*)      objects;
+ (NSArray*)                  undictify: (NSDictionary*) dict;

/*******************************************************************
 Dictionary keyed by PID

 dictifyByPID takes an array of PFObject and makes a dictionary
 of PFObject, the keys are PFObject objectIds (PIDs)
 *******************************************************************/
+ (NSMutableDictionary*)   dictifyByPID: (NSArray*)      objects;
// inverse is              [dict allValues];

// redictifyByPID takes a dictionary of PFObject keyed by class
// and changes it into a dictionary keyed by PID
+ (NSMutableDictionary*) redictifyByPID: (NSDictionary*) dict;

/**
 Save/Delete the PFObject in the background.
 Return a promise for nil.
 **/
- (Promise*) promise_save;
- (Promise*) promise_delete;

/**
 Refresh the PFObject in the background.
 Return a promise for the PFObject.
 **/
- (Promise*) promise_refresh;

/**
 Fetch the PFObject in the background.
 Return a promise for the PFObject.
 **/
- (Promise*) promise_fetch;

/**
 Fetch the PFObject in the background if needed.
 Return a promise for the PFObject.
 **/
- (Promise*) promise_fetchIfNeeded;

@end
