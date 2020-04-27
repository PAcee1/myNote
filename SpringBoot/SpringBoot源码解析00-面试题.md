## 系统初始化器

### 如何自定义实现系统初始化器？

Factories工厂配置、SpringApplication添加、环境配置application.properties

### 系统初始化器加载调用时机？

Factories工厂配置——SpringBoot初始化时加载

SpringApplication添加——SpringBoot初始化后手动加载

环境配置application.properties——SpringBoot.run()，调用DelegateApplicationContextInitializer时加载调用

### 自定义实现系统初始化器有哪些注意事项？

在环境配置中，对于Order排序会失效，会在其他自定义加载之前，因为DelegateApplicationContextInitializer的优先级最高，在此初始化器加载调用时，就会调用环境配置中的



