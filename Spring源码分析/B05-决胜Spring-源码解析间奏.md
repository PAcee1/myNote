再进行Spring IOC流程解析前，我们需要对一些必要的类进行了解

## Bean

Bean我们太常见了，就是一个个的Java对象，那他和普通Java对象有什么不同呢？其实就是Bean是由Spring进行管理的。

## BeanDefinition

BeanDefinition是什么呢？看名字为Bean的定义，其实就是Bean在xml或者注解配置时，所添加的属性，都会被组装成一个个的BeanDefineition，放到容器中，以供后面使用。

常见的Bean定义属性有：

- lazy-init懒加载
- id
- class
- scope作用域
- 等等

## BeanFactory

BeanFactory是顶级的管理Bean的接口，为基类接口

其中getBean方法也是我们经常使用的方法，通过名称、类型或者构造函数来从容器中获取Bean

![1589897595008](image/1589897595008.png)

BeanFactory因为是顶级接口，所以肯定会派生出很多接口与实现类

比如ListableBeanFactory就可以获取List形式的Bean集合，以及AutowireCapableBeanFactory为注解形式的BeanFactory，HierarchicalBeanFactory中自定义方法最少，但也非常关键，因为它是重要容器ApplicationContext的父接口

接下来看看ApplicationContext

![1589898624283](image/1589898624283.png)

这里可以发现，ApplicationContext也有很多具体的实现，其中用到了很多设计模式

相对重要的是AbstractApplicationContext，其中最重要的方法`refresh()`，就是SpringIOC容器启动的方法

其中就用到了**模板方法模式**，refresh中有很多方法，有的是模板方法，所有子类实现公用的，有的是钩子方法，可实现可不实现，有的是抽象方法，必须由子类实现的

除了AbstractApplicationContext外，可以看到最下层具有几个常用的ApplicationContext

- ClassPathXmlApplicationContext
- FileSystemXmlApplicationContext
- XMLWebApplicationContext
- AnnotationConfigWebApplicationContext

前三个是加载xml配置文件的，最后一个是注解时使用的上下文