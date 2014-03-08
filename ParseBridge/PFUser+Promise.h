//
//  PFUser+Promise.h
//  PT1
//
//  Created by Bob Carlson on 2013-09-12.
//
//

#import <Parse/Parse.h>
#import "PromiseParseBridge.h"

@interface PFUser (Promise)

/*******************************************************************
 promise_loginWithUserName:password:

 Returns PFUser for success, NSError for any failure.
 *******************************************************************/
+ (Promise*) promise_loginWithUserName: (NSString*) username
                              password: (NSString*) pwd;

/*******************************************************************
 promise_signup

 Returns BOOL indicating success, NSError for failure.
 *******************************************************************/
- (Promise*) promise_signup;

@end
