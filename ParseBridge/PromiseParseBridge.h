//
//  PromiseParseBridge.h
//  PT1
//
//  Created by Bob Carlson on 2013-09-13.
//
//

#import "Promise.h"

@interface Promise (Parse)

- (void) parseObject: (id)       result
               error: (NSError*) error;

- (void)  parseError: (NSError*) error;

- (PFArrayResultBlock)   pfArrayResultBlock;
- (PFBooleanResultBlock) pfBooleanResultBlock;
- (PFDataResultBlock)    pfDataResultBlock;
- (PFProgressBlock)      pfProgressBlock;
- (PFUserResultBlock)    pfUserResultBlock;

@end
