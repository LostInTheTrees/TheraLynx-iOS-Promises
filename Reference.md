# Promise Class Reference
## Bob Carlson, TheraLynx LLC

### Overview
The Promise class provides a way to execute sequences of asynchronous blocks in a controlled manner. Each Promise object represents a promise to deliver a result object or an error object to a block at some future time. When the result or error is delivered to the Promise though its resolve method, the appropriate block is scheduled on a queue and run.

### Tasks

#### Creating Promises
    + (Promise*)   [promiseWithName][promiseWithName]: (NSString*) name;
    + (Promise*)      resolvedWith: (id)        result;
    + (Promise*) resolvedWithError: (NSInteger) code
                       description: (NSString*) desc;

#### Adding Blocks
	- (Promise*) then: (id (^)(id result))      successBlock;
	- (Promise*) then: (id (^)(id result))      successBlock
    	        error: (id (^)(NSError* error)) errorBlock;

#### Resolving Promises
    + (Promise*)      resolvedWith: (id)        result;
    + (Promise*) resolvedWithError: (NSInteger) code
                       description: (NSString*) desc;
    + (NSError*)          getError: (NSInteger) code
    	               description: (NSString*) desc; 

#### Scheduling
	- (Promise*)       next;
	- (void)        setNext: (Promise*) p;
	- (Promise*)       prev;	
	
	- (void) runOnMainQueue;
	- (void) runDefault;
	- (void) runLowPriority;
	- (void) runHighPriority;

#### Debugging
	- (NSNumber*) debug;    	      
	- (void)   setDebug: (NSNumber*) debug;
	- (NSString*)  name;
	- (void)    setName: (NSString*) name;

*****

### Class Methods

#### promiseWithName [promiseWithName]

    + (Promise*) promiseWithName: (NSString*) name;

###### Return Value
Returns a Promise

###### Discussion
Equivalent to

	Promise* p = [[Promise alloc] init];
	p.name = @”name”;

***

#### resolvedWith
    + (Promise*) resolvedWith: (id) result;

###### Return Value
Returns a Promise

###### Discussion
Creates a new Promise that will resolve immediately with the object passed as result. 

***

#### resolvedWithError
    + (Promise*) resolvedWithError: (NSInteger) code
                       description: (NSString*) desc;

###### Return Value
Returns a Promise

###### Discussion
Creates a new Promise that will resolve immediately with an error object. The error object is created from the code and description passed using [Promise getError:description:]. When a Promise is resolved with this object, the error block will be run.

***

#### getError
    + (NSError*) getError: (NSInteger) code
    	      description: (NSString*) desc;

###### Return Value
Returns an NSError object

#### Discussion
Creates a new NSError that is created from the code and description passed. This can be used to resolve a Promise with an error when it is appropriate to call [promise resolve:…].

***

### Instance Methods

#### debug
	- (NSNumber*) debug;

#### Return Value
Returns an NSNumber* 

###### Discussion
Returns the debug property value.

***

#### setDebug
	- (void) setDebug: (NSNumber*) debug;

###### Return Value
None

###### Discussion
Sets the debug level. Defaults to zero. Zero means no debugging output. Set via promise.debug = <number>.

***

###### description
	- (NSString*) description;

###### Return Value
Returns an NSString*

###### Discussion
The string returned is a description of the full chain of Promises. The prev pointers are used to backtrack to the oldest Promise in the chain. The name property is used to identify each promise. The promise on who the method is called is identified with “*****”.

***

#### name
	- (NSString*) name;

###### Return Value
Returns an NSString*

###### Discussion
Returns an NSString that concatenates the basename with “.<generation>”. Generation is an internal property that consists of a number. Generation defaults to zero, but is incremented when Promises are strung together with then: and then:error:.

***

#### setName
	- (void) setName: (NSString*) name;

###### Return Value
None

###### Discussion
Sets basename to name and generation to zero. Then: and then:error: may increment generation. Use promise.name = @”name”.

***

#### next
	- (Promise*) next;

###### Return Value
Returns the Promise that is waiting for this Promise.

###### Discussion
It is not common to read this property except in debugging situations.

***

#### setNext
	- (void) setNext: (Promise*) p;

###### Return Value
None

###### Discussion
The next pointer is set to point to another Promise. When the Success or Error blocks return an object, whatever Promise is “next” is resolved by the return object. The next pointer is usually set by then: or then:error:. It is rarely set explicitly.

***

#### prev
	- (Promise*) prev;

###### Return Value
The Promise referred to by the “prev” pointer.

#### Discussion
The prev pointer is set as the reverse of the next pointer. It is ONLY set when a next pointer is set. After [p1 setNext: p2], p1.next == p2 and p2.prev == p1. User for debugging only.

***

#### queue
	- (dispatch_queue_t*) queue;

###### Return Value
Returns an NSString*

###### Discussion
The string returned is a description of the full chain of Promises. The prev pointers are used to backtrack to the oldest Promise in the chain.

***

#### setQueue
	- (void) setQueue: (dispatch_queue_t*) queue;

###### Return Value
None

###### Discussion
Sets the dispatch queue to use for the success and error blocks.

***

#### reject:description:
	- (void) reject: (NSInteger) code
	    description: (NSString*) desc;

###### Return Value
None

###### Discussion
Resolves this Promise with an error constructed from the code and description passed.

***

#### resolve
	- (void) resolve: (id) result;

###### Return Value
None

###### Discussion
Resolves this Promise. If the result object is an NSError, the Error block is scheduled and run. If there is no Error block, but there is a Next Promise, the Next Promise is resolved with the error. If there is no Error block and Next is nil, then assert(NO). If the result is not an NSError, then the Success block is scheduled and run.

***

#### prev
	- (Promise*) prev;

###### Return Value
The Promise referred to by the “prev” pointer.

##### Discussion
The prev pointer is set as the reverse of the next pointer. It is ONLY set when a next pointer is set. After [p1 setNext: p2], p1.next == p2 and p2.prev == p1. User for debugging only.

***

#### runOnMainQueue
	- (void) runOnMainQueue;

###### Return Value
None

###### Discussion
Sets the queue of this Promise to the Main queue. Any blocks scheduled by this promise will be scheduled on the Main queue.

***

#### runDefault
	- (void) runDefault;

###### Return Value
None

###### Discussion
Sets the queue of this Promise to the Default Priority Global Queue. This is the usual default.

***

#### runHighPriority
	- (void) runHighPriority;

###### Return Value
None

###### Discussion
Sets the queue of this Promise to the High Priority Global Queue.

***

#### runLowPriority
	- (void) runLowPriority;

###### Return Value
None

###### Discussion
Sets the queue of this Promise to the Low Priority Global Queue.

***

#### then:
	- (Promise*) then: (id (^)(id result)) successBlock;

###### Return Value
Returns a new Promise.

###### Discussion
	[promise then: successBlock];

is equivalent to  

	[promise then: successBlock error: nil];

***

#### then: error:
	- (Promise*) then: (id (^)(id result))      successBlock
    	        error: (id (^)(NSError* error)) errorBlock;

###### Return Value
Returns a Promise*

###### Discussion
Assigns success and error blocks to the promise. Creates a new dependent Promise. The dependent Promise is set as the value of next of the current Promise. The dependent Promise inherits the queue and name of the current Promise. The dependent Promise’s generation is set to the generation of the current Promise plus 1. Thus in a string of then blocks, if the first Promise is named xyzzy, the name property will return xyzzy.0 for the first Promise in the string, xyzzy.1 for the second, xyzzy.2 for the third and so on.
