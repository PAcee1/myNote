## 简介

本文通过学习田小波的博客，进行总结记录，方便以后自己复习巩固。

这篇文章分析了SpringIOC中`BeanFactory`的`getBean(String)`方法的实现细节。

## 源码分析

在本章的开始，也就是2.1节，会先分析`getBean(String)`方法的整体实现逻辑，对其调用的方法会在后续章节进行分析。

### 俯瞰getBean(String)源码

本章先从整体看一下`getBean`方法的实现步骤，代码如下：

```java
public Object getBean(String name) throws BeansException {
    // getBean 是一个空壳方法，所有的逻辑都封装在 doGetBean 方法中
    return doGetBean(name, null, null, false);
}

protected <T> T doGetBean(
        final String name, final Class<T> requiredType, final Object[] args, boolean typeCheckOnly)
        throws BeansException {

    /*
     * 通过 name 获取 beanName。这里不使用 name 直接作为 beanName 有两点原因：
     * 1. name 可能会以 & 字符开头，表明调用者想获取 FactoryBean 本身，而非 FactoryBean 
     *    实现类所创建的 bean。在 BeanFactory 中，FactoryBean 的实现类和其他的 bean 存储
     *    方式是一致的，即 <beanName, bean>，beanName 中是没有 & 这个字符的。所以我们需要
     *    将 name 的首字符 & 移除，这样才能从缓存里取到 FactoryBean 实例。
     * 2. 若 name 是一个别名，则应将别名转换为具体的实例名，也就是 beanName。
     */
    final String beanName = transformedBeanName(name);
    Object bean;

    /*
     * 从缓存中获取单例 bean。Spring 是使用 Map 作为 beanName 和 bean 实例的缓存的，所以这
     * 里暂时可以把 getSingleton(beanName) 等价于 beanMap.get(beanName)。当然，实际的
     * 逻辑并非如此简单，后面再细说。
     */
    Object sharedInstance = getSingleton(beanName);

    /*
     * 如果 sharedInstance = null，则说明缓存里没有对应的实例，表明这个实例还没创建。
     * BeanFactory 并不会在一开始就将所有的单例 bean 实例化好，而是在调用 getBean 获取 
     * bean 时再实例化，也就是懒加载。
     * getBean 方法有很多重载，比如 getBean(String name, Object... args)，我们在首次获取
     * 某个 bean 时，可以传入用于初始化 bean 的参数数组（args），BeanFactory 会根据这些参数
     * 去匹配合适的构造方法构造 bean 实例。当然，如果单例 bean 早已创建好，这里的 args 就没有
     * 用了，BeanFactory 不会多次实例化单例 bean。
     */
    if (sharedInstance != null && args == null) {
        if (logger.isDebugEnabled()) {
            if (isSingletonCurrentlyInCreation(beanName)) {
                logger.debug("...");
            }
            else {
                logger.debug("...");
            }
        }
      
        /*
         * 如果 sharedInstance 是普通的单例 bean，下面的方法会直接返回。但如果 
         * sharedInstance 是 FactoryBean 类型的，则需调用 getObject 工厂方法获取真正的 
         * bean 实例。如果用户想获取 FactoryBean 本身，这里也不会做特别的处理，直接返回
         * 即可。毕竟 FactoryBean 的实现类本身也是一种 bean，只不过具有一点特殊的功能而已。
         */
        bean = getObjectForBeanInstance(sharedInstance, name, beanName, null);
    }
    /*
     * 如果上面的条件不满足，则表明 sharedInstance 可能为空，此时 beanName 对应的 bean 
     * 实例可能还未创建。这里还存在另一种可能，如果当前容器有父容器，beanName 对应的 bean 实例
     * 可能是在父容器中被创建了，所以在创建实例前，需要先去父容器里检查一下。
     */
    else {
        // BeanFactory 不缓存 Prototype 类型的 bean，无法处理该类型 bean 的循环依赖问题
        if (isPrototypeCurrentlyInCreation(beanName)) {
            throw new BeanCurrentlyInCreationException(beanName);
        }

        // 如果 sharedInstance = null，则到父容器中查找 bean 实例
        BeanFactory parentBeanFactory = getParentBeanFactory();
        if (parentBeanFactory != null && !containsBeanDefinition(beanName)) {
            // 获取 name 对应的 beanName，如果 name 是以 & 字符开头，则返回 & + beanName
            String nameToLookup = originalBeanName(name);
            // 根据 args 是否为空，以决定调用父容器哪个方法获取 bean
            if (args != null) {
                return (T) parentBeanFactory.getBean(nameToLookup, args);
            } 
            else {
                return parentBeanFactory.getBean(nameToLookup, requiredType);
            }
        }

        if (!typeCheckOnly) {
            markBeanAsCreated(beanName);
        }

        try {
            // 合并父 BeanDefinition 与子 BeanDefinition，后面会单独分析这个方法
            final RootBeanDefinition mbd = getMergedLocalBeanDefinition(beanName);
            checkMergedBeanDefinition(mbd, beanName, args);

            // 检查是否有 dependsOn 依赖，如果有则先初始化所依赖的 bean
            String[] dependsOn = mbd.getDependsOn();
            if (dependsOn != null) {
                for (String dep : dependsOn) {
                    /*
                     * 检测是否存在 depends-on 循环依赖，若存在则抛异常。比如 A 依赖 B，
                     * B 又依赖 A，他们的配置如下：
                     *   <bean id="beanA" class="BeanA" depends-on="beanB">
                     *   <bean id="beanB" class="BeanB" depends-on="beanA">
                     *   
                     * beanA 要求 beanB 在其之前被创建，但 beanB 又要求 beanA 先于它
                     * 创建。这个时候形成了循环，对于 depends-on 循环，Spring 会直接
                     * 抛出异常
                     */
                    if (isDependent(beanName, dep)) {
                        throw new BeanCreationException(mbd.getResourceDescription(), 														  beanName,"...");
                    }
                    // 注册依赖记录
                    registerDependentBean(dep, beanName);
                    try {
                        // 加载 depends-on 依赖
                        getBean(dep);
                    } 
                    catch (NoSuchBeanDefinitionException ex) {
                        throw new BeanCreationException(mbd.getResourceDescription(), 														  beanName,"...");
                    }
                }
            }

            // 创建 bean 实例
            if (mbd.isSingleton()) {
                /*
                 * 这里并没有直接调用 createBean 方法创建 bean 实例，而是通过 
                 * getSingleton(String, ObjectFactory) 方法获取 bean 实例。
                 * getSingleton(String, ObjectFactory) 方法会在内部调用 
                 * ObjectFactory 的 getObject() 方法创建 bean，并会在创建完成后，
                 * 将 bean 放入缓存中。关于 getSingleton 方法的分析，本文先不展开，我会在
                 * 后面的文章中进行分析
                 */
                sharedInstance = getSingleton(beanName, new ObjectFactory<Object>() {
                    @Override
                    public Object getObject() throws BeansException {
                        try {
                            // 创建 bean 实例
                            return createBean(beanName, mbd, args);
                        }
                        catch (BeansException ex) {
                            destroySingleton(beanName);
                            throw ex;
                        }
                    }
                });
                // 如果 bean 是 FactoryBean 类型，则调用工厂方法获取真正的 bean 实例。否则直接返回 bean 实例
                bean = getObjectForBeanInstance(sharedInstance, name, beanName, mbd);
            }

            // 创建 prototype 类型的 bean 实例
            else if (mbd.isPrototype()) {
                Object prototypeInstance = null;
                try {
                    beforePrototypeCreation(beanName);
                    prototypeInstance = createBean(beanName, mbd, args);
                }
                finally {
                    afterPrototypeCreation(beanName);
                }
                bean = getObjectForBeanInstance(prototypeInstance, name, beanName, mbd);
            }

            // 创建其他类型的 bean 实例
            else {
                String scopeName = mbd.getScope();
                final Scope scope = this.scopes.get(scopeName);
                if (scope == null) {
                    throw new IllegalStateException("No Scope registered ...");
                }
                try {
                    Object scopedInstance = scope.get(beanName, new ObjectFactory<Object>() {
                        @Override
                        public Object getObject() throws BeansException {
                            beforePrototypeCreation(beanName);
                            try {
                                return createBean(beanName, mbd, args);
                            }
                            finally {
                                afterPrototypeCreation(beanName);
                            }
                        }
                    });
                    bean = getObjectForBeanInstance(scopedInstance, name, beanName, mbd);
                }
                catch (IllegalStateException ex) {
                    throw new BeanCreationException(beanName,"...",ex);
                }
            }
        }
        catch (BeansException ex) {
            cleanupAfterBeanCreationFailure(beanName);
            throw ex;
        }
    }

    // 如果需要进行类型转换，则在此处进行转换。类型转换这一块我没细看，就不多说了。
    if (requiredType != null && bean != null && !requiredType.isInstance(bean)) {
        try {
            return getTypeConverter().convertIfNecessary(bean, requiredType);
        }
        catch (TypeMismatchException ex) {
            if (logger.isDebugEnabled()) {
                logger.debug("Failed to convert bean...");
            }
            throw new BeanNotOfRequiredTypeException(name, requiredType, bean.getClass());
        }
    }

    // 返回 bean
    return (T) bean;
}
```

这里的代码一些log或者throw的异常信息都做了省略，看完了源码，下面我来简单总结一下 `doGetBean()` 的执行流程。如下：

1. 将name转换为beanName
2. 从缓存中获取实例
3. 如果实例不为空且args为null，调用`getObjectForBeanInstance`方法，并按 name 规则返回相应的 bean 实例
4. 如果不满足上面条件，到父容器查询是否存在beanName的实例对象，有则返回
5. 如果没有，需要进行下一步操作——合并BeanDefinition
6. 处理depends-on依赖，如果有循环依赖抛出异常，如果有依赖的bean先`getBean(beanName)`
7. 根据Bean属性创建Bean（Singleton、prototype或其他），并缓存到map中
8. 调用 `getObjectForBeanInstance` 方法，并按 name 规则返回相应的 bean 实例
9. 按需转换Bean类型，并返回

以上流程对应的流程图：

![getBean流程图](https://blog-pictures.oss-cn-shanghai.aliyuncs.com/15277442845278.jpg)

上面代码中有几个重要的方法，我们在接下来详细分析下：

#### 重要的方法

`transformedBeanName(String name)`：转换BeanName

`getSingleton(String beanName)`：从缓存中获取bean

`getMergedLocalBeanDefinition(String beanName)`：合并父子BeanDefinition

`getObjectForBeanInstance`：获取Bean实例，主要针对FactoryBean与普通Bean的处理

### 转换BeanName

转换BeanName的方法为`transformedBeanName(String name)`，主要是针对**name带了&符号的**，进行去掉，或者**设置了alias别名**的，进行转换，以防止`BeanFactory`找不到name对应的bean实例。

```java
protected String transformedBeanName(String name) {
    // 这里调用了两个方法：BeanFactoryUtils.transformedBeanName(name) 和 canonicalName
    // 第一个先处理&符号，然后再寻找别名
    return canonicalName(BeanFactoryUtils.transformedBeanName(name));
}

/** 该方法用于处理 & 字符 */
public static String transformedBeanName(String name) {
    Assert.notNull(name, "'name' must not be null");
    String beanName = name;
    // 循环处理 & 字符。比如 name = "&&&&&helloService"，最终会被转成 helloService
    while (beanName.startsWith(BeanFactory.FACTORY_BEAN_PREFIX)) {
        beanName = beanName.substring(BeanFactory.FACTORY_BEAN_PREFIX.length());
    }
    return beanName;
}

/** 该方法用于转换别名 */
public String canonicalName(String name) {
    String canonicalName = name;
    String resolvedName;
    /*
     * 这里使用 while 循环进行处理，原因是：可能会存在多重别名的问题，即别名指向别名。比如下面
     * 的配置：
     *   <bean id="hello" class="service.Hello"/>
     *   <alias name="hello" alias="aliasA"/>
     *   <alias name="aliasA" alias="aliasB"/>
     *
     * 上面的别名指向关系为 aliasB -> aliasA -> hello，对于上面的别名配置，aliasMap 中数据
     * 视图为：aliasMap = [<aliasB, aliasA>, <aliasA, hello>]。通过下面的循环解析别名
     * aliasB 最终指向的 beanName
     */
    do {
        resolvedName = this.aliasMap.get(canonicalName);
        if (resolvedName != null) {
                canonicalName = resolvedName;
        }
    }
    while (resolvedName != null);
    return canonicalName;
}
```

### 从缓存中获取单例bean

对于单例bean，spring容器只会实例化一次，所以直接去缓存中取便可。

**这里关键的是需要处理循环依赖的问题！**

```java
public Object getSingleton(String beanName) {
    return getSingleton(beanName, true);
}

/**
 * 这里解释一下 allowEarlyReference 参数，allowEarlyReference 表示是否允许其他 bean 引用
 * 正在创建中的 bean，用于处理循环引用的问题。关于循环引用，这里先简单介绍一下。先看下面的配置：
 *
 *   <bean id="hello" class="xyz.coolblog.service.Hello">
 *       <property name="world" ref="world"/>
 *   </bean>
 *   <bean id="world" class="xyz.coolblog.service.World">
 *       <property name="hello" ref="hello"/>
 *   </bean>
 * 
 * 如上所示，hello 依赖 world，world 又依赖于 hello，他们之间形成了循环依赖。Spring 在构建 
 * hello 这个 bean 时，会检测到它依赖于 world，于是先去实例化 world。实例化 world 时，发现 
 * world 依赖 hello。这个时候容器又要去初始化 hello。由于 hello 已经在初始化进程中了，为了让 
 * world 能完成初始化，这里先让 world 引用正在初始化中的 hello。world 初始化完成后，hello 
 * 就可引用到 world 实例，这样 hello 也就能完成初始了。关于循环依赖，我后面会专门写一篇文章讲
 * 解，这里先说这么多。
 */
protected Object getSingleton(String beanName, boolean allowEarlyReference) {
    // 从 singletonObjects 获取实例，singletonObjects 中缓存的实例都是完全实例化好的 bean，可以直接使用
    Object singletonObject = this.singletonObjects.get(beanName);
    /*
     * 如果 singletonObject = null，表明还没创建，或者还没完全创建好。
     * 这里判断 beanName 对应的 bean 是否正在创建中
     */
    if (singletonObject == null && isSingletonCurrentlyInCreation(beanName)) {
        synchronized (this.singletonObjects) {
            // 从 earlySingletonObjects 中获取提前曝光的 bean，用于处理循环引用
            singletonObject = this.earlySingletonObjects.get(beanName);
            // 如果如果 singletonObject = null，且允许提前曝光 bean 实例，则从相应的 ObjectFactory 获取一个原始的（raw）bean（尚未填充属性）
            if (singletonObject == null && allowEarlyReference) {
                // 获取相应的工厂类
                ObjectFactory<?> singletonFactory = this.singletonFactories.get(beanName);
                if (singletonFactory != null) {
                    // 提前曝光 bean 实例，用于解决循环依赖
                    singletonObject = singletonFactory.getObject();
                    // 放入缓存中，如果还有其他 bean 依赖当前 bean，其他 bean 可以直接从 earlySingletonObjects 取结果
                    this.earlySingletonObjects.put(beanName, singletonObject);
                    this.singletonFactories.remove(beanName);
                }
            }
        }
    }
    return (singletonObject != NULL_OBJECT ? singletonObject : null);
}
```

这里介绍一下使用到的缓存：

| 缓存                  | 用途                                                         |
| --------------------- | ------------------------------------------------------------ |
| singletonObjects      | 用于存放完全初始化好的 bean，从该缓存中取出的 bean 可以直接使用 |
| earlySingletonObjects | 用于存放还在初始化中的 bean，用于解决循环依赖                |
| singletonFactories    | 用于存放 bean 工厂。bean 工厂所产生的 bean 是还未完成初始化的 bean。如代码所示，bean 工厂所生成的对象最终会被缓存到 earlySingletonObjects 中 |

循环依赖其实就是当A需要依赖B的实例，B又需要依赖A时，产生类似死锁的情景，这时可以让A先引用初始化中的B，这样A便可以完初始化，B依赖于的A初始化完成，B便也可以完成初始化了。

后面还会细讲循环依赖

### 合并父子BeanDefinition

Spring 支持配置继承，在标签中可以使用`parent`属性配置父类 bean。这样子类 bean 可以继承父类 bean 的配置信息，同时也可覆盖父类中的配置。比如下面的配置：

```xml
<bean id="hello" class="xyz.coolblog.innerbean.Hello">
    <property name="content" value="hello"/>
</bean>

<bean id="hello-child" parent="hello">
    <property name="content" value="I`m hello-child"/>
</bean>
```

这时在获取Bean实例之前就需要合并父子BeanDefinition，当然如果没有父bean便无需合并直接缓存，来看一下源码：

```java
protected RootBeanDefinition getMergedLocalBeanDefinition(String beanName) throws BeansException {
    // 检查缓存中是否存在“已合并的 BeanDefinition”，若有直接返回即可
    RootBeanDefinition mbd = this.mergedBeanDefinitions.get(beanName);
    if (mbd != null) {
        return mbd;
    }
    // 调用重载方法
    return getMergedBeanDefinition(beanName, getBeanDefinition(beanName));
}

protected RootBeanDefinition getMergedBeanDefinition(String beanName, BeanDefinition bd)
        throws BeanDefinitionStoreException {
    // 继续调用重载方法
    return getMergedBeanDefinition(beanName, bd, null);
}

protected RootBeanDefinition getMergedBeanDefinition(
        String beanName, BeanDefinition bd, BeanDefinition containingBd)
        throws BeanDefinitionStoreException {

    synchronized (this.mergedBeanDefinitions) {
        RootBeanDefinition mbd = null;

        // 我暂时还没去详细了解 containingBd 的用途，尽管从方法的注释上可以知道 containingBd 的大致用途，但没经过详细分析，就不多说了。见谅
        if (containingBd == null) {
            mbd = this.mergedBeanDefinitions.get(beanName);
        }

        if (mbd == null) {
            // bd.getParentName() == null，表明无父配置，这时直接将当前的 BeanDefinition 升级为 RootBeanDefinition
            if (bd.getParentName() == null) {
                if (bd instanceof RootBeanDefinition) {
                    mbd = ((RootBeanDefinition) bd).cloneBeanDefinition();
                }
                else {
                    mbd = new RootBeanDefinition(bd);
                }
            }
            else { // 有父配置，需要合并
                BeanDefinition pbd;
                try {
                    String parentBeanName = transformedBeanName(bd.getParentName());
                    /*
                     * 判断父类 beanName 与子类 beanName 名称是否相同。若相同，则父类 bean 一定
                     * 在父容器中。原因也很简单，容器底层是用 Map 缓存 <beanName, bean> 键值对
                     * 的。同一个容器下，使用同一个 beanName 映射两个 bean 实例显然是不合适的。
                     * 有的朋友可能会觉得可以这样存储：<beanName, [bean1, bean2]> ，似乎解决了
                     * 一对多的问题。但是也有问题，调用 getName(beanName) 时，到底返回哪个 bean 
                     * 实例好呢？
                     */
                    if (!beanName.equals(parentBeanName)) {
                        /*
                         * 这里再次调用 getMergedBeanDefinition，只不过参数值变为了 
                         * parentBeanName，用于合并父 BeanDefinition 和爷爷辈的 
                         * BeanDefinition。如果爷爷辈的 BeanDefinition 仍有父 
                         * BeanDefinition，则继续合并
                         */
                        pbd = getMergedBeanDefinition(parentBeanName);
                    }
                    else {// 不是父类，进行父类查找
                        BeanFactory parent = getParentBeanFactory();
                        //判断，父容器的类型，若不是 ConfigurableBeanFactory 则判抛出异常
                        if (parent instanceof ConfigurableBeanFactory) {
                            // 继续查找父容器上级
                            pbd = ((ConfigurableBeanFactory) parent).getMergedBeanDefinition(parentBeanName);
                        }
                        else {
                            throw new NoSuchBeanDefinitionException(parentBeanName,
                                    "Parent name '" + parentBeanName + "' is equal to bean name '" + beanName +
                                    "': cannot be resolved without an AbstractBeanFactory parent");
                        }
                    }
                }
                catch (NoSuchBeanDefinitionException ex) {
                    throw new BeanDefinitionStoreException(bd.getResourceDescription(), beanName,
                            "Could not resolve parent bean definition '" + bd.getParentName() + "'", ex);
                }
                // 以父 BeanDefinition 的配置信息为蓝本创建 RootBeanDefinition，也就是“已合并的 BeanDefinition”
                mbd = new RootBeanDefinition(pbd);
                // 用子 BeanDefinition 中的属性覆盖父 BeanDefinition 中的属性
                mbd.overrideFrom(bd);
            }

            // 如果用户未配置 scope 属性，则默认将该属性配置为 singleton
            if (!StringUtils.hasLength(mbd.getScope())) {
                mbd.setScope(RootBeanDefinition.SCOPE_SINGLETON);
            }

            if (containingBd != null && !containingBd.isSingleton() && mbd.isSingleton()) {
                mbd.setScope(containingBd.getScope());
            }

            if (containingBd == null && isCacheBeanMetadata()) {
                // 缓存合并后的 BeanDefinition
                this.mergedBeanDefinitions.put(beanName, mbd);
            }
        }

        return mbd;
    }
}
```



### 获取Bean实例

`getObjectForBeanInstance()`主要用于对FactoryBean这种特殊Bean的处理，如果是普通Bean会直接返回。

```java
protected Object getObjectForBeanInstance(
        Object beanInstance, String name, String beanName, RootBeanDefinition mbd) {

    // 如果 name 以 & 开头，但 beanInstance 却不是 FactoryBean，则认为有问题。
    if (BeanFactoryUtils.isFactoryDereference(name) && !(beanInstance instanceof FactoryBean)) {
        throw new BeanIsNotAFactoryException(transformedBeanName(name), beanInstance.getClass());
    }

    /* 
     * 如果上面的判断通过了，表明 beanInstance 可能是一个普通的 bean，也可能是一个 
     * FactoryBean。如果是一个普通的 bean，这里直接返回 beanInstance 即可。如果是 
     * FactoryBean，则要调用工厂方法生成一个 bean 实例。
     */
    if (!(beanInstance instanceof FactoryBean) || BeanFactoryUtils.isFactoryDereference(name)) {
        return beanInstance;
    }

    Object object = null;
    if (mbd == null) {
        /*
         * 如果 mbd 为空，则从缓存中加载 bean。FactoryBean 生成的单例 bean 会被缓存
         * 在 factoryBeanObjectCache 集合中，不用每次都创建
         */
        object = getCachedObjectForFactoryBean(beanName);
    }
    if (object == null) {
        // 经过前面的判断，到这里可以保证 beanInstance 是 FactoryBean 类型的，所以可以进行类型转换
        FactoryBean<?> factory = (FactoryBean<?>) beanInstance;
        // 如果 mbd 为空，则判断是否存在名字为 beanName 的 BeanDefinition
        if (mbd == null && containsBeanDefinition(beanName)) {
            // 合并 BeanDefinition
            mbd = getMergedLocalBeanDefinition(beanName);
        }
        // synthetic 字面意思是"合成的"。通过全局查找，我发现在 AOP 相关的类中会将该属性设为 true。
        // 所以我觉得该字段可能表示某个 bean 是不是被 AOP 增强过，也就是 AOP 基于原始类合成了一个新的代理类。
        // 不过目前只是猜测，没有深究。如果有朋友知道这个字段的具体意义，还望不吝赐教
        boolean synthetic = (mbd != null && mbd.isSynthetic());

        // 调用 getObjectFromFactoryBean 方法继续获取实例
        object = getObjectFromFactoryBean(factory, beanName, !synthetic);
    }
    return object;
}

protected Object getObjectFromFactoryBean(FactoryBean<?> factory, String beanName, boolean shouldPostProcess) {
    /*
     * FactoryBean 也有单例和非单例之分，针对不同类型的 FactoryBean，这里有两种处理方式：
     *   1. 单例 FactoryBean 生成的 bean 实例也认为是单例类型。需放入缓存中，供后续重复使用
     *   2. 非单例 FactoryBean 生成的 bean 实例则不会被放入缓存中，每次都会创建新的实例
     */
    if (factory.isSingleton() && containsSingleton(beanName)) {
        synchronized (getSingletonMutex()) {
            // 从缓存中取 bean 实例，避免多次创建 bean 实例
            Object object = this.factoryBeanObjectCache.get(beanName);
            if (object == null) {
                // 使用工厂对象中创建实例
                object = doGetObjectFromFactoryBean(factory, beanName);
                Object alreadyThere = this.factoryBeanObjectCache.get(beanName);
                if (alreadyThere != null) {
                    object = alreadyThere;
                }
                else {
                    // shouldPostProcess 等价于上一个方法中的 !synthetic，用于表示是否应用后置处理
                    if (object != null && shouldPostProcess) {
                        if (isSingletonCurrentlyInCreation(beanName)) {
                            return object;
                        }
                        beforeSingletonCreation(beanName);
                        try {
                            // 应用后置处理
                            object = postProcessObjectFromFactoryBean(object, beanName);
                        }
                        catch (Throwable ex) {
                            throw new BeanCreationException(beanName,
                                    "Post-processing of FactoryBean's singleton object failed", ex);
                        }
                        finally {
                            afterSingletonCreation(beanName);
                        }
                    }
                    // 这里的 beanName 对应于 FactoryBean 的实现类， FactoryBean 的实现类也会被实例化，并被缓存在 singletonObjects 中
                    if (containsSingleton(beanName)) {
                        // FactoryBean 所创建的实例会被缓存在 factoryBeanObjectCache 中，供后续调用使用
                        this.factoryBeanObjectCache.put(beanName, (object != null ? object : NULL_OBJECT));
                    }
                }
            }
            return (object != NULL_OBJECT ? object : null);
        }
    }
    // 获取非单例实例
    else {
        // 从工厂类中获取实例
        Object object = doGetObjectFromFactoryBean(factory, beanName);
        if (object != null && shouldPostProcess) {
            try {
                // 应用后置处理
                object = postProcessObjectFromFactoryBean(object, beanName);
            }
            catch (Throwable ex) {
                throw new BeanCreationException(beanName, "Post-processing of FactoryBean's object failed", ex);
            }
        }
        return object;
    }
}

private Object doGetObjectFromFactoryBean(final FactoryBean<?> factory, final String beanName)
        throws BeanCreationException {

    Object object;
    try {
        // if 分支的逻辑是 Java 安全方面的代码，可以忽略，直接看 else 分支的代码
        if (System.getSecurityManager() != null) {
            AccessControlContext acc = getAccessControlContext();
            try {
                object = AccessController.doPrivileged(new PrivilegedExceptionAction<Object>() {
                    @Override
                    public Object run() throws Exception {
                            return factory.getObject();
                        }
                    }, acc);
            }
            catch (PrivilegedActionException pae) {
                throw pae.getException();
            }
        }
        else {
            // 调用工厂方法生成 bean 实例
            object = factory.getObject();
        }
    }
    catch (FactoryBeanNotInitializedException ex) {
        throw new BeanCurrentlyInCreationException(beanName, ex.toString());
    }
    catch (Throwable ex) {
        throw new BeanCreationException(beanName, "FactoryBean threw exception on object creation", ex);
    }

    if (object == null && isSingletonCurrentlyInCreation(beanName)) {
        throw new BeanCurrentlyInCreationException(
                beanName, "FactoryBean which is currently in creation returned null from getObject");
    }
    return object;
}
```

看了上面的代码，我们来总结一下步骤：

1. 检测`beanInstance`的类型，如果不是`FactoryBean`直接返回
2. 检测`FactoryBean`是单例还是非单例，做出不同处理
3. 单例情况下，从缓存中取出bean，如果为null，进行创建
4. 创建完判断是否有后置方法，如果有则调用，最后缓存到`factoryBeanObjectCache`中
5. 非单例，直接创建新的实例，并进行后置方法判断，有则调用，最后缓存到`factoryBeanObjectCache`中



## 总结

到此，SpringIOC获取单例Bean方面的分析就结束了，主要是从`getBean()`方法来看，因为这是外部调用获取单例的方法，然后再从`getBean`中所调用的方法进行查看，比如比较重要的`transformedBeanName`、 `getSingleton`、 `getMergedLocalBeanDefinition` 、`getObjectForBeanInstance`方法，并进行详细介绍。

由2.1`getBean`代码可以看到在缓存中没有bean时，需要调用`createBean`方法创建bean，我们在下一个笔记里详细讲一下这个方法。