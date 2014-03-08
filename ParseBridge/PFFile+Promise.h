//
//  PFFile+Promise.h
//  PT1
//
//  Created by Bob Carlson on 2013-10-23.
//
//

#import <Parse/Parse.h>

@interface PFFile (Promise)

/*******************************************************************
 promise_getData
 
 Returns a promise for a BOOL that indicates success/failure
 *******************************************************************/
- (Promise*) promise_getData; // Promises a BOOL, success/failure

/*******************************************************************
 promise_save

 Returns a promise for a BOOL that indicates success/failure
 *******************************************************************/
- (Promise*) promise_save; // Promises a BOOL, success/failure

/*******************************************************************
 originalName
 
 Returns the original name of the file before Parse pre-pended a 
 unique value. Marker must have been used as the prefix to the file
 name when it was originally saved.
 *******************************************************************/
- (NSString*) originalName: (NSString*) marker;

@end
