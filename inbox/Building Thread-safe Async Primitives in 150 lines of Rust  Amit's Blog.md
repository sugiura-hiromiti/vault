---
title: Building Thread-safe Async Primitives in 150 lines of Rust | Amit's Blog
source: https://amit.prasad.me/blog/async-oneshot
author: 
published: 
created: 2025-05-22
description: 
tags:
  - clippings
status: unread
aliases: 
updated: 2025-06-10T06:33
---
## \> Building Thread-safe Async Primitives in 150 lines of Rust\_

November 25, 2024 · [Amit Prasad](https://amit.prasad.me/)

---

In this post, I’ll go over a simple, yet fast implementation of the (commonly seen) “oneshot” channel, going through lower-level asynchronous Rust, synchronization primitives, all alongside the unseen footguns of concurrent code. We build and iterate on a real, dependency-free, async oneshot channel library, published on crates.io.

Asynchronous Rust can be scary. Hell, writing concurrent code in general is always a little scary. Understanding “simple” primitives like this one often helps in understanding the more complex ones.

Here’s a snippet demonstrating what we’ll be building:

```
use async_oneshot_channel::oneshot;

use futures::executor::block_on;

// A oneshot for sending a single integer

let (tx, rx) = oneshot();

// Send a value

tx.send(42).unwrap();

// Receive the value asynchronously

// Could be in another thread/task!

let result = block_on(rx.recv());

assert_eq!(result, Some(42));
```

## Groundwork, and the Problem

Alrighty, let’s define what we want to solve with our oneshot channel.

> Wait a sec, why do we actually need oneshot channels?

Good question! For illustrative purposes, consider an intra-process request-response system. Suppose we have a task, connected to the rest of the process via another “multi-shot” (`mpsc`, below) channel — allowing other tasks in the process to send requests (“messages”) to our task:

```
enum Request {

    Add(i32, i32)

}

struct MyTask {

    rx: mpsc::Receiver<Request>,

}

async fn run_my_task(mut task: MyTask) {

    while let Some(request) = task.rx.recv().await {

        // Process the request

        match request {

            Request::Add(a, b) => {

                let result = a + b;

                // Send the response back

                // ...?

            }

        }

    }

}

// Elsewhere:

let (tx, rx) = mpsc::channel::<Request>();

// Assuming we construct MyTask with \`rx\`, use \`tx\`:

tx.send(Request::Add(a, b)).await; // Send a request
```

> Sure, but is this toy example applicable to real software?

Yep! In the real-world we see this pattern in the Actor execution model, which has been used to model many concurrent (and distributed!) systems for decades.

Back to the problem. Once our task processes the input, it needs to send a response back to the caller. We have no way of knowing “where” in the code, or what other task to return our response to, especially since an `mpsc` channel implies **m** ultiple **p** roducers. In other words, there is no 1-1 correspondence implied by the channel, and even if we constrained to the 1-1 case, we don’t have a great way to return the request across this 1-way channel.

In comes oneshot:

```
// Let's include a oneshot response channel, in our request:

enum Request {

    Add(i32, i32, oneshot::Sender<i32>)

}

// In our task:

async fn run_my_task(mut task: MyTask) {

    while let Some(request) = task.rx.recv().await {

        // Process the request, as before

        match request {

            Request::Add(a, b, tx) => {

                let result = a + b;

                // But now, we can respond via the oneshot!

                tx.send(result).unwrap();

            }

        }

    }

}
```

We now include a “handle” via which we can send the response back to the original caller. We construct the receiving end of the oneshot whilst sending the request, so the caller can wait for the response at their leisure:

```
// At the caller site:

let (tx, rx) = oneshot::<i32>();

tx.send(Request::Add(1, 2, tx)).await;

do_some_other_work();

// Now, we can wait for the response via \`rx\`:

let result = rx.recv().await.unwrap();
```

> Alright great, a motivating use-case. What does a oneshot channel need to look like to support this?

For starters, we need obviously need to support:

- Sending at most one value over the channel, reliably. Any subsequent sends should fail.
- Receiving at most one value from the channel

Where “reliably” means that a single send operation will always succeed.

> “At most one value”? Why not just “one”?

Well, what if `MyTask` encounters an error and crashes? We don’t want the caller to wait forever, hence another requirement:

- If all sender handles are dropped, the receiver is notified that the value will never arrive

Remember, Rust’s borrow checker semantics mean that if the last `oneshot::Sender` is dropped, then it’s guaranteed that there is absolutely no way to send a value over the channel anymore.

And finally, one important requirement:

- Waiting to receive a value should be asynchronous (non-blocking)

> What does that mean? Why is that important?

In asynchronous applications, there could be thousands of tasks running on a handful of threads. Each task “takes turns” actually running on a thread. If a task is waiting for a response, it isn’t doing any computational work, so the thread should be free to run other tasks.

Imagine if waiting for a response blocked the entire thread. We wouldn’t be able to run any other tasks on that thread, and we’d be keeping the processor busy doing nothing!

## The Implementation

> A naive implementation seems simple enough, just use a `Mutex<Option<T>>`, right?

```
use std::sync::{Mutex, Arc};

pub struct OneshotChan<T> {

    inner: Arc<Mutex<Option<T>>>,

}

impl<T> OneshotChan<T> {

    pub fn send(&self, value: T) -> Result<(), T> {

        let mut inner = self.inner.lock().unwrap();

        // If there's already a value, return the input

        if inner.is_some() {

            return Err(value);

        }

        // Otherwise, set the value

        *inner = Some(value);

        Ok(())

    }

}
```

> Okay, but what about the receiver? We need our receiving task to be notified when `inner` is set to `Some(..)`. Hmm, let’s try this?

```
use std::sync::{Mutex, Arc};

pub struct OneshotChan<T> {

    inner: Arc<Mutex<Option<T>>>,

}

impl<T> OneshotChan<T> {

    pub fn recv(&self) -> T {

        while self.inner.lock().unwrap().is_none() {

            // Spin until the value is set

        }

        // Return the value

        self.inner.lock().unwrap().take()

    }

}
```

> Ah wait! This isn’t async. What did I do wrong?

Remember how we said that waiting should be non-blocking, and shouldn’t consume the thread? This implementation works by constantly locking the Mutex and checking if the value is set, over and over again. This is called “busy-waiting” and is generally a terrible idea.

In fact, it’s even worse here, since locking a Mutex isn’t free, and we’re doing it in a loop, not to mention that this doesn’t achieve most of the stated requirements we had above.

> Okay, so no busy waiting. Then how do we notify the receiver without the receiver constantly checking?

Good question, once again! Here we turn to Rust’s async side, and the `Future` trait.

Futures in Rust are effectively creating a state machine which asks an “executor” to run them in a specified way. If you’ve heard of `tokio`, or `smol`, or `async-std`, you’ve heard of an executor. The executor is responsible for scheduling and running futures/tasks, and how they interact with threads (if at all). Let’s take a look at making a simple future, starting with the skeleton:

```
// We implement the Future trait to define a future

use std::future::Future;

use std::task::{Poll, Context, Waker};

pub struct ReceiveFuture<T> {}

impl<T> Future for ReceiveFuture<T> {

    // What does the future return on completion?

    type Output = T;

    // Huh?

    fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {}

}
```

> Lots to unpack, the “Output” type seems pretty straightforward. What’s going on with `Pin`, `Context`, and `Poll`?

`Pin` [has been explained](https://fasterthanli.me/articles/pin-and-suffering) by those more familiar than I, for the purposes of this post, think of it as a `&self` that’s “more async-friendly”.

Let’s start with `Poll`. `Poll` is an enum with two variants which tell the executor what the future’s status is:

- `Poll::Ready(T)`: The future has completed, and the value `T` is ready to be returned to the caller.
- `Poll::Pending`: The future is not yet ready, and needs to be polled again

> Okay, so the executor “polls” the future, and the future tells the executor if it’s ready?

Exactly!

> But how does the executor know when to poll the future again if it’s not ready?

That’s where `Context` comes in. `Context` allows us to get a handle to something called a `Waker`, which has methods to wake up (re-poll) the future. So our future has access to the handle can be used to wake it up.

> Hold up, how does that help anything? The `Waker` is inside the same future that wants to be woken up! If it’s already returned `Poll::Pending`, it would never have a chance to wake itself up, right?

Good point! That’s why we typically pass the `Waker` to some other thread or task. Let’s apply this to our `OneshotChan`. First, let’s modify our `OneshotChan` to have a field for storing the `Waker`, and our `ReceiveFuture` to store a reference to the `OneshotChan` it’s associated with:

```
// Using OnceLock

use std::sync::OnceLock;

pub struct OneshotChan<T> {

    inner: Mutex<Option<T>>,

    // We'll store the waker here.

    waker: OnceLock<Waker>,

}

pub struct ReceiveFuture<T> {

    // Keep a reference to the channel

    chan: Arc<OneshotChan<T>>,

}
```

Notice how we’re storing the `Waker` in a `OnceLock`. This is for two reasons: We can modify it via interior mutability, briefly discussed later on, whilst retaining thread-safety, and we can ensure that the `Waker` is only set once, as we only have one receiver.

Let’s modify our `send` method to wake up the receiver once we’ve set the value we’re sending. We’ll also modify the `recv` method to create an instance of `ReceiveFuture`:

```
impl<T> OneshotChan<T> {

    pub fn send(&self, value: T) -> Result<(), T> {

        let mut inner = self.inner.lock().unwrap();

        if inner.is_some() {

            return Err(value);

        }

        *inner = Some(value);

        // If there's a waker, wake it up!

        if let Some(waker) = self.waker.get() {

            waker.wake_by_ref();

        }

        Ok(())

    }

    // Now, this just creates the future

    pub fn recv(&self) -> ReceiveFuture<T> {

        ReceiveFuture {

            chan: self.inner.clone()

        }

    }

}
```

And finally, we can implement the `Future` trait for `ReceiveFuture`:

```
impl<T> Future for ReceiveFuture<T> {

    type Output = T;

    fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {

        // First, store a waker handle in the channel

        // OnceLock guarantees that this only happens once

        self.chan.waker.get_or_init(|| cx.waker().clone());

        // Then, check if the value is set

        let mut inner = self.chan.inner.lock().unwrap();

        if let Some(value) = inner.take() {

            Poll::Ready(value)

        } else {

            // If not, return Pending

            Poll::Pending

        }

    }

}
```

Here’s what we’ve effectively done:

1. When the receiver awaits the future for the first time, it stores a waker handle in the channel.
2. The receiver then locks and checks if the channel’s value has been set.
3. If it has, we’re done! Return `Poll::Ready(..)` with the value.
4. If not, we return `Poll::Pending`, and since the waker is stored in the channel, the sender can wake up the receiver when it sets the value.

> That’s it? That’s all we need?

Well… not quite. As it stands, this implementation still has a few issues. For one, we’re not correctly implementing the “oneshot” semantics as we defined above. Since we’re using `Option::take`, we’re effectively “resetting” the channel after each successful receive, meaning the same channel can be used for another value. Mutexes are also relatively expensive — We don’t expect this oneshot channel to be used in high-contention scenarios, but it’s a good exercise to see how we can avoid using a Mutex altogether.

It would be great if we could solve both of these problems in a single go, wouldn’t it?

> Go on…

Alrighty. Setting the channel just once. Let’s search the standard library for something that might help. Hmm… `Once` in `std::sync` looks interesting. What do the docs say?

> “A low-level synchronization primitive for one-time global execution.”

Sounds like what we need! `Once::call_once` looks like it takes a closure and ensures the closure is executed exactly once across even if called concurrently. Let’s try using it:

```
pub struct OneshotChan<T> {

    inner: Mutex<Option<T>>,

    waker: OnceLock<Waker>,

    // Keep track of whether the value has been set via Once

    tx: Once,

}

// In send:

pub fn send(&self, value: T) -> Result<(), T> {

    // Call the closure only once

    self.tx.call_once(|| {

        let mut inner = self.inner.lock().unwrap();

        // No need to check if \`inner\` is already set, \`Once\` ensures this

        *inner = Some(value);

        if let Some(waker) = self.waker.get() {

            waker.wake_by_ref();

        }

    });

    Ok(())

}
```

Ok. Couple of issues. First off, we’re always returning `Ok(())` from `send`, even if the value was already set. How do we idiomatically detect if the value was already set?

```
// Take 2

pub fn send(&self, value: T) -> Result<(), T> {

    let mut data = Some(value);

    self.tx.call_once(|| {

        let mut inner = self.inner.lock().unwrap();

        // data.take() always returns Some(..), and sets data to None

        *inner = Some(data.take().unwrap());

        if let Some(waker) = self.waker.get() {

            waker.wake_by_ref();

        }

    });

    match data {

        // Data is Some(..) if call_once didn't run

        Some(value) => Err(value),

        // Data is None if call_once ran

        None => Ok(())

    }

}
```

Cool trick with `data.take()` to check if `Once` was just run, right? Now, we still haven’t solved the issue of the Mutex here.

First, ask ourselves what property of the Mutex we’re actually using here. Notice that `send` takes an *immutable* reference to `&self`, yet we store data in `self`. This means we’re using our Mutex for something called “interior mutability”, where we mutate data inside a container object without a mutable reference to the container itself, whilst still satisfying the Rust borrow checker. I won’t go into depth here, but you can read more about interior mutability in the [Rust book](https://doc.rust-lang.org/book/ch15-05-interior-mutability.html).

> So, interior mutabilty without a Mutex?

Yep, we could simply use a `Cell` for this. Unlike the `Waker`, we’re synchronizing access to the data via `Once` ourselves — we’ve effectively built our own `OnceLock`! Let’s just replace the `Mutex` with a `Cell`:

```
use std::cell::Cell;

pub struct OneshotChan<T> {

    // No more Mutex!

    inner: Cell<Option<T>>,

    waker: OnceLock<Waker>,

    tx: Once

}
```

and modify our `send` method:

```
pub fn send(&self, value: T) -> Result<(), T> {

    let mut data = Some(value);

    self.tx.call_once(|| {

        // No more locking, just:

        self.inner.set(data.take());

        if let Some(waker) = self.waker.get() {

            waker.wake_by_ref();

        }

    });

    match data {

        // Data is Some(..) if call_once didn't run

        Some(value) => Err(value),

        // Data is None if call_once ran

        None => Ok(())

    }

}
```

and finally, our `ReceiveFuture` needs to be modified to account for `Once` and `Cell`:

```
impl<T> Future for ReceiveFuture<T> {

    type Output = T;

    fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {

        // Unchanged, storing a waker:

        self.chan.waker.get_or_init(|| cx.waker().clone());

        // Instead of locking, check if the \`Once\` has run:

        if self.chan.tx.is_completed() {

            Poll::Ready(self.chan.inner.take())

        } else {

            Poll::Pending

        }

    }

}
```

> Does a second `await` of `ReceiveFuture` return `None`, as we expect it to?

Let’s see. The first `await` only returns once the value is set, and returns via `self.chan.inner.take()`. Here’s how `Cell::take` is implemented in the standard library:

```
impl<T: Default> Cell<T> {

    /// Takes the value of the cell, leaving \`Default::default()\` in its place.

    pub fn take(&self) -> T {

        self.replace(Default::default())

    }

}
```

And since `Option<T>` defaults to `None`, a `take()` replaces the cell value with `None`. A second `await` just takes a None out of the cell, and returns it, as we expect.

While going through the standard library documentation, however, I notice this note on `Once::call_once`: “This method will block the calling thread if another initialization routine is currently running.” If you’ve written thread-synchronized code before, this should be ringing alarm bells: Do as little as possible inside `call_once`! Again, we don’t expect this to be high-contention, but if we *can* try optimizing it, why not?

```
pub fn send(&self, value: T) -> Result<(), T> {

    let mut data = Some(value);

    self.tx.call_once(|| {

        self.inner.set(data.take());

        // Move the waker call from here...

    });

    match data {

        Some(value) => Err(value),

        None => {

            // ...to here

            if let Some(waker) = self.waker.get() {

                waker.wake_by_ref();

            }

            Ok(())

        }

    }

}
```

Now let’s review our requirements:

- Sending at most one value over the channel, reliably. Any subsequent sends should fail.

We’ve ensured this via `Once`.

- Receiving at most one value from the channel

Again, via `Once` and `Cell::take`.

- Waiting to receive a value should be asynchronous (non-blocking)

We’re using a `Waker` and the `Future` trait to ensure this.

- If all sender handles are dropped, the receiver is notified that the value will never arrive

Ah, we haven’t gotten to this part yet. Immediate problem: We don’t have a “sender handle” to drop, without dropping the entire channel. Since the `ReceiveFuture` has an `Arc` to the channel, we can’t just drop the channel either. Let’s do a quick refactor to move public `send` functionality to a separate `Sender` struct:

```
// Modify OneshotChan so \`send\` is private (not shown)

// We can clone the sender handle! There's no limit on potential senders,

// just on there being a single value sent during the channel's lifetime.

#[derive(Clone)]

pub struct Sender<T> {

    chan: Arc<OneshotChan<T>>

}

impl<T> Sender<T> {

    pub fn send(&self, value: T) -> Result<(), T> {

        self.chan.send(value)

    }

}
```

> But how are we meant to keep track of the number of senders?

Let’s see… Senders are associated with their channels, and it looks like we need to do some manual reference counting on how many senders there are. So we can keep track of a counter inside our `OneshotChan`. Since senders could be created/cloned on any thread, let’s use atomics from the standard library:

```
use std::sync::atomic::{AtomicUsize, Ordering};

pub struct OneshotChan<T> {

    inner: Cell<Option<T>>

    waker: OnceLock<Waker>,

    tx: Once

    // Keep track of the number of senders

    sender_rc: AtomicUsize

}
```

And then we can increment and decrement this counter when `Clone` and `Drop` are called on the `Sender`:

```
// Move away from #[derive(Clone)], so we can implement ref-counting

impl<T> Clone for Sender<T> {

    fn clone(&self) -> Self {

        // Atomic increment

        self.chan.sender_rc.fetch_add(1, Ordering::Release);

        Self {

            chan: self.chan.clone()

        }

    }

}

impl<T> Drop for Sender<T> {

    fn drop(&mut self) {

        // Atomic decrement

        self.chan.sender_rc.fetch_sub(1, Ordering::AcqRel);

    }

}
```

> What is the meaning behind the `Ordering::Release` and `Ordering::AcqRel`?

Since we’re using a single atomic variable, we don’t really need to worry about the exact meaning of `Ordering` here. In a nutshell, by default, atomic operations only guarantee that a “load-then-store” happens atomically, meaning that an `x += 1` will always actually result in an increment of 1. `Release` followed by `Acquire` guarantees to us that some notoion of causality between operations is established. The important part is that `drop` always sees the latest `sender_rc` value. Rust borrows these naming conventions from C++, so if you’re interested in the details, you can read more about it in the [Rustnomicon](https://doc.rust-lang.org/nomicon/atomics.html).

> It doesn’t look like we’re notifying the receiver when there are no more senders. How do we do that?

Getting to that! We can use the `drop` implementation to check if the `sender_rc` has just been decremented to 0, and if so, wake up the receiver:

```
impl<T> Drop for Sender<T> {

    fn drop(&mut self) {

        // If the \`fetch\` returns 1, then we just decremented to 0

        if self.chan.sender_rc.fetch_sub(1, Ordering::AcqRel) == 1 {

            // Wake up the receiver. Remember, we may not be receiving yet!

            if let Some(waker) = self.chan.waker.get() {

                waker.wake_by_ref();

            }

        }

    }

}
```

But remember, we aren’t setting the `Once` in `OneshotChan`, so we need to modify our `ReceiveFuture` to check if the `sender_rc` counter is 0:

```
impl<T> Future for ReceiveFuture<T> {

    type Output = T;

    fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {

        self.chan.waker.get_or_init(|| cx.waker().clone());

        if self.chan.tx.is_completed() {

            Poll::Ready(self.chan.inner.take())

        } else if self.chan.sender_rc.load(Ordering::Acquire) == 0 {

            // If there are no more senders, return None

            Poll::Ready(None)

        } else {

            Poll::Pending

        }

    }

}
```

Again, the `Ordering` here is to ensure that there aren’t data race conditions between the `sender_rc` and the future’s `Poll` result. We want to ensure that we don’t erroneously return `Poll::Pending` as there may not be any senders left — leaving the task waiting forever.

> And that’s it?

Just some finishing touches:

```
// Renaming ReceiveFuture to Receiver, OneshotChan to Chan

// Woah! Unsafe?

unsafe impl<T: Send + Sync> Sync for Chan<T> {}

unsafe impl<T: Send> Send for Chan<T> {}

// And finally, a simple public constructor for the channel

pub fn oneshot<T>() -> (Sender<T>, Receiver<T>) {

    let chan = Arc::new(Chan::new());

    (Sender { chan: chan.clone() }, Receiver { chan })

}
```

Don’t worry about the unsafe! We’re effectively telling the compiler that we’ve manually implemented the synchronization guarantees for our oneshot channel. `Cell` is explicitly marked `!Sync`, but we’re using a `Once` around the data `Cell` to ensure that we synchronize access to it.

And there we have it. We’ve built a “simple” oneshot channel, with all the requirements we set out to meet. We’ve also sidestepped some of the common crutches (ahem, Mutexes), that people default to when writing concurrent code, whilst learning about `Once` and atomics.

The source code behind this oneshot channel can be found [here](https://github.com/AmitPr/async-oneshot-channel), and the crate is published on [crates.io](https://crates.io/crates/async-oneshot-channel). If you spot any issues in this post, or the crate, feel free to open an issue or contact me [here](https://amit.prasad.me/blog/).

### Update (2024-11-27)

Thanks to Reddit user Lantua for pointing out that using `Cell<Option<Waker>>` as done in a previous version of this post could lead to undefined behavior due to `Cell` being a `!Sync` type. Specifically, setting the waker isn’t an atomic, thread-safe operation, and a `take` operation could read a partially set Waker from memory (with vanishing probability, but possible nonetheless). The waker is now using `OnceLock`.

[← Back](https://amit.prasad.me/)