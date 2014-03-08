//
//  PFUser+Promise.m
//  PT1
//
//  Created by Bob Carlson on 2013-09-12.
//
//

#import "PFUser+Promise.h"

@implementation PFUser (Promise)

/*******************************************************************
 promise_loginWithUserName:password:

 Returns PFUser for success, NSError for any failure.
 *******************************************************************/
+ (Promise*) promise_loginWithUserName: (NSString*) username
                              password: (NSString*) pwd
{
    Promise* p0 = [Promise promiseWithName: @"PFUser loginWithUserName"];
    [PFUser logInWithUsernameInBackground: username
                                 password: pwd
                                   target: p0
                                 selector: @selector(parseObject:error:)];
    return p0;
}

/*******************************************************************
 promise_signup

 Returns BOOL indicating success, NSError for failure.
 *******************************************************************/
- (Promise*) promise_signup
{
    Promise* p0 = [Promise promiseWithName: @"PFUser signup"];
    [self signUpInBackgroundWithTarget: p0
                              selector: @selector(parseObject:error:)];
    return p0;
}

@end
