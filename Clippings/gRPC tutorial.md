---
title: "Quick start"
source: "https://grpc.io/docs/languages/python/quickstart/"
author:
  - "[[gRPC]]"
published:
created: 2025-08-20
description: "This guide gets you started with gRPC in Python with a simple working example."
tags:
  - "clippings"
---
This guide gets you started with gRPC in Python with a simple working example.

## Quick start

### Prerequisites

- Python 3.7 or higher
- `pip` version 9.0.1 or higher

If necessary, upgrade your version of `pip`:

```sh
python -m pip install --upgrade pip
```

If you cannot upgrade `pip` due to a system-owned installation, you can run the example in a virtualenv:

```sh
python -m pip install virtualenv
virtualenv venv
source venv/bin/activate
python -m pip install --upgrade pip
```

#### gRPC

Install gRPC:

```sh
python -m pip install grpcio
```

Or, to install it system wide:

```sh
sudo python -m pip install grpcio
```

#### gRPC tools

Python’s gRPC tools include the protocol buffer compiler `protoc` and the special plugin for generating server and client code from `.proto` service definitions. For the first part of our quick-start example, we’ve already generated the server and client stubs from [helloworld.proto](https://github.com/grpc/grpc/tree/v1.74.0/examples/protos/helloworld.proto), but you’ll need the tools for the rest of our quick start, as well as later tutorials and your own projects.

To install gRPC tools, run:

```sh
python -m pip install grpcio-tools
```

### Download the example

You’ll need a local copy of the example code to work through this quick start. Download the example code from our GitHub repository (the following command clones the entire repository, but you just need the examples for this quick start and other tutorials):

### Run a gRPC application

From the `examples/python/helloworld` directory:

1. Run the server:
	```sh
	python greeter_server.py
	```
2. From another terminal, run the client:
	```sh
	python greeter_client.py
	```

Congratulations! You’ve just run a client-server application with gRPC.

### Update the gRPC service

Now let’s look at how to update the application with an extra method on the server for the client to call. Our gRPC service is defined using protocol buffers; you can find out lots more about how to define a service in a `.proto` file in [Introduction to gRPC](https://grpc.io/docs/what-is-grpc/introduction/) and [Basics tutorial](https://grpc.io/docs/languages/python/basics/). For now all you need to know is that both the server and the client “stub” have a `SayHello` RPC method that takes a `HelloRequest` parameter from the client and returns a `HelloReply` from the server, and that this method is defined like this:

```proto
// The greeting service definition.
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply) {}
}

// The request message containing the user's name.
message HelloRequest {
  string name = 1;
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
}
```

Let’s update this so that the `Greeter` service has two methods. Edit `examples/protos/helloworld.proto` and update it with a new `SayHelloAgain` method, with the same request and response types:

```proto
// The greeting service definition.
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply) {}
  // Sends another greeting
  rpc SayHelloAgain (HelloRequest) returns (HelloReply) {}
}

// The request message containing the user's name.
message HelloRequest {
  string name = 1;
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
}
```

Remember to save the file!

### Generate gRPC code

Next we need to update the gRPC code used by our application to use the new service definition.

From the `examples/python/helloworld` directory, run:

```sh
python -m grpc_tools.protoc -I../../protos --python_out=. --pyi_out=. --grpc_python_out=. ../../protos/helloworld.proto
```

This regenerates `helloworld_pb2.py` which contains our generated request and response classes and `helloworld_pb2_grpc.py` which contains our generated client and server classes.

### Update and run the application

We now have new generated server and client code, but we still need to implement and call the new method in the human-written parts of our example application.

#### Update the server

In the same directory, open `greeter_server.py`. Implement the new method like this:

```py
class Greeter(helloworld_pb2_grpc.GreeterServicer):

    def SayHello(self, request, context):
        return helloworld_pb2.HelloReply(message=f"Hello, {request.name}!")

    def SayHelloAgain(self, request, context):
        return helloworld_pb2.HelloReply(message=f"Hello again, {request.name}!")
...
```

#### Update the client

In the same directory, open `greeter_client.py`. Call the new method like this:

```py
def run():
    with grpc.insecure_channel('localhost:50051') as channel:
        stub = helloworld_pb2_grpc.GreeterStub(channel)
        response = stub.SayHello(helloworld_pb2.HelloRequest(name='you'))
        print("Greeter client received: " + response.message)
        response = stub.SayHelloAgain(helloworld_pb2.HelloRequest(name='you'))
        print("Greeter client received: " + response.message)
```

#### Run!

Just like we did before, from the `examples/python/helloworld` directory:

1. Run the server:
	```sh
	python greeter_server.py
	```
2. From another terminal, run the client:
	```sh
	python greeter_client.py
	```

### What’s next

- Learn how gRPC works in [Introduction to gRPC](https://grpc.io/docs/what-is-grpc/introduction/) and [Core concepts](https://grpc.io/docs/what-is-grpc/core-concepts/).
- Work through the [Basics tutorial](https://grpc.io/docs/languages/python/basics/).
- Explore the [API reference](https://grpc.io/docs/languages/python/api).

Last modified November 25, 2024: [feat: move the $ shell line indicator to scss (#1354) (ab8b3af)](https://github.com/grpc/grpc.io/commit/ab8b3af6ddfccb1995e1a06367593b14972aaf4b)

[View page source](https://github.com/grpc/grpc.io/tree/main/content/en/docs/languages/python/quickstart.md) [Edit this page](https://github.com/grpc/grpc.io/edit/main/content/en/docs/languages/python/quickstart.md) [Create child page](https://github.com/grpc/grpc.io/new/main/content/en/docs/languages/python/quickstart.md?filename=change-me.md&value=---%0Atitle%3A+%22Long+Page+Title%22%0AlinkTitle%3A+%22Short+Nav+Title%22%0Aweight%3A+100%0Adescription%3A+%3E-%0A+++++Page+description+for+heading+and+indexes.%0A---%0A%0A%23%23+Heading%0A%0AEdit+this+template+to+create+your+new+page.%0A%0A%2A+Give+it+a+good+name%2C+ending+in+%60.md%60+-+e.g.+%60getting-started.md%60%0A%2A+Edit+the+%22front+matter%22+section+at+the+top+of+the+page+%28weight+controls+how+its+ordered+amongst+other+pages+in+the+same+directory%3B+lowest+number+first%29.%0A%2A+Add+a+good+commit+message+at+the+bottom+of+the+page+%28%3C80+characters%3B+use+the+extended+description+field+for+more+detail%29.%0A%2A+Create+a+new+branch+so+you+can+preview+your+new+file+and+request+a+review+via+Pull+Request.%0A) [Create documentation issue](https://github.com/grpc/grpc.io/issues/new?title=Quick%20start) [Create project issue](https://github.com/grpc/grpc.io/issues/new)