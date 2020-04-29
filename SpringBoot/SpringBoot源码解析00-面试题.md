## 系统初始化器

**如何自定义实现系统初始化器？**

- Factories工厂配置、SpringApplication添加、环境配置application.properties

**系统初始化器加载调用时机？**

- Factories工厂配置——SpringBoot初始化时加载
- SpringApplication添加——SpringBoot初始化后手动加载
- 环境配置application.properties——SpringBoot.run()，调用DelegateApplicationContextInitializer时加载调用

**自定义实现系统初始化器有哪些注意事项？**

- 在环境配置中，对于Order排序会失效，会在其他自定义加载之前，因为DelegateApplicationContextInitializer的优先级最高，在此初始化器加载调用时，就会调用环境配置中的

## 事件监听机制

**介绍下SpringBoot监听器模式**

**SpringBoot常见的监听器**

- FileEncodingApplicationListener 》ApplicationEnvironmentPreparedEvent：环境准备完毕后，对文件编码
- AnsiOutputApplicationListener 》ApplicationEnvironmentPreparedEvent：控制台彩色输出日志
- ConfigFileApplicationListener 》ApplicationEnvironmentPreparedEvent || ApplicationPreparedEvent：读取配置文件的监听器
- DelegatingApplicationListener 》 ApplicationEvent：用来广播事件给配置在application中的监听器

**SpringBoot框架有哪些事件以及执行顺序**

**监听器的触发机制是什么？**

- 发布事件 - 寻找所有监听器 - 循环找到当前事件绑定的监听器集合 - 通过supportsEvent()方法判断 - 返回集合 - 循环执行监听器方法

**如何自定义实现监听器**

**实现ApplicationListener和SmartApplicationListener接口区别**

