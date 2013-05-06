# Promise Class Reference
## Bob Carlson, TheraLynx LLC
##### Version 1.01

### Overview
The Promise class provides a way to execute sequences of asynchronous blocks in a controlled manner. Each Promise object represents a promise to deliver a result object or an error object to a block at some future time. When the result or error is delivered to the Promise though its resolve method, the appropriate block is scheduled on a queue and run.

### Tasks

#### Creating Promises
<pre>
<a href="#promisewithname">+ (Promise*)   promiseWithName: (NSString*) name;</a>
<a href="#resWith">+ (Promise*)      resolvedWith: (id)        result;</a>
<a href="#resError">+ (Promise*) resolvedWithError: (NSInteger) code
                   description: (NSString*) desc;</a>
</pre>

#### Scheduling Blocks
<pre>
<a href="#after">- (Promise*) after: (NSArray*)                             arrayOfPromises
   	            do: (id (^)(NSMutableDictionary* results)) afterBlock;</a>

<a href="#then">- (Promise*)  then: (id (^)(id result))      successBlock;</a>
<a href="#thenerror">- (Promise*)  then: (id (^)(id result))      successBlock
   	         error: (id (^)(NSError* error)) errorBlock;</a>
</pre>

#### Resolving Promises
<pre>
<a href="#resolve">- (void)      resolve: (id)        result;</a>
<a href="#getError">+ (NSError*) getError: (NSInteger) code
          description: (NSString*) desc;</a>
</pre>

#### Cancelling Promises
<pre>
<a href="#cancel2">- (void) cancel: (void (^)())cancelBlock;</a>
<a href="#cancel1">- (void) cancel;</a>
</pre>

#### Scheduling
<pre>
<a href="#setNext">- (void)   setNext: (Promise*) p;</a>
<a href="#next">- (Promise*)  next;</a>
<a href="#prev">- (Promise*)  prev;</a>

<a href="#OnMainQueue">- (void) runOnMainQueue;</a>
<a href="#Default">- (void) runDefault;</a>
<a href="#LowPriority">- (void) runLowPriority;</a>
<a href="#HighPriority">- (void) runHighPriority;</a>
</pre>

#### Debugging
<pre>
<a href="#debug">- (NSNumber*) debug;</a>
<a href="#setDebug">- (void)   setDebug: (NSNumber*) debug;</a>
<a href="#name">- (NSString*)  name;</a>
<a href="#setName">- (void)    setName: (NSString*) name;</a>
</pre>

*****

### Class Methods

<a name="promiseWithName"></a>
#### promiseWithName

    + (Promise*) promiseWithName: (NSString*) name;

###### Return Value
Returns a Promise

###### Discussion
Equivalent to

	Promise* p = [[Promise alloc] init];
	p.name = @”name”;

***

<a name="resWith"></a>
#### resolvedWith   
    + (Promise*) resolvedWith: (id) result;

###### Return Value
Returns a Promise

###### Discussion
Creates a new Promise that will resolve immediately with the object passed as result. 

***

<a name="resError"></a>
#### resolvedWithError
    + (Promise*) resolvedWithError: (NSInteger) code
                       description: (NSString*) desc;

###### Return Value
Returns a Promise

###### Discussion
Creates a new Promise that will resolve immediately with an error object. The error object is created from the code and description passed using [Promise getError:description:]. When a Promise is resolved with this object, the error block will be run.

***

<a name="getError"></a>
#### getError
    + (NSError*) getError: (NSInteger) code
    	      description: (NSString*) desc;

###### Return Value
Returns an NSError object

###### Discussion
Creates a new NSError that is created from the code and description passed. This can be used to resolve a Promise with an error when it is appropriate to call [promise resolve:…].

***

### Instance Methods

<a name="after"></a>
#### after:do:
    - (Promise*) after: (NSArray*)                             arrayOfPromises
                    do: (id (^)(NSMutableDictionary* results)) afterBlock;

###### Return Value
Returns a Promise* 

###### Discussion
Returns an "aggregate" Promise. When each of the Promises in arrayOfPromises has delivered its result, the afterBlock will be scheduled and run. The object passed to the afterBlock is a dictionary of the results. Each result may be accessed via [results objectForKey: @(i)]; where i is the ordinal of the original Promise in arrayOfPromises. The key for the second result is @(2) and so on. The result may be an NSError. There is no Error block for an Aggregate Promise so errors must be found explicitly. Errors do not "pass through" aggregate Promises as they do with others that lack an Error block.

***

<a name="cancel1"></a>
#### cancel 
	- (void) cancel;

###### Return Value
None

###### Discussion
Cancel this promise and all its precedecessors.

* When a Promise is cancelled, it is marked as cancelled and its predecessor is also cancelled. This will ripple back to the earliest Promise in the chain. The next and prev pointers and the block pointers of a cancelled Promise are set to nil.
* If a Promise marked as cancelled is "resolved", nothing will happen, it's blocks will not be run.
* If a Cancel Block is attached to a Promise. It will be run (synchronously) if the Promise is cancelled. The cancel block can use this opportunity to cancel the "asynchonous service" that it is waiting for. 
* If a cancelled Promise has a dependent Promise an error will be used to resolve it. The error will have a code of 9999. 

***

<a name="cancel2"></a>
#### cancel: 
	- (void) cancel:  (void (^)())cancelBlock;

###### Return Value
None

###### Discussion
Set a Cancel Block to be run if this promise is cancelled.

***

<a name="debug"></a>
#### debug 
	- (NSNumber*) debug;

###### Return Value
Returns an NSNumber* 

###### Discussion
Returns the debug property value.

***

<a name="setDebug"></a>
#### setDebug
	- (void) setDebug: (NSNumber*) debug;

###### Return Value
None

###### Discussion
Sets the debug level. Defaults to zero. Zero means no debugging output. Set via promise.debug = <number>.

***

<a name="description"></a>
#### description 
	- (NSString*) description;

###### Return Value
Returns an NSString*

###### Discussion
The string returned is a description of the full chain of Promises. The prev pointers are used to backtrack to the oldest Promise in the chain. The name property is used to identify each promise. The promise on who the method is called is identified with “*****”.

***

<a name="name"></a>
#### name 
	- (NSString*) name;

###### Return Value
Returns an NSString*

###### Discussion
Returns an NSString that concatenates the basename with “.<generation>”. Generation is an internal property that consists of a number. Generation defaults to zero, but is incremented when Promises are strung together with then: and then:error:.

***

<a name="setName"></a>
#### setName 
	- (void) setName: (NSString*) name;

###### Return Value
None

###### Discussion
Sets basename to name and generation to zero. Then: and then:error: may increment generation. Use promise.name = @”name”.

***

<a name="next"></a>
#### next 
	- (Promise*) next;

###### Return Value
Returns the Promise that is waiting for this Promise.

###### Discussion
It is not common to read this property except in debugging situations.

***

<a name="setNext"></a>
#### setNext 
	- (void) setNext: (Promise*) p;

###### Return Value
None

###### Discussion
The next pointer is set to point to another Promise. When the Success or Error blocks return an object, whatever Promise is “next” is resolved by the return object. The next pointer is usually set by then: or then:error:. It is rarely set explicitly.

***

<a name="prev"></a>
#### prev 
	- (Promise*) prev;

###### Return Value
The Promise referred to by the “prev” pointer.

###### Discussion
The prev pointer is set as the reverse of the next pointer. It is ONLY set when a next pointer is set. After [p1 setNext: p2], p1.next == p2 and p2.prev == p1. User for debugging only.

***

<a name="queue"></a>
#### queue 
	- (dispatch_queue_t*) queue;

###### Return Value
Returns an NSString*

###### Discussion
The string returned is a description of the full chain of Promises. The prev pointers are used to backtrack to the oldest Promise in the chain.

***

<a name="setQueue"></a>
#### setQueue 
	- (void) setQueue: (dispatch_queue_t*) queue;

###### Return Value
None

###### Discussion
Sets the dispatch queue to use for the success and error blocks.

***

<a name="reject"></a>
#### reject:description:
	- (void) reject: (NSInteger) code
	    description: (NSString*) desc;

###### Return Value
None

###### Discussion
Resolves this Promise with an error constructed from the code and description passed.

***

<a name="resolve"></a>
#### resolve 
	- (void) resolve: (id) result;

###### Return Value
None

###### Discussion
Resolves this Promise. If the result object is an NSError, the Error block is scheduled and run. If there is no Error block, but there is a Next Promise, the Next Promise is resolved with the error. If there is no Error block and Next is nil, then assert(NO). If the result is not an NSError, then the Success block is scheduled and run.

***

<a name="after"></a>
#### prev [prev]
	- (Promise*) prev;

###### Return Value
The Promise referred to by the “prev” pointer.

###### Discussion
The prev pointer is set as the reverse of the next pointer. It is ONLY set when a next pointer is set. After [p1 setNext: p2], p1.next == p2 and p2.prev == p1. User for debugging only.

***

<a name="OnMainQueue"></a>
#### runOnMainQueue 
	- (void) runOnMainQueue;

###### Return Value
None

###### Discussion
Sets the queue of this Promise to the Main queue. Any blocks scheduled by this promise will be scheduled on the Main queue.

***

<a name="Default"></a>
#### runDefault 
	- (void) runDefault;

###### Return Value
None

###### Discussion
Sets the queue of this Promise to the Default Priority Global Queue. This is the usual default.

***

<a name="HighPriority"></a>
#### runHighPriority
	- (void) runHighPriority;

###### Return Value
None

###### Discussion
Sets the queue of this Promise to the High Priority Global Queue.

***

<a name="LowPriority"></a>
#### runLowPriority 
	- (void) runLowPriority;

###### Return Value
None

###### Discussion
Sets the queue of this Promise to the Low Priority Global Queue.

***

<a name="then"></a>
#### then: 
	- (Promise*) then: (id (^)(id result)) successBlock;

###### Return Value
Returns a new Promise.

###### Discussion
	[promise then: successBlock];

is equivalent to  

	[promise then: successBlock error: nil];

***

<a name="thenerror"></a>
#### then:error: 
	- (Promise*) then: (id (^)(id result))      successBlock
    	        error: (id (^)(NSError* error)) errorBlock;

###### Return Value
Returns a Promise*

###### Discussion
Assigns success and error blocks to the promise. Creates a new dependent Promise. The dependent Promise is set as the value of next of the current Promise. The dependent Promise inherits the queue and name of the current Promise. The dependent Promise’s generation is set to the generation of the current Promise plus 1. Thus in a string of then blocks, if the first Promise is named xyzzy, the name property will return xyzzy.0 for the first Promise in the string, xyzzy.1 for the second, xyzzy.2 for the third and so on.
