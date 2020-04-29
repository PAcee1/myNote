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