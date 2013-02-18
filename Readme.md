
# SocketMQ

Library for building application in ZeroMQ-like messaging semantics end to end. Build upon node.js and Engine.IO

## Introduction

[ZeroMQ](http://www.zeromq.org/) has introduced a completely new way for how we can exchange messages and resolve different messaging related problems in a much simpler and elegant way. But it's limited in your internal trusted network. Why not to make it avaliable for all the devices/members of your entire messaging process?

By combining ZeroMQ and [Engine.IO](https://github.com/LearnBoost/engine.io) the two great libs together, [SocketMQ](https://github.com/lsm/socketmq) simply makes the ZeroMQ-like semantics avaliable for clients which support Engine.IO. You can build application in same sets of messaging semantics/patterns end to end. Thus, it makes your event-driven realtime architecture much easier to implement.

## Example

### Request-Reply

#### server.js

```javascript
  var SocketMQ = require('socketmq');
  var context = SocketMQ.listen(8888, '127.0.0.1');

  var responder = context.socket('rep');

  responder.bind('news://', function(err) {
    if (err) throw err;
    
    console.log('Reply socket bound news:// at 127.0.0.1:8888');

    responder.on('message', function(data) {
      console.log('Server got message: ' + data);
      responder.send('World');
    });
  });
```

#### client.js

```javascript
  var SocketMQ = require('socketmq');
  var context = SocketMQ.connect(8888, '127.0.0.1');

  var requester = context.socket('req');

  requester.connect('news://');

  requester.on('message', function(data){
    console.log('Client got message: ' + data);
    setTimeout(function(){
      requester.send('Hello');  
    }, 300);
  });

  requester.send('Hello');
```

### Publish-Subscribe

#### pub.js

SocketMQ can listen to the existing `httpServer` instance.

```javascript
  var SocketMQ = require('socketmq');
  var http = require('http');
  var server = http.createServer().listen(8888, '127.0.0.1');
  var context = SocketMQ.listen(server);

  var publisher = context.socket('pub');

  publisher.bind('weather://', function(err) {
    if (err) throw err;

    console.log('Publish socket bound weather:// at 127.0.0.1:8888');

    setInterval(function() {
      publisher.send('AAA message');
      publisher.send('BBB message');
    }, 300);
  });s
```

#### sub.js

```javascript
  var SocketMQ = require('socketmq');
  var context = SocketMQ.connect(8888, '127.0.0.1');

  var subscriber = context.socket('sub');
  subscriber.connect('weather://');
  subscriber.subscribe('BBB');

  subscriber.on('message', function(data) {
    console.log('Subscriber got message: ' + data);
  });
```

### Push-Pull

#### pusher.js

```javascript
  var SocketMQ = require('socketmq');
  var context = SocketMQ.listen(8888, '127.0.0.1');

  var pusher = context.socket('push');
  pusher.bind('task://', function(err) {
    if (err) throw err;

    console.log('Push socket bound task:// at 127.0.0.1:8888');

    setInterval(function() {
      pusher.send("Pusher's workload");
    });
  });
```

#### puller.js

```javascript
  var SocketMQ = require('socketmq');
  var context = SocketMQ.listen(8888, '127.0.0.1');

  var puller = context.socket('pull');
  puller.connect('task://');

  puller.on('message', function(data) {
    console.log("Puller got task: " + data);
  });
```

## License 

(The MIT License)

Copyright (c) 2013 Senmiao Liu &lt;zir.echo@gmail.com&gt;

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.