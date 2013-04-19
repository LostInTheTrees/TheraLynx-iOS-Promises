# Promises for iOS
## Bob Carlson, TheraLynx LLC

---

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

```- (Promise*) getPO: (NSString*) objectID ofClass: (NSString*) class  
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
}```

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

```- (Promise*) getThing3: (NSString*) objID1  
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
}```

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

```- (Promise*) doSomethingInForeground: (id) someArgument  
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
}```

1.	Call getThing3 to start an async task.
2.	Run the blocks for this Promise on the Main queue.
3.	Assign a Success block and an Error block for this task. [p0 then:…] returns a Promise, but this is discarded because these blocks do not start any asynchronous tasks. 
4.	The string of async tasks ends here and rejoins the Main queue.
5.	Nil is returned because these blocks do not promise any results.
 
### Pre-Resolved Promises

It also turns out to be valuable to be able to create a Promise that resolves immediately. Consider getPO again, which encapsulates an asynchronous task. It’s possible that getPO might determine that an async task is not needed. However, it must return a Promise. The answer is to return a Promise that is “already resolved”. As soon as a Success block is assigned to that Promise, the promise is resolved and the Success (or Error) block is scheduled and run.

```- (Promise*) getPO: (NSString*) objectID ofClass: (NSString*) class  
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
}```

1.	If a nil is passed for class, do not start a query. Return a Promise that is already resolved as “nil”.
2.	Otherwise, create a Promise and proceed with an async task.

