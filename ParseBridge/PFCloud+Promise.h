//
//  PFCloud+Promise.h
//  PT1
//
//  Created by Bob Carlson on 2014-02-07.
//
//

#import <Parse/Parse.h>
#import "PromiseParseBridge.h"

@interface PFCloud (Promise)

+ (Promise*) promise_callFunction: (NSString*)     function
                   withParameters: (NSDictionary*) parameters;

@end
