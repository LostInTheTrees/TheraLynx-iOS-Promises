# Promises for iOS
## Bob Carlson, TheraLynx LLC

Promises are a method of controlling and understanding asynchrony. They originated in Javascript, but I have created an iOS version. So far, I am finding it to be a much better way to handle this problem. Promises allow for several valuable concepts.

* A string of asynchronous tasks can be programmed in a way that looks linear on the page for easy understanding.
* A set of asynchronous tasks can be encapsulated within a single method call that returns one Promise object and thus appears to be a single asynchronous operation.
* Because a whole series of asynchronous tasks can be contained in a set of blocks within one method, they can all share a common context with no cumbersome context passing mechanisms.
* Errors that occur in any part of the asynchronous chain can be caught at any point or automatically passed down the chain.
* Any existing method call that asynchronously executes a block can be easily encapsulated in a method that returns a Promise.

I found that the screencasts by Mike Taulty on JS Promises to be an excellent introduction, even though the environment and some names are different. However, I will still attempt an introduction here. 

A Promise should be thought of as a promise to return a result object (id) or an error object (NSError) to a block at a future time. A Promise object is created to represent the asynchronous result. The asynchronous code delivers the result to the Promise and then the Promise schedules and runs a block to handle the result or error. The basic sequence for using promises is as follows.

- Call some code that starts an asynchronous task. The code returns a Promise object.
- The caller attaches 1 or 2 blocks to the Promise. The blocks are called the “Success block” and the “Error block”.
- When the asynchronous task is complete, the resolve method of the Promise is called. One object is passed to resolve, the resolution object. 
- The resolve method calls the error block if the resolution object is an NSError. Otherwise the Success block is called.
- The Success or Error block is executed on a queue using dispatch_async. The default background queue is used by default, but the main queue or other queues can be substituted.

The above describes the execution of a single Promise. To string together multiple Promises, we add three ideas. 

- The method that attaches the Success and Error blocks returns another Promise, the “Next Promise”. The Next Promise represents a promise for another result object. That object will be returned by the Success or Error block of the first Promise.
- The signature of the Success and Error blocks includes an id as the return. Returning an object is equivalent to calling resolve for the next promise.
- Normally, you can return an NSError or a result object from either the Success or Error block. However, you can also return a new Promise. The new Promise adopts the next Promise as ITS next Promise.

### Encapsulating an Asynchronous Call as a Promise

This code shows how any method that executes a block asynchronously can be turned into a “Promise”. PFObject and PFQuery are from the parse.com SDK. GetObjectInBackgroundWithId has no knowledge of  Promises, but it can now be called by any code that uses Promises. Giving a Promise a name helps with debugging.

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
	        // Do stuff with Thing1 obj1  
	        return [self getThing2: infoFromThing1]; // (6)  
	        //getThing2 returns a Promise for a Thing2 object   
	    }];  
	    Promise* p2 = [p1 then:^id(id result) { // (3)  
	        T2Class *obj2 = (T2Class*) result; // (7)  
	        // Do stuff with typed obj2  
	        return [self getThingIWant: newInfoFromThing2 ]; // (8)  
	        //getThingIWant returns a Promise for a Thing3 object   
	    }];  
	    return p2; // (4)  
	}

1.	GetPO is executed synchronously and returns a Promise p0. It starts off an asynchronous task. When that task completes, it resolves the Promise p0 with a Thing1 object.
2.	A Success block is attached to Promise p0. Promise p1 is returned. The Promise p1 will be resolved by whatever object is returned by the Success block of p0.
3.	A Success block is attached to Promise p1. Promise p2 is returned. The Promise p2 will be resolved by whatever object is returned by the Success block of p1.
4.	Promise p2 is returned to the caller. Steps 1-4 have all happened synchronously. None of the blocks have been executed, but are held in the stack along with their scopes until they execute.
5.	When the async task started by getPO completes, it resolves p0 with a result object. Then the p0 Success block is scheduled and executed on the default queue.
6.	GetThing2 is called with an argument obtained from Thing1. It starts an async task and returns a Promise. Promise p1 was waiting for the p0 Success block to return an object. Since it returns a Promise instead, it now waits for  that Promise to be resolved. 
7.	When the async getThing2 task completes, it resolves its Promise which finally causes the p1 Success block to be scheduled and run.
8.	GetThingIWant is called with an argument obtained from Thing2. It starts an async task and returns a Promise. Promise p2 was waiting for the p1 Success block to return an object. Since it returns a Promise instead, it now waits for  that Promise to be resolved. 
9.	However, the p2 Promise was returned to the calling function. When the getThingIWant async task completes, it will resolve its Promise, which will resolve Promise p2, which will schedule and run the Success block (if any) assigned by the calling function.

### Returning to the Foreground

The code above might be a string of asynchronous tasks that are required to complete a longer task. Code in a ViewController can call it to execute that code in the background. The final blocks though can be run on the main queue so the ViewController can continue its business.

	- (Promise*) doSomethingInForeground: (id) someArgument  
	{  
	    Promise* p0 = [self getThing3: someArgument]; // (1)  
	    [p0 runOnMainQueue]; // (2)  
	    [p0 then:^id(id result) { // (3)  
	        TObject *typedObj = (TObject*) result; // (4)  
	        // Do stuff here on Main queue, including UI, VCs etc.  
	        return nil; // (5)  
	    } error:^id(NSError error) {  
	        // Log the error  
	        return nil; // (5)  
	    }];  
	}

1.	Call getThing3 to start an async task.
2.	Run the blocks for this Promise on the Main queue.
3.	Assign a Success block and an Error block for this task. [p0 then:…] returns a Promise, but this is discarded because these blocks do not start any asynchronous tasks. 
4.	The string of async tasks ends here and rejoins the Main queue.
5.	Nil is returned because these blocks do not promise any results.
 
### Pre-Resolved Promises

It also turns out to be valuable to be able to create a Promise that resolves immediately. Consider getPO again, which encapsulates an asynchronous task. It’s possible that getPO might determine that an async task is not needed. However, it must return a Promise. The answer is to return a Promise that is “already resolved”. As soon as a Success block is assigned to that Promise, the promise is resolved and the Success (or Error) block is scheduled and run.

	- (Promise*) getPO: (NSString*) objectID ofClass: (NSString*) class  
	// Returns a Promise for an id of type class  
	{  
	    if (!class) return [Promise resolvedWith: nil]; // (1)  
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

1.	If a nil is passed for class, do not start a query. Return a Promise that is already resolved as “nil”.
2.	Otherwise, create a Promise and proceed with an async task.

## Promise Class Reference

### Overview
The Promise class provides a way to execute sequences of asynchronous blocks in a controlled manner. Each Promise object represents a promise to deliver a result object or an error object to a block at some future time. When the result or error is delivered to the Promise though its resolve method, the appropriate block is scheduled on a queue and run.

### Tasks

#### Creating Promises

#### Debugging Promise Execution

### Class Methods

#### promiseWithName
    + (Promise*) promiseWithName: (NSString*) name;

###### Return Value
Returns a Promise

###### Discussion
Equivalent to
 
	Promise* p = [[Promise alloc] init];
	p.name = @”name”;

#### resolvedWith
    + (Promise*) resolvedWith: (id) result;

###### Return Value
Returns a Promise

###### Discussion
Creates a new Promise that will resolve immediately with the object passed as result. 

#### resolvedWithError
    + (Promise*) resolvedWithError: (NSInteger) code
                       description: (NSString*) desc;

###### Return Value
Returns a Promise

###### Discussion
Creates a new Promise that will resolve immediately with an error object. The error object is created from the code and description passed using [Promise getError:description:]. When a Promise is resolved with this object, the error block will be run.

#### getError
    + (NSError*) getError: (NSInteger) code
    	      description: (NSString*) desc;

###### Return Value
Returns an NSError object

#### Discussion
Creates a new NSError that is created from the code and description passed. This can be used to resolve a Promise with an error when it is appropriate to call [promise resolve:…].

### Instance Methods

#### debug
	- (NSNumber*) debug;

#### Return Value
Returns an NSNumber* 

###### Discussion
Returns the debug property value.

#### setDebug
	- (void) setDebug: (NSNumber*) debug;

###### Return Value
None

###### Discussion
Sets the debug level. Defaults to zero. Zero means no debugging output. Set via promise.debug = <number>.

###### description
	- (NSString*) description;

###### Return Value
Returns an NSString*

###### Discussion
The string returned is a description of the full chain of Promises. The prev pointers are used to backtrack to the oldest Promise in the chain. The name property is used to identify each promise. The promise on who the method is called is identified with “*****”.

#### name
	- (NSString*) name;

###### Return Value
Returns an NSString*

###### Discussion
Returns an NSString that concatenates the basename with “.<generation>”. Generation is an internal property that consists of a number. Generation defaults to zero, but is incremented when Promises are strung together with then: and then:error:.

#### setName
	- (void) setName: (NSString*) name;

###### Return Value
None

###### Discussion
Sets basename to name and generation to zero. Then: and then:error: may increment generation. Use promise.name = @”name”.

#### next
	- (Promise*) next;

###### Return Value
Returns the Promise that is waiting for this Promise.

###### Discussion
It is not common to read this property except in debugging situations.

#### setNext
	- (void) next: (Promise*) p;

###### Return Value
None

###### Discussion
The next pointer is set to point to another Promise. When the Success or Error blocks return an object, whatever Promise is “next” is resolved by the return object. The next pointer is usually set by then: or then:error:. It is rarely set explicitly.

#### prev
	- (Promise*) prev;

###### Return Value
The Promise referred to by the “prev” pointer.

#### Discussion
The prev pointer is set as the reverse of the next pointer. It is ONLY set when a next pointer is set. After [p1 setNext: p2], p1.next == p2 and p2.prev == p1. User for debugging only.

#### queue
	- (dispatch_queue_t*) queue;

###### Return Value
Returns an NSString*

###### Discussion
The string returned is a description of the full chain of Promises. The prev pointers are used to backtrack to the oldest Promise in the chain.

#### setQueue
	- (void) setQueue: (dispatch_queue_t*) queue;

###### Return Value
None

###### Discussion
Sets the dispatch queue to use for the success and error blocks.

#### reject:description:
	- (void) reject: (NSInteger) code
	    description: (NSString*) desc;

###### Return Value
None

###### Discussion
Resolves this Promise with an error constructed from the code and description passed.

#### resolve
	- (void) resolve: (id) result;

###### Return Value
None

###### Discussion
Resolves this Promise. If the result object is an NSError, the Error block is scheduled and run. If there is no Error block, but there is a Next Promise, the Next Promise is resolved with the error. If there is no Error block and Next is nil, then assert(NO). If the result is not an NSError, then the Success block is scheduled and run.

#### prev
	- (Promise*) prev;

###### Return Value
The Promise referred to by the “prev” pointer.

##### Discussion
The prev pointer is set as the reverse of the next pointer. It is ONLY set when a next pointer is set. After [p1 setNext: p2], p1.next == p2 and p2.prev == p1. User for debugging only.

#### runOnMainQueue
	- (void) runOnMainQueue;

###### Return Value
None

###### Discussion
Sets the queue of this Promise to the Main queue. Any blocks scheduled by this promise will be scheduled on the Main queue.

#### then:
	- (Promise*) then: (id (^)(id result)) successBlock;

###### Return Value
Returns a new Promise.

###### Discussion
	[promise then: successBlock];

is equivalent to  

	[promise then: successBlock error: nil];

#### then: error:
	- (Promise*) then: (id (^)(id result))      successBlock
    	        error: (id (^)(NSError* error)) errorBlock;

###### Return Value
Returns a Promise*

###### Discussion
Assigns success and error blocks to the promise. Creates a new dependent Promise. The dependent Promise is set as the value of next of the current Promise. The dependent Promise inherits the queue and name of the current Promise. The dependent Promise’s generation is set to the generation of the current Promise plus 1. Thus in a string of then blocks, if the first Promise is named xyzzy, the name property will return xyzzy.0 for the first Promise in the string, xyzzy.1 for the second, xyzzy.2 for the third and so on.
