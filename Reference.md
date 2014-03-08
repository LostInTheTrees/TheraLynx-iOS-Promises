# Promise Class Reference
## Bob Carlson, TheraLynx LLC
##### Version 2.0.0

## Overview
The Promise class provides a way to execute sequences of asynchronous blocks 
in a controlled manner. Each Promise object represents a promise to deliver 
a result object or an NSError object to a block at some future time. When the 
result or error is delivered to the Promise though its resolve method, the 
appropriate block is scheduled on a queue and run.

## Tasks

#### Creating Promises
<pre>
<a href="#promisewithname">+ (Promise*)   promiseWithName: (NSString*) name;</a>
<a href="#resWith">+ (Promise*)      resolvedWith: (id)        result;</a>
<a href="#resWithNil">+ (Promise*)          resolved;</a>
<a href="#resError">+ (Promise*) resolvedWithError: (NSInteger) code
                   description: (NSString*) desc;</a>
</pre>

#### Resolution Blocks
<pre>
<a href="#after">+ (Promise*)     after: (NSDictionary*)         promises
   	                do: (PromiseIterationBlock) afterBlock;</a>
<a href="#after">- (Promise*)     after: (NSDictionary*)         promises
   	                do: (PromiseIterationBlock) afterBlock;</a>

<a href="#then">- (Promise*)      then: (PromiseSuccessBlock)   successBlock;</a>
<a href="#thenerror">- (Promise*) thenError: (PromiseSuccessBlock)   successBlock;</a>
<a href="#then1">- (Promise*)      then: (PromiseSuccessBlock)   successBlock
   	             error: (PromiseErrorBlock)     errorBlock;</a>

<a href="#thenmainq">- (Promise*)      thenMainQ: (PromiseSuccessBlock)   successBlock;</a>
<a href="#thenmain2">- (Promise*) thenErrorMainQ: (PromiseSuccessBlock)   successBlock;</a>
<a href="#thenmainq1">- (Promise*)      thenMainQ: (PromiseSuccessBlock)   successBlock
   	                  error: (PromiseErrorBlock)     errorBlock;</a>
</pre>

#### Resolving Promises
<pre>
<a href="#resolve">- (void)      resolve: (id)        result;</a>
<a href="#getError">+ (NSError*) getError: (NSInteger) code
          description: (NSString*) desc;</a>
</pre>

#### Cancelling Promises
<pre>
<a href="#cancel2">- (void) cancel: (PromiseCancelBlock) cancelBlock;</a>
<a href="#cancel1">- (void) cancel;</a>
</pre>

#### Scheduling
<pre>
<a href="#setNext">- (void)   setNext: (Promise*) p;</a>
<a href="#next">- (Promise*)  next;</a>
<a href="#prev">- (Promise*)  prev;</a>

<a href="#inContext">- (void) runInContext: (NSManagedObjectContext*) context;</a>
<a href="#OnMainQueue">- (void) runOnMainQueue;</a>
<a href="#HighPriority">- (void) runHighPriority;</a>
<a href="#Default">- (void) runDefault;</a>
<a href="#LowPriority">- (void) runLowPriority;</a>
<a href="#LowestPriority">- (void) runLowestPriority;</a>
</pre>

#### Debugging
<pre>
<a href="#debug">@property (readwrite...) NSInteger debug</a>
<a href="#name">@property (readwrite...) NSString* name</a>
</pre>

*****

## Class Methods

<a name="after"></a>
#### after:do:
<pre>+ (Promise*) after: (NSDictionary*)     dictOfPromises
                do: (<a href="#blocks">PromiseAfterBlock</a>) afterBlock;
</pre>

###### Return Value
Returns a Promise* 

###### Discussion
Returns an "aggregate" Promise. When each of the Promises in dictOfPromises has 
delivered its result, the afterBlock will be scheduled and run. The object passed 
to the afterBlock is a dictionary of the results. Each key of each result is the 
key of the Promise it is resolving. The result may be an NSError or nil. There is no Error 
block for an Aggregate Promise so errors must be found explicitly. However, there is 
an "errors" argument to the after block that gives the number of errors. Errors do 
not "pass through" aggregate Promises as they do with others that lack an Error block.

***

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

<a name="queueName"></a>
#### queueName

    + (NSString*) queueName;

###### Return Value
Returns a string identifying the current queue.

###### Discussion
This may be used within a resolution block to find the name that the Promise Class associates with the current queue. It returns an empty string when the current queue is not a global queue. It is intended for debugging only.

***

<a name="resWithNil"></a>
#### resolved   
    + (Promise*) resolved;

###### Return Value
Returns a Promise

###### Discussion
Creates a new Promise that will resolve immediately with nil as the result. 

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
Creates a new Promise that will resolve immediately with an error object. 
The error object is created from the code and description passed using 
[Promise getError:description:]. When a Promise is resolved with this object, 
the error block will be run.

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

## Properties

<a name="context"></a>
#### context 
	@property (readwrite, weak...) NSManagedObjectContext* context;

If context is set, any blocks executed by this promise will be 
executed on the queue associated with the context, allowing 
ManagedObjects to be easily referenced in the background. 

***

<a name="debug"></a>
#### debug 
	@property (readwrite...) NSInteger debug;

The debug property value. Zero by default, no debug logging. Value of one or greater enables debug logging.
Successor promises inherit the debug value of their predecessors when returned by the then or similar methods.

***

<a name="name"></a>
#### name 
	@property (readwrite...) NSString* name;

When you set name, the basename is set. When read, name returns an NSString* that concatenates the basename 
with “.serialNumber”. SerialNumber is a property that consists of a unique number for each Promise. 
See the serialNumber propertiy. 

***

<a name="next"></a>
#### next 
	@property (readwrite...) Promise* next;

Returns the Promise that is waiting for this Promise.
It is not common to read this property except in debugging situations.

The next pointer can be set to point to another Promise. When the Success or Error block returns an object, 
whatever Promise is “next” is resolved by the return object. The next pointer is usually set by then: or 
then:error:. It is rarely set explicitly.

***

<a name="prev"></a>
#### prev 
	@property (readwrite...) Promise* prev;
	
The prev pointer is set as the inverse of the next pointer. It is ONLY set when a next pointer is set. After p1.next = p2, p1.next == p2 and p2.prev == p1. Used for debugging only.

***

<a name="queue"></a>
#### queue
	@property (readwrite...) dispatch_queue_t* queue;

The dispatch queue to use for the resolution blocks. It not recommended to use this property for anything but debugging.

***

## Instance Methods

<a name="after"></a>
#### after:do:
<pre>- (Promise*) after: (˜NSDictionary*)    dictOfPromises
                do: (<a href="#blocks">PromiseAfterBlock</a>) afterBlock;
</pre>

###### Return Value
Returns a Promise* 

###### Discussion
Returns an "aggregate" Promise. When each of the Promises in dictOfPromises has 
delivered its result, the afterBlock will be scheduled and run. The object passed 
to the afterBlock is a dictionary of the results. Each key of each result is the 
key of the Promise it is resolving. The result may be an NSError or nil. There is no Error 
block for an Aggregate Promise so errors must be found explicitly. However, there is 
an "errors" argument to the after block that gives the number of errors. Errors do 
not "pass through" aggregate Promises as they do with others that lack an Error block.

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

<a name="description"></a>
#### description 
	- (NSString*) description;

###### Return Value
Returns an NSString*

###### Discussion
The string returned is a description of the full chain of Promises. The prev pointers are used to backtrack to the oldest Promise in the chain. The name property is used to identify each promise. The promise on who the method is called is identified with “*****”.

***

<a name="Iterate"></a>
#### iterate: 
	- (Promise*) iterate: (id(^)(id result, NSInteger step)) iterationBlock;

###### Return Value
Returns a new Promise.

###### Discussion
Iterate provides a method for executing the same block repeatedly. In an iterate block, when the block returns
a Promise, when that Promise is resolved, the iterate block is run again with the resolution object as the result.
If the block returns nil or any non-Promise object, the iteration block is completed.

The Promise returned by the iterate method is the successor to the iterate block. It will be resolved when 
the iterate block returns anything other than a Promise.

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

<a name="inContext"></a>
#### runInContext 
	- (void) runInContext: (NSManagedObjectContext*) context;

###### Return Value
None

###### Discussion
Equivalent to setting the context property.
If context is set, any blocks executed by this promise will be 
executed on the queue associated with the context, allowing 
ManagedObjects to be easily referenced in the background. 

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

<a name="LowestPriority"></a>
#### runLowestPriority 
	- (void) runLowestPriority;

###### Return Value
None

###### Discussion
Sets the queue of this Promise to the Background Global Queue.

***

<a name="then"></a>
#### then: 
	- (Promise*) then: (<a href="#blocks">PromiseSuccessBlock</a>) successBlock;

###### Return Value
Returns a new Promise.

###### Discussion
	[promise then: successBlock];

is equivalent to  

	[promise then: successBlock 
	        error: nil];

***

<a name="then1"></a>
#### then:error: 
<pre>- (Promise*) then: (<a href="#blocks">PromiseSuccessBlock</a>) successBlock
            error: (<a href="#blocks">PromiseErrorBlock</a>) errorBlock;</pre>

###### Return Value
Returns a Promise*

###### Discussion
Assigns success and error blocks to the promise. Creates a new dependent Promise. The dependent Promise is set as the value of next of the current Promise. The dependent Promise inherits the queue and name of the current Promise. The dependent Promise’s generation is set to the generation of the current Promise plus 1. Thus in a string of then blocks, if the first Promise is named xyzzy, the name property will return xyzzy.0 for the first Promise in the string, xyzzy.1 for the second, xyzzy.2 for the third and so on.

***

<a name="then2"></a>
#### thenerror: 
<pre>- (Promise*) then: (<a href="#blocks">PromiseSuccessBlock</a>) successBlock</pre>

###### Return Value
Returns a Promise*

###### Discussion
Assigns the same block to the Promise as both success and error blocks. 
See <a href="#then1">then:error:</a>.

***

<a name="thenMainQ"></a>
#### thenMainQ: 
<pre>- (Promise*) thenMainQ: (<a href="#blocks">PromiseSuccessBlock</a>) successBlock;</pre>

###### Return Value
Returns a new Promise.

###### Discussion
<pre>[promise thenMainQ: successBlock];

is equivalent to  

[promise then: successBlock error: nil];
[promise runOnMainQ];

See <a href="#then1">then:error:</a>.
</pre>
***

<a name="thenMainQ1"></a>
#### thenMainQ:error: 
<pre>- (Promise*) thenMainQ: (<a href="#blocks">PromiseSuccessBlock</a>) successBlock
    	         error: (<a href="#blocks">PromiseErrorBlock</a>)   errorBlock;</pre>

###### Return Value
Returns a new Promise.

###### Discussion
<pre>[promise thenMainQ: successBlock error: errorBlock];

is equivalent to  

[promise then: successBlock error: errorBlock];
[promise runOnMainQ];

See <a href="#then1">then:error:</a>.
</pre>

***
<a name="thenMainQ2"></a>
#### thenErrorMainQ: 
<pre>- (Promise*) thenErrorMainQ: (<a href="#blocks">PromiseSuccessBlock</a>) successBlock;</pre>

###### Return Value
Returns a new Promise.

###### Discussion
<pre>[promise thenMainQ: successBlock error: errorBlock];

is equivalent to  

[promise then: successBlock error: errorBlock];
[promise runOnMainQ];

See <a href="#then1">then:error:</a>.
</pre>

<a name="blocks"></a>
## Block Signatures
	typedef   id (^PromiseBlock) (id result);
Called when the Promise is resolved successfully. Result may be nil or any object including an NSError.

	typedef   id (^PromiseSuccessBlock) (id result);
Called when the Promise is resolved successfully. Result may be nil or any object that is not an NSError.

	typedef   id (^PromiseErrorBlock) (NSError* error);
Called when the Promise is resolved with an error.

	typedef   id (^PromiseAfterBlock) (NSMutableDictionary* results,  NSInteger errors);
Called when an "after" promise is resolved. Results is a dictionary of results keyed by the same keys 
as the dictionary of Promises used to create the after Promise. The individual result objects may be NSErrors. 
Errors contains the number of original Promises resolved by NSErrors.

	typedef   id (^PromiseIterationBlock) (id result, NSInteger step);
Called when an "iterate" promise is resolved. Step will be zero on the first call and will be incremented by one on each additional call. When an iterate block returns a Promise, the iterate block will be run again when the returned Promise is resolved. Any other return will run the "next" Promise.

	typedef void (^PromiseCancelBlock) (void);
Called when the Promise is cancelled.
