//
//  PromiseParseBridge.m
//  PT1
//
//  Created by Bob Carlson on 2013-09-13.
//
//

#import "PromiseParseBridge.h"

@implementation Promise (Parse)

- (void) parseObject: (NSObject*) result
               error: (NSError*)  error
{
    if (error) {
        if (self.debug) QNSLOG(@"%@   Result: %@   error: %@\n%@",
                               self.name, result.description, error.description, self.description);
        [self resolve: error];
    } else {
        if (self.debug) QNSLOG(@"%@   Result: %@", self.name, result.description);
        [self resolve: result];
    }
}

- (void) parseError: (NSError*) error
{
    if (error) {
        if (self.debug) QNSLOG(@"%@    Error: %@\n%@", self.name, error.description, self.description);
        [self resolve: error];
    } else {
        if (self.debug) QNSLOG(@"%@    Succeeded", self.name);
        [self resolve: nil];
    }
}

- (PFBooleanResultBlock) pfBooleanResultBlock
{
    PFBooleanResultBlock block =
    ^(BOOL result, NSError* error){
        if (error) {
            if (self.debug) QNSLOG(@"%@   Result: %d   error: %@\n%@",
                                   self.name, result, error.description, self.description);
            [self resolve: error];
        } else {
            if (self.debug) QNSLOG(@"%@   Result: %d", self.name, result);
            [self resolve: [NSNumber numberWithBool: result]];
        }
    };
    return block;
}

- (PFArrayResultBlock) pfArrayResultBlock
{
    PFArrayResultBlock block =
    ^(NSArray* result, NSError* error){
        if (error) {
            if (self.debug) QNSLOG(@"%@   Result: %@   error: %@\n%@",
                                   self.name, result.description, error.description, self.description);
            [self resolve: error];
        } else {
            if (self.debug) QNSLOG(@"%@   Result: %@", self.name, result.description);
            [self resolve: result];
        }
    };
    return block;
}

- (PFDataResultBlock) pfDataResultBlock
{
    PFDataResultBlock block =
        ^(NSData* result, NSError* error){
            if (error) {
                if (self.debug) QNSLOG(@"%@   Result: %@   error: %@\n%@",
                                       self.name, result.description, error.description, self.description);
                [self resolve: error];
            } else {
                if (self.debug) QNSLOG(@"%@   Result: %@", self.name, result.description);
                [self resolve: result];
            }
        };
    return block;
}

- (PFUserResultBlock) pfUserResultBlock
{
    PFUserResultBlock block =
    ^(PFUser* result, NSError* error){
        if (error) {
            if (self.debug)
                QNSLOG(@"%@   Result: %@   error: %@\n%@",
                       self.name, result.description, error.description, self.description);
            [self resolve: error];
        } else {
            if (self.debug) QNSLOG(@"%@   Result: %@", self.name, result.description);
            [self resolve: result];
        }
    };
    return block;
}

- (PFProgressBlock)   pfProgressBlock
{
    PFProgressBlock block =
    ^(int percentDone){
        //TODO: nothing here
    };
    return block;
}


@end
