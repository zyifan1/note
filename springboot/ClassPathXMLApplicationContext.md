### ClassPathXmlApplicationContext

独立的XML应用程序上下文，从类路径中获取上下文定义文件，将普通路径解释为包含包路径的类路径资源名称（例如“mypackage/ myresource. txt”）。对于测试工具以及 JAR 中嵌入的应用程序上下文很有用。
配置位置默认值可以通过getConfigLocations覆盖，配置位置可以表示具体文件，如“/ myfiles/ context. xml”或 Ant 风格模式，如“/ myfiles/*-context. xml”（请参阅org. springframework. util. AntPathMatcher javadoc 了解模式详细信息）。
注意：如果有多个配置位置，后面的 bean 定义将覆盖早期加载的文件中定义的 bean。可以利用这一点通过额外的 XML 文件故意覆盖某些 bean 定义。
这是一个简单、一站式、方便的 ApplicationContext。考虑将GenericApplicationContext类与org. springframework. beans. factory. xml. XmlBeanDefinitionReader结合使用，以获得更灵活的上下文设置



- 该类中都是一些构造方法，用以获取ClassPathXmlApplicationContext对象

  其中一个构造方法如下：

  ```java
  public ClassPathXmlApplicationContext(
  			String[] configLocations, boolean refresh, @Nullable ApplicationContext parent)
  			throws BeansException {
  
  		super(parent);
  		setConfigLocations(configLocations);
  		if (refresh) {
  			refresh();
  		}
  	}
  ```

  其中setConfigLocations用以根据提供的路径，处理成配置文件数组(以分号、逗号、空格、tab、换行符分割)

  ```java
  public void setConfigLocations(@Nullable String... locations) {
  		if (locations != null) {
  			Assert.noNullElements(locations, "Config locations must not be null");
  			this.configLocations = new String[locations.length];
  			for (int i = 0; i < locations.length; i++) {
  				this.configLocations[i] = resolvePath(locations[i]).trim();
  			}
  		}
  		else {
  			this.configLocations = null;
  		}
  	}
  ```

  在这段构造函数中，最重要的就是refresh()，ApplicationContext 建立起来以后，其实我们是可以通过调用 refresh() 这个方法重建的，refresh() 会将原来的 ApplicationContext 销毁，然后再重新执行一次初始化操作。

  ```java
  public void refresh() throws BeansException, IllegalStateException {
      	//上锁，防止在applicationcontext销毁或重新创建过程中，再次执行该过程
  		this.startupShutdownLock.lock();
  		try {
  			this.startupShutdownThread = Thread.currentThread();
  
  			StartupStep contextRefresh = this.applicationStartup.start("spring.context.refresh");
  
  			// Prepare this context for refreshing.
              //准备工作，记录下容器的启动时间、标记“已启动”状态、处理配置文件中的占位符
  			prepareRefresh();
  
  			// Tell the subclass to refresh the internal bean factory.
              // 这步比较关键，这步完成后，配置文件就会解析成一个个 Bean 定义，注册到BeanFactory 中，
        		// 当然，这里说的 Bean 还没有初始化，只是配置信息都提取出来了，
        		// 注册也只是将这些信息都保存到了注册中心(说到底核心是一个 beanName->beanDefinition 的 map)
  			ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();
  
  			// Prepare the bean factory for use in this context.
              // 设置 BeanFactory 的类加载器，添加几个 BeanPostProcessor，手动注册几个特殊的 bean
  			prepareBeanFactory(beanFactory);
  
  			try {
                  // 【这里需要知道 BeanFactoryPostProcessor 这个知识点，Bean 如果实现了此接口，那么在容器初始化以后，Spring 会负责调用里面的 postProcessBeanFactory 方法。】
                  
                  
  				// Allows post-processing of the bean factory in context subclasses.
                  // 这里是提供给子类的扩展点，到这里的时候，所有的 Bean 都加载、注册完成了，但是都还没有初始化
           		// 具体的子类可以在这步的时候添加一些特殊的 BeanFactoryPostProcessor 的实现类或做点什么事
  				postProcessBeanFactory(beanFactory);
  
  				StartupStep beanPostProcess = this.applicationStartup.start("spring.context.beans.post-process");
  				// Invoke factory processors registered as beans in the context.
  				invokeBeanFactoryPostProcessors(beanFactory);
  				// Register bean processors that intercept bean creation.
  				registerBeanPostProcessors(beanFactory);
  				beanPostProcess.end();
  
  				// Initialize message source for this context.
  				initMessageSource();
  
  				// Initialize event multicaster for this context.
  				initApplicationEventMulticaster();
  
  				// Initialize other special beans in specific context subclasses.
  				onRefresh();
  
  				// Check for listener beans and register them.
  				registerListeners();
  
  				// Instantiate all remaining (non-lazy-init) singletons.
  				finishBeanFactoryInitialization(beanFactory);
  
  				// Last step: publish corresponding event.
  				finishRefresh();
  			}
  
  			catch (RuntimeException | Error ex ) {
  				if (logger.isWarnEnabled()) {
  					logger.warn("Exception encountered during context initialization - " +
  							"cancelling refresh attempt: " + ex);
  				}
  
  				// Destroy already created singletons to avoid dangling resources.
  				destroyBeans();
  
  				// Reset 'active' flag.
  				cancelRefresh(ex);
  
  				// Propagate exception to caller.
  				throw ex;
  			}
  
  			finally {
  				contextRefresh.end();
  			}
  		}
  		finally {
  			this.startupShutdownThread = null;
  			this.startupShutdownLock.unlock();
  		}
  	}
  ```

  

