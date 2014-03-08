# Promises for iOS
## Bob Carlson, TheraLynx LLC
##### Version 2.0.0

Promises are a method of controlling and understanding asynchrony. They originated in Javascript, but I have created an iOS version. So far, I am finding it to be a much better way to handle this problem. Promises allow for several valuable benefits. The existing methods for handling async tasks in iOS do not make any of these things easy.

* A string of asynchronous tasks can be programmed in a way that looks linear on the page for easy understanding.
* A set of asynchronous tasks can be encapsulated within a single method call that returns one Promise object and thus appears to be a single asynchronous operation.
* Because a whole series of asynchronous tasks can be contained in a set of blocks within one method, they can all share a common context with no cumbersome context passing mechanisms.
* Errors that occur in any part of the asynchronous chain can be caught at any point or automatically passed down the chain.
* Any existing method call that asynchronously executes a block or a target-action method can be easily encapsulated in a method that returns a Promise.

The code can be found [here](https://github.com/LostInTheTrees/TheraLynx-iOS-Promises) on GitHub.  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA. Under this licence you may use this work and redistribute deriviatives of this work as long as you make available any changes and credit the use of the work by attributing the work to "Bob Carlson, TheraLynx LLC". As much as any general altruism on my part, I hope that others will find issues and improve what I have begun. You can reach me at bob (ats1gn) TheraLynx (d0t) com.

I found that the [screencasts by Mike Taulty](http://mtaulty.com/CommunityServer/blogs/mike_taultys_blog/archive/2012/04/11/winjs-promises-1.aspx) on JS Promises to be an excellent introduction, even though the environment and some names are different. However, I will still attempt an introduction here. 

### Promise Basics

A Promise is an object to which the result of an asynchronous task is delivered. Delivering the result is called "resolving" the Promise. Blocks can be attached to the Promise and one of these blocks may be run when the Promise is resolved. The resolution block is usually run in the background, but may run in the foreground or on another queue.

When you attach resolution blocks to a Promise, the blocks constitute a new async task. A new Promise, the Next Promise, is created to receive the result of this task. When the resolution block runs, it returns an object. This object resolves the Next Promise.

The most common resolution blocks are the success and error blocks. If the Promise is resolved with an NSError object, then the error block is run. In all other cases, the success block is run. This includes nil; Promises can be resolved with nil.

If a Promise is resolved by an NSError but there is only a success block, the NSError is used to resolve the Next Promise. This is recursive so an error can propagate all the way to the end of a chain of Promises.

Normally, you can return an NSError, a result object or nil from either the success or error block. However, you can also return a new Promise. This is the most difficult thing to internalize about Promises. When you return an object or nil, it resolves the Next Promise. When you return a new Promise, you are saying the new Promise will resolve the Next Promise.

To put the capability of Promises in more esoteric terms, they enable you to easily construct an arbitrary acyclic directed graph of dependent tasks and blocks that lead to a single block that will be executed when the graph of tasks has been completed.

When "running in the background" is mentioned here, it means "running on any queue that is not the Main Queue". It should not be confused with running on the Background global queue which is the lowest priority global queue. In almost all cases, Promises will be used to execute tasks and blocks in the background so as to free up the Main Queue. Much of the time the final resolution block run will be on the Main Queue so that the UI can be updated.

### Making an Asynchronous Call with a Promise

The basic operation of Promises is to allow an asynchronous operation to execute and then run a block when the operation is complete. The simplest call look slike this in code.

    - (void) aMethod: (id) arg
	{  
    	Promise* p0 = [SomeClass getAnObjectFromTheWeb: arg]; // (1)  
	    [p0 then:^id(id result) { // (2)
	        TObject *typedObj = (TObject*) result; // (4)
	        // Use the object
	        return nil; // (6)
	    } error:^id(NSError error) {  
	        // Log the error   (5)
	        return nil; // (6)
	    }];  
	    return; // (3)
	}
1.	Start an asynchronous operation and get a Promise for the result.
2.	Attach blocks that will run when the Promise is resolved with a result.
3.	After attaching the blocks, return. The operation is still running and the blocks are waiting to be run.
4.	If the Promise is resolved successfully (with anything except an NSError) this block will run.
5.	If the Promise is resolved with an NSError, this block will be run.
6.	Assuming no other pointers to p0 have been saved, when the block exits, the Promise will be deallocated 
along with the blocks and any other data kept around for the blocks.



### Encapsulating an Asynchronous Call as a Promise

This code shows how any method that executes a block asynchronously can be turned into a “Promise”. It also shouws how Promises are resolved. PFObject and PFQuery are from the parse.com SDK. GetObjectInBackgroundWithId has no knowledge of  Promises, but it can now be called by any code that uses Promises. A similar method can be used with target-action.

    - (Promise*) getPO: (NSString*) objectID ofClass: (NSString*) class
	// Returns a Promise for an id of type class  
	{  
    	Promise* p0 = [Promise alloc] init]; // (1)  
    	P0.name = @"getPO"]; // (2)  
    	PFQuery *query = [PFQuery queryWithClassName: class];  
    	[query getObjectInBackgroundWithId: objectID  // (3)  
    	block: ^(PFObject *object, NSError *error) { // (5)  
        	if (object) {    
            	[p0 resolve: object]; // (6)  
        	} else if (error) {  
            	[p0 resolve: error]; // (7)  
        	} else {  
            	[p0 resolve: [Promise getError: ERR_FETCHFAILED  
                	               description: ERRM_FETCHFAILED]]; // (8)  
        	}  
    	}];  
    	return p0; // (4)  
	}

1.	A Promise object is created.
2.	Assign a name for debugging purposes. [Promise initWithName: @”name”] can do these in one step.
3.	Start an async task that runs a block upon completion.
4.	Return the Promise to the caller. The block has not run yet.
5.	When the query completes, the block runs.
6.	If an object is returned, this resolves the Promise with the object returned by the query.
7.	If an NSError object is returned, this resolves the Promise with the same error. The Error block (if any) of the Promise will be run.
8.	If both object and error are nil, this creates an NSError object and resolves the Promise with it. The Error block (if any) of the Promise will be run. [Promise getError:…] is a convenience method for creating a simple NSError object.

### Sequences of Asynchronous Tasks

The following code shows how a Promise returning function can be called and how multiple async operations can be done in sequence.

	- (Promise*) getThing3: (NSString*) objID1  
	// Promise is satisfied with an object of class Thing3  
	{  
	    Promise* p0 = [self getPO: objID1 // (1)  
	                      ofClass: @”Thing1”];  
	    Promise* p1 = [p0 then:^id(id result) { // (2)  
	        Thing1 *obj1 = (Thing1*) result; // (5)  
	        // Do stuff with typed obj1
	        return [self getSecondThingIWant: infoFromThing1]; // (6)  
	    }];  
	    Promise* p2 = [p1 then:^id(id result) { // (3)  
	        Thing2* obj2 = (Thing2*) result; // (7)  
	        // Do stuff with typed obj2  
	        return [self getThirdThingIWant: newInfoFromThing2 ]; // (8)  
	        //getThingIWant returns a Promise for a Thing3 object   
	    }];  
	    return p2; // (4)  
	}

1.	GetPO is executed synchronously and returns a Promise p0. It starts off an asynchronous task. When that task completes, it resolves the Promise p0 with a Thing1 object.
2.	A Success block is attached to Promise p0. Promise p1 is returned. The Promise p1 will be resolved by whatever object is returned by the Success block of p0.
3.	A Success block is attached to Promise p1. Promise p2 is returned. The Promise p2 will be resolved by whatever object is returned by the Success block of p1. Note that there is no error block so any error will propagate to Promise p2.
4.	Promise p2 is returned to the caller. Steps 1-4 have all happened synchronously. None of the blocks have been executed, but are held in the stack along with their scopes until they execute.
5.	When the async task started by getPO completes, it resolves p0 with a result object. Then the p0 Success block is scheduled and executed on the default queue. The result id is cast to a Thing1*. In real code you might use introspection here to verify the class.
6.	getSecondThingIWant is called with an argument obtained from Thing1. It returns a Thing2* object. Promise p1 was waiting for the p0 Success block to return an object. Note that getSecondThingIWant can return either a Thing2 or a Promise for a Thing2. This code does not care.
7.	When the getSecondThingIWant returns, it resolves p1, which finally causes the p1 Success block to be scheduled and run.
8.	GetThirdThingIWant is called with an argument obtained from obj2. It starts an async task and returns a Promise. Promise p2 was waiting for the p1 Success block to return an object. Since it returns a Promise instead, it now waits for  that Promise to be resolved. Ultimately, the Promise p2 will be resolved by whatever object is finally returned by GetThirdThingIWant.

### Queues

When a resolution block is run by a Promise, it is dispatched on a GCD queue. By default, the queue is the global default queue. Using various methods, you can control the queue on which the blocks are run. The runLowPriority, runHighPriority and runLowestPriority methods tell the Promise to use different global queues. The runOnMainQ or thenMainQ: methods direct the Promise to run blocks on the main queue. Lastly, it is also possible to run on a custom queue by assigning the queue to the "queue" property of the Promise.

The code above might be a string of asynchronous tasks that are required to complete a longer task. Code in a ViewController can call it to execute that code in the background. The final blocks though can be run on the main queue so the ViewController can continue its business.

	- (Promise*) doSomethingInForeground: (id) someArgument  
	{  
	    Promise* p0 = [self getThing3: someArgument]; // (1)  
	    [p0 thenMainQ:^id(id result) { // (2)(3)  
	        TObject *typedObj = (TObject*) result; // (4)  
	        // Do stuff here on Main queue, including UI, VCs etc.  
	        return nil; // (5)  
	    } error:^id(NSError error) {  
	        // Log the error  
	        return nil; // (5)  
	    }];
	}

1.	Call getThing3 to start an async task. This is probably in the background, but not necessarily.
2.	Run the blocks for this Promise on the Main queue.
3.	Assign a Success block and an Error block for this task. [p0 then:…] returns a Promise, but this is discarded because these blocks do not start any asynchronous tasks. 
4.	The string of async tasks ends here and rejoins the Main queue.
5.	Nil is returned because these blocks do not promise any results. No blocks are attached to p0 so this ends execution of this string of Promises.

Alternatively you could replace the thenMainQ:error: method with then:error: and add [p0 runOnMainQ] on the previous line.


### Working with Managed Objects

When accessing an NSManagedObject (MO) in the background, you must do so in a thread safe manner. When an NSManagedObjectContext (MOC) is created with the NSPrivateQueueConcurrencyType, then there will be a queue associated with the context. Any access to an MO in that context must be made while running on that queue. Promises accommodate that easily.

	- (Promise*) doSomethingInBackground: (id) someArgument  
	{  
	    Promise* p0 = [self getManagedObject: someArgument 
	                                      in: aBackgroundContext]; // (1)
		[p0 runInContext: aBackgroundContext]; (2)	                                 
	    [p0 then:^id(id result) { // (3)  
	        NSManagedObject *mObj = result; // (4)  
	        // Do stuff here with the managed object
	        return nil; // (5)  
	    } error:^id(NSError error) {  
	        // Log the error  
	        return nil; // (5)  
	    }];
	}

1.	Call getManagedObject:in: to start an async task. This is probably in the background, but not necessarily.  getManagedObject:in: returns a Promise for an MO.
2.	Run the blocks for this Promise on the queue associated with aBackgroundContext. 
3.	Assign a Success block and an Error block for this task. [p0 then:…] returns a Promise, but this is discarded because these blocks do not start any asynchronous tasks. 
4.	When the MO is returned, this block is run on the context's queue. The MO can be freely accessed and modified.
5.	Nil is returned because these blocks do not promise any results.

### Pre-Resolved Promises

It also turns out to be valuable to be able to create a Promise that resolves immediately. Consider getPO again, which encapsulates an asynchronous task. It’s possible that getPO might determine that an async task is not needed. However, it must return a Promise. The answer is to return a Promise that is “already resolved”. As soon as a Success block is assigned to that Promise, the promise is resolved and the Success (or Error) block is scheduled and run.

	- (Promise*) getPO: (NSString*) objectID ofClass: (NSString*) className  
	// Returns a Promise for an id of type class  
	{  
	    if (!className) return [Promise resolvedWith: nil]; // (1)  
	    Promise* p0 = [Promise initWithName: @"getPO"]; // (2)  
	    PFQuery *query = [PFQuery queryWithClassName: class];  
	    [query getObjectInBackgroundWithId: objectID   
	           block: ^(PFObject *object, NSError *error)  
	    {  
	        if (object) {  
	            [p0 resolve: object];  
	        } else if (error) {  
	            [p0 resolve: error];  
	        } else {  
	            [p0 resolve: [Promise getError: ERR_FETCHFAILED  
	                               description: ERRM_FETCHFAILED]];  
	            }  
	        }];  
	    return p0;  
	}

1.	If a nil is passed for className, do not start a query. Return a Promise that is already resolved as “nil”.
2.	Otherwise, create a Promise and proceed with an async task.

You may notice an apparent race condition here. When a promise is "already resolved", it does not have blocks assigned when it is created. As soon as resolution blocks are assigned, One of them is scheduled to run with the result. Thus any modifying methods such as runInContext: must be performed before the block assignment method (then:, then:error:, ...) is called.

### Multiple Parallel Promises

You can wait for several Promises to complete by using the after: method. Start a set of async tasks and then wait for all of them to complete. The Promises are values in a dictionary. The results are returned in a dictionary with the same keys.

	- (Promise*) getListObjects: (NSArray*) listOfStrings
	{
	    NSMutableDictionary* promiseList = [NSMutableDictionary new];
	    for (NSString* key in listOfStrings) {
	        Promise* p = [self getObjectUsingKey: key];
            [promiseList setObject: p forKey: key]; // (1)
	    }
	    if (promiseList.count == 0) { // (2)
	        return [Promise resolvedWith: [NSMutableDictionary new]];
	    }
	    Promise* p0 = [Promise after: promiseList
	                              do: ^id(NSMutableDictionary *results, NSInteger errors) { // (3)
			// All Promises are resolved (5)
			if (errors) {
				// Search the values in the dictionary for NSErrors
				// log them
				// Delete them from the dictionary
			}
	    	return results;
	    }];
	    return p0; // (4)
	}

1.	Add a Promise to the list (dictionary) of Promises. Use the key to identify the particular Promise.
2.	Make sure actually have some Promises to wait for.
3.	The results are returned in a dictionary with the same keys that were used for the Promises, so individual results can be located. There is no separate error block in an aggregate Promise.
4.	Return the Promise p0. It promises a dictionary with no NSError results.
5.	The block is run when all Promises have been resolved. Errors gives an error count. Each result is a value in the dictionary. They could each be nil, an object or and NSError.

### Iteration

Just as in procedural code, you may need to execute a block repeatedly for a varying number of arguments. The iterate: method makes this possible. The iterate: method specifies a special type of resolution block.

	- (void) doSomethingWithAListInBackground: (NSArray*) listOfArguments
	{  
		__block NSMutableArray* list = [listOfArguments mutableCopy]
		Promise* p0 = [Promise promiseResolvedWith: nil]; // (1)
		Promise* p1 = [p0 iterate:^id(id result, NSInteger step) { // (2)  
			if (!step) { // (5)
				// Initialize the iteration if necessary
			}
			if (result) { // (6)
				// Do something with the result of processThisString, if any
			}
			if (!listOfArguments.count) { // (7)
				return nil;
			}
			NSString* someArgument = [list firstObject];
			[list removeObjectAtIndex: 0]; // (8)
	        return [self doSomethingWith: someArgument]; // (9)  
	    }];  
	    [p1 thenMainQ:^id(id result) { // (3)  
	        // Do stuff here on Main queue, including UI, VCs etc.  // (10)
	        return nil; 
	    } error:^id(NSError error) {  
	        // Log the error   (11)
	        return nil; 
	    }];
	    return; (4)
	}

1.	Create a pre-resolved promise. When the iterate block is attached to this, it will be scheduled to run right away.
2.	Attach the iterate block. Promise p1 is returned. It will receive the final result of the iterate block.
3.	Attach blocks to p1 that will receive the final result of the iterate block. Run these blocks back on the main queue.
4.	Exit, the blocks are waiting to run.
5.	Step will increment by one each time the block is run. Step == 0 can be used to trigger initialization.
6.	The first result passed in will be nil. Subsequent results might not be.
7.	This is the "test" part of a normal for loop. In this example, a task must be run for each string in listOfArguments. When the list is empty, nil is returned and the iteration is terminated. "Nil" will resolve p1.
8.	This is essentially the "increment" part of a for loop. Remove the argument being processed.
9.	Process this argument. doSomethingWith returns a Promise for a result. Returning the Promise says "run this block again with the result returned by this new Promise.
10.	If the iteration is completed without an error, this blcok will execute on th emain queue.
11.	An NSError returned anywhere in the iteration (unless caught by another lower down error block) will cause this block to execute.

### Queuing Up Jobs

Promises can also be used to create "jobs" and queue them up for execution.

	- (Promise*) sync: (NSString*) syncGroup
	{
		@synchonized{
		    if (self.syncInProgress) { // (1)
		        // A sync is in progress, queue this up for later
		        Promise* q0 = [Promise promiseWithName: @"queuedSyncRequest"]; // (2)
		        Promise* q1 = [q0 then:^id(id result) { // (3)
		            return [self syncGroup: syncGroup];
		        }];
		        [self.syncQueue addObject: q0]; // Add to the queue (4)
		        return q1; // (5)
		    }
	        self.syncInProgress = YES; // (6)
		}
	    p0 = [self doTheSync: syncGroup]; // (7)
	    Promise* p1 = [p0 thenError: ^id(id result) {
	        self.syncInProgress = NO;  // (8)
	        // Clean up after the sync
	        if ([result isKindOfClass: [NSError class]]) {
	        	// error
	        } else {
	        	// success
	        }
	        
	        if (self.syncQueue.count) { // (9)
	            Promise* q0 = self.syncQueue.firstObject; // (10)
	            [self.syncQueue removeObject: q0]; 
	            [q0 resolve: nil]; // Schedule the next job (11)
	        }
	        return nil;
	    }];
	    return p1;
	}

1.	Check if the sync code is busy.
2.	Create a Promise to be the queue element.
3.	Attach a block that will eventually run this sync job.
4.	Add the Promise to the queue.
5.	Return the Promise for this job.
6.	Mark the sync code busy.
7.	Do the actual sync job, which is asynchronous and returns a Promise for its result.
8.	This block is always executed when doTheSync is resolved, even when there is an error.
9.	Check for waiting jobs.
10.	Get the Promise represting the next job.
11.	Run the next job by resolving the promise. This will execute the block associated with it. This promise was create in (2).

### Executing a block in the background 

You may want to execute a block the background to begin a sequence of asynchronous tasks. Just create a Promise with a Success block and then resolve the Promise when you are ready to kick off the sequence.

	- (Promise*) doSomethingInBackground: (id) someArgument  
	{  
		Promise* p0 = [Promise promiseWithName: @"start in BG"]; // (1)
		Promise* p1 = [p0 then:^id(id result) { // (2)  
	        // Ignore the result (6)
	        // Do stuff here in the BG  
	        return [self getThing3: someArgument]; // (7)  
	    }];  

	    [p1 thenMainQ:^id(id result) { // (3) (4)  
	        TObject *typedObj = (TObject*) result; // (8)  
	        // Do stuff here on Main queue, including UI, VCs etc.  
	        return nil; // (9)
	    } error:^id(NSError error) {  
	        // Log the error  (8)
	        return nil; // (9)
	    }];  
	    [p0 resolve: nil]; // (5)
	}

1.	Create a Promise to hold the initial background block.
2.	Assign the initial background block. P1 is a Promise waiting for the p0 block to resolve it.
3.	Run the p1 block back on the main queue when it runs.
4.	Assign the resolution blocks for p1.
5.	Kick off the p0 block in the background. It will run in the background sometime after we exit doSomethingInBackground.
6. 	This block runs in the background. It does not expect any result object.
7.	The p0 block returns a Promise, so p1 is now waiting for that Promise. When it returns a resolution, the p1 block will be run.
8.	The p1 block now runs in the foreground.
9.	Returns nil. There is no dependent Promise, so the async sequence ends.

### Cancellation

Canceling asynchronous tasks is occasionally necessary, so a cancel method is part of iOS Promises. Promises are not asynchronous tasks in and of themselves. They just receive results from asynchronous service providers and schedule blocks to handle them. Because of this, Promises do not cancel the asynchronous tasks themselves, but the user of a Promise can cancel the asynchronous task. There are three aspects to Promise cancellation.

* When a Promise is cancelled, it is marked as cancelled and its predecessor is also cancelled. This will ripple back to the earliest Promise in the chain. The next and prev pointers and the block pointers of a cancelled Promise are set to nil.
* If a Promise marked as cancelled is "resolved", nothing will happen, it's blocks will not be run.
* A Cancel Block can be attached to a Promise. It will be run (synchronously) if the Promise is cancelled. The cancel block can use this opportunity to cancel the "asynchronous service" that it is waiting for. For example, a running NSUrlConnection could be cancelled.
* If a cancelled Promise has a dependent Promise an error will be used to resolve it. The error will have a code of 9999. 

### Parse.com

I use Promises extensively in iOS with the parse.com iOS SDK. Included in the Promises code is the Promises wrapper for the Parse SDK. All of the Parse SDK async methods are bridged to Promises. Each of the Parse objects has a category like this abbreviated one.

	@implementation PFObject (Promise)
	- (Promise*) promise_save
	{
	    Promise* p0 = [Promise promiseWithName: @"PFObject save"];
	    [self saveInBackgroundWithTarget: p0
	                            selector: @selector(parseObject:error:)];
	    return p0;
	}
	
	+ (Promise*) promise_saveAll: (NSArray*) objects
	{
	    Promise* p0 = [Promise promiseWithName: @"PFObject saveAll"];
	    [self saveAllInBackground: objects
	                       target: p0
	                     selector: @selector(parseError:)];
	    return p0;
	}	
	...
	@end

All of the Parse Promise methods are handled by just two methods used as targets, parseError: and parseObject:error:.

	@implementation Promise (Parse)
	- (void) parseObject: (NSObject*) result
	               error: (NSError*)  error
	{
	    if (error) {
	        [self resolve: error];
	    } else {
	        [self resolve: result];
	    }
	}
	
	- (void) parseError: (NSError*) error
	{
	    if (error) {
	        [self resolve: error];
	    } else {
	        [self resolve: nil];
	    }
	}
	@end
