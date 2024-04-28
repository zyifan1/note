# Vert.x core——HTTPServer和HTTPClient

## vertx实例

Vert. x Core API 的入口点。

可以使用此类的实例来实现以下功能：

- 创建 TCP 客户端和服务器
- 创建 HTTP 客户端和服务器
- 创建 DNS 客户端
- 创建数据报套接字
- 设置和取消周期性和一次性定时器
- 获取事件总线 API 的引用
- 获取文件系统 API 的引用
- 获取对共享数据 API 的引用
- 部署和取消部署 verticle

Vert. x 核心中的大多数功能都相当低级。

要创建此类的实例，您可以使用静态工厂方法： vertx 、 vertx(VertxOptions)和clusteredVertx(VertxOptions, Handler) 。例如：

```java
Vertx vertx = Vertx.vertx();
```



## HTTP客户端和服务器

### 创建服务器

- 创建服务器对象实例

  ```java
  HttpServer server = vertx.createHttpServer();
  ```

- 如果不想使用默认的配置，可以通过创建HttpServerOptions对象，然后修改其默认值，然后在创建服务服务器时传入该对象，从而修改默认值。

  ```java
  //创建HttpServerOptions对象并设置最大WebSocket帧大小
  HttpServerOptions options = new HttpServerOptions().setMaxWebSocketFrameSize(1000000);
  
  HttpServer server = vertx.createHttpServer(options);
  ```

##### 常见服务器配置

- 记录网络波动

  ```java
  HttpServerOptions httpServerOptions = new HttpServerOptions().setLogActivity(true);
  ```



#### 启动服务器监听

##### 异步请求

调用`HttpServer`的`listen()`方法监听端口，此方法默认端口为80，该监听是异步的，服务器可能要等到调用返回后一段时间才会侦听，如果想在服务器实际监听时受到通知，可以为`listen`调用提供一个处理程序

```java
//监听端口   该方法异步
server.listen(port, result -> {
    if (result.succeeded()) {
        System.out.println("成功");
    } else {
        System.out.println("失败");
    }
});

//监听并调用处理程序
server.listen(80)
         .onComplete(res -> {
             if (res.succeeded()){
                 System.out.println("成功");
             }
             if (res.failed()){
                 System.out.println("失败");
             }
         });
```

##### 同步请求

如果需要在请求到达时收到通知，需要调用`HttpServer`的`requestHandler`方法

```java
server.requestHandler(res -> {
    System.out.println("requestHandler在 " + res.uri() + " 收到请求请求");
});
```

该方法的调用需要在`listen`之前



#### 处理请求

- 当请求到达时，将调用请求处理程序并传入 的实例`HttpServerRequest`。该对象代表服务器端 `HTTP `请求。

- 当请求的标头已完全读取时，将调用处理程序。

- 如果请求包含`body`，则该`body`将在调用请求处理程序后的某个时间到达服务器。

- 服务器请求对象（即`HttpServerRequest`）允许您检索`uri`、 `path`、`params`和 `headers`等。

- 每个服务器请求对象都与一个服务器响应对象相关联。可以使用 `response`获取对象的引用`HttpServerResponse` 。

  ```java
  //获取HttpServerRequest对应的HttpServerResponse对象
  HttpServerResponse response = request.response();
  ```

  ```java
  //简单的服务器处理请求并返回hello word
  vertx.createHttpServer().requestHandler(request -> {
    request.response().end("Hello world");
  }).listen(8080);
  ```



##### 获取请求参数

可以通过`HttpServerRequest`来获取该次请求的请求参数，包括headers、body、method等，以下列举几个常用的参数：

- 请求版本

- 请求方式

- 请求URI

- 请求path

- 请求query

- 请求标头

- 远程地址（IPV6）

- 绝对URI

  ```java
  request.version()       //请求版本
  request.method()        //请求方式
  request.uri()           //请求URI
  request.path()          //请求path
  request.query()         //请求query
  request.headers()       //请求标头
  request.remoteAddress() //远程地址（IPV6）
  request.absoluteURI()   //绝对URI
  ```



##### 结束处理程序

当整个请求（包括任何主体）被完全读取时，将调用`HttpServerRequest`的`endHandler`方法

```java
request.endHandler(res -> {
    System.out.println("请求结束");
});
```



##### 从请求body中读取数据

通常，`HTTP`请求包含我们想要读取的正文。正如前面提到的，当请求头到达时，请求处理程序就会被调用，因此请求对象此时没有body。

- 当body可能非常大（例如文件上传），并且通常不希望在将整个body交给程序之前将其缓冲在内存中，因为这可能会导致服务器耗尽可用内存。

  要接收body，可以在请求上使用`handler`  ，每次请求正文的一部分到达时都会调用该方法。

  ```java
  request.handler(buffer -> {
    System.out.println("I have received a chunk of the body of length " + buffer.length());
  });
  ```

- 如果请求body很小，希望在内存中聚合整个body，而不是像上述方法一样将一个body拆成多个部分多次访问，则可以自行聚合整个body

  ```java
  Buffer totalBuffer = Buffer.buffer();
  
  request.handler(buffer -> {
    System.out.println("I have received a chunk of the body of length " + buffer.length());
    totalBuffer.appendBuffer(buffer);
  });
  
  request.endHandler(v -> {
    System.out.println("Full body received, length = " + totalBuffer.length());
  });
  ```

  这种情况很常见，所以Vert.x提供了一个`bodyHandler`方法来执行上述操作，在收到所有body后，主处理程序将被调用一次

  ```java
  request.bodyHandler(totalBuffer -> {
    System.out.println("Full body received, length = " + totalBuffer.length());
  });
  ```

- 如果是请求是流式传输，则请求对象是一个ReadStream



##### 处理HTML form

`HTML` 表单可以使用`content-type`为`application/x-www-form-urlencoded`或来提交`multipart/form-data`

- 如果是url编码表单，表单的属性被封装在url中，则可以像调用普通query一样
- 对于大部分表单，他们的编码被封装到requestbody内，因此需要遵循上面body的调用规则（当请求处理程序执行完成后使用`handler`或`bodyhandler`）



##### 处理cookies

- 可以使用`request.getcookie()`、`request.cookies()`或`reques.cookieMap()`（以弃置，建议使用前两种）来获取cookie

- 使用`removeCookie`删除`cookie`

- 使用`addCookie`添加`cookie`

  ```java
  //查询cookie
  Cookie someCookie = request.getCookie("mycookie");
  String cookieValue = someCookie.getValue();
  
  //添加cookie
  request.response().addCookie(Cookie.cookie("othercookie", "somevalue"));
  
  //接口
  HttpServerResponse addCookie(Cookie cookie);
  
  //删除类似
  ```



#### 发送响应

服务器响应对象是`HttpServerResponse`的一个实例，并且是从请求中获取的`response`。

可以使用响应对象将响应写回HTTP客户端



##### 设置状态码和消息

响应的默认HTTP状态码为200，表示请求正常

可以使用`setStatusCode`来设置不同的code

还可以使用`setStatusMessage`来设置自定义状态消息，如果不自定义，则使用默认状态码及默认消息



##### 编写HTTP响应

- 要将数据写入`HTTP`响应，可以使用`write`，在响应之前可以多次调用。

  ```java
  //创建HTTP响应
  HttpServerResponse response = request.response();
  //创建buffer缓冲区
  Buffer buffer = new BufferImpl();
  //写入数据
  response.write(buffer);
  //write也可以直接传入String
  response.write("hello world!");
  //可以传入字符串编码
  response.write("hello world!", "UTF-16");
  ```

- 将数据写入响应时异步的，并且总会在写入后立即返回

- 如果只需要像HTTP响应写入单个字符串或buffer，则可以直接使用`end`

  ```java
  //http响应
  request.response()
          //设置响应头
          .putHeader("content-type", "text/plain")
          //结束响应，响应的返回值
          .end("Hello from Vert.x HTTP server!");
  ```

- 在第一次调用`write`时会将`responseHeader`写入响应中，因此如果不使用`chunk`（块）,则必须在写入响应之前设置`responseHeader`

##### 结束HTTP响应

- 一旦完成`HTTP`响应，就应该使用`end`

  ```java
  HttpServerResponse response = request.response();
  response.write("hello world!");
  response.end();
  
  HttpServerResponse response = request.response();
  response.end("hello world!");
  ```

- 默认情况下`Vert.x`不会自动关闭`keep-alive`连接，如果希望在空闲时间关闭他，则可以设置`setIdleTimeout`



### 创建客户端

#### 创建客户端实例

```java
HttpClient client = vertx.createHttpClient();
```

客户端配置选项

```java
//客户端配置对象实例
HttpClientOptions httpClientOptions = new HttpClientOptions();
//关闭keep-alive
httpClientOptions.setKeepAlive(false);
//在创建客户端实例时导入配置
HttpClient client = vertx.createHttpClient(options);
```



#### 发送请求

```java
httpClient.request(HttpMethod.GET,"/requestUri")
          .onComplete(res -> {
           		if (res.succeeded()){
                    System.out.println("成功");
                }
                if (res.failed()){
                    System.out.println("失败");
                }
     });
```



#### 写入请求并处理响应

可以使用`send`发送请求（例如`HTTP`）GET并处理异步`HttpClientResponse`

```java
client
  .request(HttpMethod.GET, 8080, "myserver.mycompany.com", "/some-uri")
  .onComplete(ar1 -> {
    if (ar1.succeeded()) {
      HttpClientRequest request = ar1.result();

      // Send the request and process the response
      request
        .send()
        .onComplete(ar -> {
          if (ar.succeeded()) {
            HttpClientResponse response = ar.result();
            System.out.println("Received response with status code " + response.statusCode());
          } else {
            System.out.println("Something went wrong " + ar.cause().getMessage());
          }
        });
    }
  });
```

