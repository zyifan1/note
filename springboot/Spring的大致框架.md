## Spring的大致框架

> IOC = 工厂模式 + XML + 反射



我们在使用 Spring 类型框架时，最主要的一点，就是他们帮助我们创建并管理 Bean。

但是如何创建并管理？

<img src="C:\Users\周逸凡\AppData\Roaming\Typora\typora-user-images\image-20240506151055863.png" alt="image-20240506151055863" style="zoom:50%;" />

上图就是Spring帮我们创建Bean的最最基础的过程



### Bean的解析流程

在使用 Spring 时，Bean 从哪里来应该是我们最先要了解的问题，下图很好的展示了 Bean 的创建过程。

![image-20240506142213309](C:\Users\周逸凡\AppData\Roaming\Typora\typora-user-images\image-20240506142213309.png)

如图所示，就是通过 **解析器**，对我们的 XML 文件或注解进行解析，最后将这些信息封装在 BeanDefinition 类中，并通过 BeanDefinitionRegistry 接口将这些信息 **注册** 起来，放在 beanDefinitionMap 变量中,

其中，beanDefinitionMap 中 key 为 beanName value 为 BeanDefinition。

#### BeanDefinition

BeanDefinition 就是描述和定义在 Spring 容器中的 Bean 的**元数据对象**，它包含了定义 Bean 的相关信息，例如 Bean 的类名、作用域、生命周期等。

BeanDefinition 对象通常由 Spring 容器在启动过程中根据配置信息或注解生成。是 Sping Ioc 容器管理的**核心数据结构之一**，用于保存 Bean 的配置和属性。

<img src="C:\Users\周逸凡\AppData\Roaming\Typora\typora-user-images\image-20240506144121685.png" alt="image-20240506144121685" style="zoom:50%;" />

> 此图只是BeanDefinition中一部分方法，详情请查看源码

如上图中，BeanDefinition 中包含了大量的 get、set 方法，可以获取到 Bean 的大量信息，以下列举部分重要的方法：

- get/setBeanClassName()

  获取/设置Bean的类名

- get/setScope()

  获取/设置Bean的作用域

- isSingleton() / isPrototype()

  判断是否单例/原型作用域

- get/setInitMethodName()

  获取/设置初始化方法名

- get/setDestroyMethodName()

  获取/设置销毁方法名

- get/setLazyInit()

  获取/设置是否延迟初始化

- get/setDependsOn()

  获取/设置依赖的Bean

- get/setPropertyValues()

  获取/设置属性值

- get/setAutowireCandidate()

  获取/设置是否可以自动装配

- get/setPrimary()

  获取/设置是否首选的自动装配Bean

总的来说，BeanDefinition中包含了Bean的大量元信息。但是，根据 Bean 不同的来源和方式，又会有许多不同种类的 BeanDefinition，首当其冲的就是 AbstractBeanDefinition，他是一个具体的 BeanDefinition 的基类，并分化出了 RootBeanDefinition、GenericBeanDefinition 和 ChildBeanDefinition

> 注：被@Component、@Bean标注过的类都会被解析成 BeanDefinition



#### BeanFactory

BeanFactory 本质就是 Spring 容器，也可以说是 IOC 容器的根接口。它可以从配置元数据（如XML文件等）中读取 Bean 的定义，并在需要时实例化和提供这些 Bean。

BeanDefinition 有了，接下来就是使用 BeanFactory 来创建 Bean 对象了。

而为了创建 Bean 对象，当然就需要使用反射了，刚好在 BeanDefinition 中保存了 BeanClass 这个属性，通过反射加上 BeanClass ，就可以很轻易地实例化一个 Bean 对象出来。

了解了大致过程，接下来就介绍以下 BeanFactory 中的一些方法：

<img src="C:\Users\周逸凡\AppData\Roaming\Typora\typora-user-images\image-20240506152242840.png" alt="image-20240506152242840" style="zoom:50%;" />

上图中最引人注目并且最主要的就是一系列的 getBean 方法，以及还有一些 **类型获取** 、**是否单例** 等方法。

而实现该接口的子接口也有很多

<img src="C:\Users\周逸凡\AppData\Roaming\Typora\typora-user-images\image-20240506153121496.png" alt="image-20240506153121496" style="zoom: 67%;" />

其中大部分的接口都是见名知意的

- ListableBeanFactory

  遍历 Bean

- HierarchicalBeanFactory

  提供 父子关系，可以获取上一级的 BeanFactory

- ConfigurableBeanFactory

  实现了 SingletonBeanRegistry ，主要是单例 Bean 的注册，生成

- AutowireCapableBeanFactory

  和自动装配有关

- AbstractBeanFactory

  单例缓存，以及 FactoryBean 相关的

- ConfigurableListableBeanFactory

  预实例化单例 Bean，分析，修改 BeanDefinition

- AbstractAutowireCapableBeanFactory

  创建 Bean ，属性注入，实例化，调用初始化方法 等等

- DefaultListableBeanFactory

  支持单例 Bean ，Bean 别名 ，父子 BeanFactory，Bean 类型转化 ，Bean 后置处理，FactoryBean，自动装配等



#### FactoryBean

FactoryBean 是 Spring 提供的一种特殊的 Bean，使用它可以生成某些需要复杂初始化过程的 Bean 对象。

与 BeanFactory 不同， FactoryBean 本质是一个 Bean 实例，即一个工厂 Bean。而 BeanFactory 是一个Bean 工厂，上文介绍过，他的作用就是实例化 Bean 对象。

FactoryBean 算是一个小工厂，因为它本质上是一个 Bean，所以他还是归 BeanFactory 这个工厂管理。

![image-20240506162607085](C:\Users\周逸凡\AppData\Roaming\Typora\typora-user-images\image-20240506162607085.png)

可以看到，FactoryBean中只有三个方法

- getObject()
- getObjectType()
- isSingleton()

经过上述描述，可能还是对 FactoryBean 很模糊，但也有了一些基本的概念，下面将更详细说明。

当配置的某个 Bean 实现了 FactoryBean 接口时，该 Bean返回的对象就不是 FactoryBean 本身，而是 FactoryBean 接口中的 getObject() 方法的返回值。这就提供了一种扩展的可能，即我们可以实现 FactoryBean 接口并重写 getObject() 方法，然后在里面自定义 Bean 的创建逻辑。

FactoryBean 与其他 Bean 的主要区别在于，FactoryBean 负责生产其他 Bean实例，而不是他本身。即我们从 IOC 容器中获取一个 FactoryBean 时，我们得到的是 FactoryBean 创建的那个 Bean 的实例，而不是 FactoryBean 的实例本身。

而在 BeanFactory 中有

```java
String FACTORY_BEAN_PREFIX = "&";
```

这样一个属性，他的作用就是标识该 Bean 是不是 FactoryBena ，即 beanName 是正常的对象，而 "&" + beanName 则是实现了 FactoryBean 的工厂对象

<img src="C:\Users\周逸凡\AppData\Roaming\Typora\typora-user-images\image-20240506170621795.png" alt="image-20240506170621795" style="zoom:50%;" />



#### ApplicationContext

ApplicationContext（应用程序上下文）是 Spring 中一个极其重要的接口，是为应用程序提供配置的中央接口。

![image-20240506170840391](C:\Users\周逸凡\AppData\Roaming\Typora\typora-user-images\image-20240506170840391.png)

通过它实现的接口可以看出，它扩展了许多功能，除了 BeanFactory 之外，它还可以创建、获取 Bean，以及处理国际化、事件、获取资源等。

下面介绍一下上图中它实现的接口以扩展的功能：

- EnvironmentCapable

  ![image-20240506171410225](C:\Users\周逸凡\AppData\Roaming\Typora\typora-user-images\image-20240506171410225.png)

  获取环境变量，可以获取到 **操作系统变量** 和 **JVM环境变量**。

- ListableBeanFactory

  该接口实现了 BeanFactory 接口，可以枚举所有 bean 实例。也可以判断某个 BeanName 是否存在 BeanDefinition 对象、获取 BeanDefinition 的数量、根据类型匹配对应的 Bean 等
  
  ![image-20240506235022936](C:\Users\周逸凡\AppData\Roaming\Typora\typora-user-images\image-20240506235022936.png)
  
- HierarchicalBeanFactory

  继承了 BeanFactory，可以获取父 BeanFactory、判断某个 name 是否存在对应的 Bean。

  ![image-20240506235441278](C:\Users\周逸凡\AppData\Roaming\Typora\typora-user-images\image-20240506235441278.png)

- MessageSource

  国际化功能

- ApplicationEventPublisher

  封装事件发布功能的接口

- ResourcePatternResolver

  加载、获取资源

除了ApplicationContext之外，还有ClassPathXmlApplication、AnnotationConfigApplicationContext、FileSystemXmlApplicationContext 这三个重要的类。



### IOC容器

IOC 控制反转，即将本来需要我们管理的 Bean 交给 IOC 容器帮助我们管理，在我们需要时调用即可。

当然，既然是 IOC 容器，不可能只有控制反转，肯定还有容器，比如容器的根接口就是 BeanFactory

除此之外，还有无处不在的后置处理器，即 xxxPostProcessor，可以在各个过程中合理利用这些后置处理器来修改 Bean 的信息



#### BeanFactory 后置处理器

在 BeanFactory 源码中，它介绍了 BeanDefinition 是为了描述一个 Bean 实例，并且他是一个最小的接口，目的是允许 BeanFactoryPostProcessor 修改属性和其他 Bean 元数据

![image-20240507001734406](C:\Users\周逸凡\AppData\Roaming\Typora\typora-user-images\image-20240507001734406.png)

通过 BeanFactoryPostProcessor ，可以在实例化对象之前，对 BeanDefinition 进行修改、冻结、预实例化单例 Bean等。

除此之外，还有 BeanDefinitionRegistryPostProcessor ，它实现了 BeanFactoryPostProcessor 接口，是对标准 BeanFactoryPostProcessor SPI 的扩展，允许在常规 BeanFactoryPostProcessor 检测开始之前注册更多的 bean 定义。通过 BeanDefinitionRegistryPostProcessor ，我们可以通过 BeanDefinitionRegistry 接口去新增、删除、获取 BeanDefinition

大致过程如下图：

![image-20240507002925249](C:\Users\周逸凡\AppData\Roaming\Typora\typora-user-images\image-20240507002925249.png)

上述只是一些简略过程，并不是整个的生产 Bean 的详细过程，本文只简略说明。

经过上述大致过程后，Bean 成功被初始化，之后就是一系列 Bean 的生命周期。



#### Bean 的生命周期

在 BeanFactory 中，详细列出了 Bean 初始化之后的一系列生命周期，共有14个：

![image-20240507003450018](C:\Users\周逸凡\AppData\Roaming\Typora\typora-user-images\image-20240507003450018.png)

整理之后如下图：

![image-20240507003627063](C:\Users\周逸凡\AppData\Roaming\Typora\typora-user-images\image-20240507003627063.png)

前面8个生命周期都是 xxxAware，而这些都实现了 Aware 接口，Aware 接口中没有任何方法，该接口是一个标记接口，它指示 Spring容器可以通过回调式方法来通知一个 Bean。

在这些 xxxAware中，都存在 setxxx() 方法，它的作用就是来设置这个 Aware 的前缀xxx，例如事件发布器，实现了 ApplicationEventPublisherAware 这个接口后，就可以设置 ApplicationEventPublisher。

在实例化和初始化的流程中，加上 Bean 后置处理器 BeanPostProcessor 后，就能得到下图过程：

![image-20240507004515687](C:\Users\周逸凡\AppData\Roaming\Typora\typora-user-images\image-20240507004515687.png)
