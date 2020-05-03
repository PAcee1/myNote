## 系统初始化器

### 如何自定义实现系统初始化器？

- Factories工厂配置、SpringApplication添加、环境配置application.properties

### 系统初始化器加载调用时机？

- Factories工厂配置——SpringBoot初始化时加载
- SpringApplication添加——SpringBoot初始化后手动加载
- 环境配置application.properties——SpringBoot.run()，调用DelegateApplicationContextInitializer时加载调用

### 自定义实现系统初始化器有哪些注意事项？

- 在环境配置中，对于Order排序会失效，会在其他自定义加载之前，因为DelegateApplicationContextInitializer的优先级最高，在此初始化器加载调用时，就会调用环境配置中的

## 事件监听机制

### 介绍下SpringBoot监听器模式

### SpringBoot常见的监听器

- FileEncodingApplicationListener 》ApplicationEnvironmentPreparedEvent：环境准备完毕后，对文件编码
- AnsiOutputApplicationListener 》ApplicationEnvironmentPreparedEvent：控制台彩色输出日志
- ConfigFileApplicationListener 》ApplicationEnvironmentPreparedEvent || ApplicationPreparedEvent：读取配置文件的监听器
- DelegatingApplicationListener 》 ApplicationEvent：用来广播事件给配置在application中的监听器

### SpringBoot框架有哪些事件以及执行顺序

### 监听器的触发机制是什么？

- 发布事件 - 寻找所有监听器 - 循环找到当前事件绑定的监听器集合 - 通过supportsEvent()方法判断 - 返回集合 - 循环执行监听器方法

### 如何自定义实现监听器

### 实现ApplicationListener和SmartApplicationListener接口区别

## Bean解析

### 介绍一下IOC思想

### springboot中bean有哪几种配置方式

- 注解：
  - @Component、@Bean
  - FactoryBean<T>
  - BeanDefinitionRegistryPostProcessor
  - ImportBeanDefinitionRegistrar

### 介绍下refresh流程

### 详细介绍refresh中你比较熟悉的一个方法

### 介绍下bean实例化流程

### 说几个bean实例化的扩展点与作用

- InstantiationAwareBeanPostProcessor
  - postProcessBeforeInstantiation()：可以用来创建代理实例
  - postProcessorsAfterInstantiation()：对代理实例进行依赖注入，属性设置

## Banner

### Banner常见的配置方式

### 简述下框架中Banner打印流程

### Banner的获取原理

### Banner的打印原理

### 你常用的Banner属性有哪些

## 定时器与启动器

### SpringBoot定时器实现你了解吗

### 让你去实现一个定时器，有什么思路

### 怎么实现在SpringBoot启动后立即执行程序

### 启动加载器实现方式

### 启动加载器实现有什么差异点

### 启动加载器的调用时机

## 属性配置

### SpringBoot属性配置的方式

### SpringBoot中Environment对象如何加载到容器中

### 某个属性集如spring_application_json是何时被加载的

### 介绍下SpringProfile

### SpringProfile使用时注意事项，为什么？

- default属性不能配在application.properties中
- default属性与active互斥

### SpringProfile的加载流程

## SpringBoot异常处理

### 介绍下SpringBoot异常处理器类结构

- SpringBootExceptionReporter：顶层异常处理实现接口
  - FailureAnalyzers
    - FailureAnalyzer -》 AbstractFailureAnalyzer：有大量实际异常处理器实现
    -  FailureAnalysisReporter  -》  LoggingFailureAnalysisReporter 
-  ExitCodeExceptionMapper ：退出状态码设置接口

### 介绍下SpringBoot异常处理器实现原理

### 介绍下SpringBoot异常处理流程

### SpringBoot异常处理流程中有哪些需要注意的

- 在handleExitCode中，如果退出状态码为0，就不会进行一些事件发布等处理
  - 这里需要自定义实现ExitCodeExceptionMapper接口，针对异常进行退出码的设置

- listener.failed发布事件不一定会执行，listener必须初始化才可以执行
- 也不一定每次都会移出Shutdown钩子方法，比如实现了才会

### 如果自定义实现SpringBoot异常处理器

## SpringBoot配置类

### 配置类是什么？有哪些作用

@Configuration等注解标志的类为配置类

主要作用是替代传统开发方式中的配置文件

### 配置类常用的注解有哪些

### SpringBoot中配置类何时配加载的

run -> refreshContext() -> invokeBeanFactoryPostProcessor -> ConfigurationClassPostProcessor -> processConfigBeanDefinitions()

### SpringBoot配置类的处理流程

### 配置类处理包括哪些内容

八大类

### 详细说一些注解的处理流程，比如@Import

- @Import分为三种情况
- ImportSelector & DeferredImportSelector # selectImports，获取String数组，存放类全限定类名，会判断此类是否为配置类
- ImportBeanDefinitionRegistrar，此方法中会向容器注册Bean，实际代码会获取注册的Bean，加载判断
- @Import，属性中的类名判断是否为配置类，进行加载