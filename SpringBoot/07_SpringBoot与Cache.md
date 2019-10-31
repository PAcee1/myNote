## 一、Spring缓存抽象接口

Spring3.1之后定义了**两个缓存接口**，**CacheManager**和**Cache**来统一不同的缓存，并支持JCache注解简化开发。

- Cache接口为缓存组件的规范定义，包含了对缓存的各种操作集合，并提供了一系列的实现类，比如我们常用的RedisCache，EhCache。

- CacheManager接口是用来管理Cache组件的，一个CacheManager可以包含多个Cache，如包含RedisCache，EhCache，并对其进行管理

一些重要的注解：

- @Cacheable：针对方法配置，即根据请求参数对结果进行缓存。比如：查id为1的用户，结果便会被缓存，如果下次还查询1号用户，便不会调用方法，直接从缓存中返回数据
- @CacheEvict：清空缓存，比如：删除1号用户，便清空1号用户的缓存
- @CachePut：更新缓存，比如：修改了1号用户的手机号，便会更新1号用户的缓存。它与Cacheable的不同是这个方法总会被调用，Cacheable是如果缓存有就不调用方法了。
- @EnableCaching：开启缓存注解

一些重要的配置：

- keyGenerator：key缓存策略
- serialize：value序列化缓存策略

接下来我们就围绕这些概念进行展开，实际使用与底层原理

## 二、@Cacheable

我们在学习SpringBoot缓存前，先搭建好一套crud项目，这里就不过多介绍了

### 2.1.@Cacheable属性

`@Cacheable`这个注解，有很多属性：

- value/cacheName：指定缓存组件名称，支持多个缓存，{"emp","temp"}

- key：缓存数据使用的key，因为数据再缓存里也是键值对保存的，默认使用入参的值，比如id为1，其key就是1。这个key还支持spEL表达式，具体不介绍了，也可以使用#id，即id的值，#a0，#p0，也是参数的值
- keyGenerator：key生成器，和key属性选择一个使用
- cacheManager/cacheResolver：指定缓存管理器，如Redis等等
- condition：符合条件下才缓存，condition = "#id>0"
- unless：否定缓存，如果条件为true，便不会缓存，如：unless = ”#result = null“
- sync：异步

### 2.2.开发步骤

需要在主程序类上开启缓存注解`@EnableCaching`

```java
@MapperScan("com.enbuys.springboot.dao")
@SpringBootApplication
@EnableCaching
public class MainApplication {

    public static void main(String[] args) {
        SpringApplication.run(MainApplication.class,args);
    }
}
```

我们在getById上添加缓存开启注解，并指定缓存组件名为emp

```java
@Service
public class EmpService {

    @Autowired
    private EmployeeDao employeeDao;

    @Cacheable(value = "emp")
    public Employee getById(Integer id){
        return employeeDao.getById(id);
    }
}
```

第一次请求有SQL打印，说明正确请求数据库

![1572504930624](D:\1笔记\image\1572504930624.png)

第二次请求，便没有SQL打印了，说明走缓存了，没有请求数据库

![1572505284929](D:\1笔记\image\1572505284929.png)

### 2.3.注解原理

经过前面的学习，我们知道，想要看组件原理，首先找到他的自动配置类，即`CacheAutoConfiguration`

```java
@Import(CacheConfigurationImportSelector.class)
public class CacheAutoConfiguration {
```

在这个类上，重要的是导入了一个`CacheConfigurationImportSelector`，通过他我们可以找到使用了哪个配置类。

![1572507691897](D:\1笔记\image\1572507691897.png)

通过断点可以看到配置了11个配置类，默认使用的是`SimpleCacheConfiguration`

```java
@Bean
public ConcurrentMapCacheManager cacheManager() {
   ConcurrentMapCacheManager cacheManager = new ConcurrentMapCacheManager();
   List<String> cacheNames = this.cacheProperties.getCacheNames();
   if (!cacheNames.isEmpty()) {
      cacheManager.setCacheNames(cacheNames);
   }
   return this.customizerInvoker.customize(cacheManager);
}
```

在SimpleCacheConfiguration源码中可以看到，注册了一个CacheManager，来进行缓存管理，使用的是`ConcurrentMapCacheManager`

```java
private final ConcurrentMap<String, Cache> cacheMap = new ConcurrentHashMap<String, Cache>(16);

// 创建ConcurrentMapCache的Cache组件
protected Cache createConcurrentMapCache(String name) {
   SerializationDelegate actualSerialization = (isStoreByValue() ? this.serialization : null);
   return new ConcurrentMapCache(name, new ConcurrentHashMap<Object, Object>(256),
         isAllowNullValues(), actualSerialization);

}

// 获取Cache
@Override
public Cache getCache(String name) {
    Cache cache = this.cacheMap.get(name);
    if (cache == null && this.dynamic) {
        synchronized (this.cacheMap) {
            cache = this.cacheMap.get(name);
            if (cache == null) {
                cache = createConcurrentMapCache(name);
                this.cacheMap.put(name, cache);
            }
        }
    }
    return cache;
}
```

在其源码中，可以看到这个缓存管理使用**ConcurrentMap**进行存储Cache组件，并具有创建和获取`ConcurrentMapCache`功能。

通过Debug发现，**在执行我们上面写的getById()方法前**，会先执行`getCache`方法，判断是否存在`emp`名称的Cache，如果没有，进行创建，如果有，则返回这个Cache进行使用。

再进一步研究`ConcurrentMapCache`：

```java
private final ConcurrentMap<Object, Object> store;

@Override
protected Object lookup(Object key) {
    return this.store.get(key);
}

@Override
public void put(Object key, Object value) {
   this.store.put(key, toStoreValue(value));
}
```

1. 从CacheManager返回Cache后，会从map里get查找key是否存在
   - 这个key是通过keygenerator生成的
   - 如果没有参数，key = new SimpleGenerator()
   - 如果有一个参数，key = 参数值
   - 如果有多个参数，key = new SimpleGenerator(params)

2. 没有找到便执行目标方法
3. 然后将返回值保持到缓存map中

#### 核心

1. 使用缓存时，会根据判断使用哪个缓存配置类，默认`SimpleCacheConfiguration`
2. `cacheManager[ConcurrentMapCacheManager]`组件加载到容器中
3. 方法如果开启`@Cacheable`注解，执行前会根据`cacheName`获取`Cache[ConcurrentMapCache]`，如果没有创建
4. 根据key寻找缓存数据，key由`keyGenerator`来生成
5. 如果没有缓存数据，执行目标方法，并将返回值缓存
6. 如果有缓存数据，直接将数据返回，不再执行目标方法

## 三、@CachePut

这个注解我们前面说过，修改数据时使用，既调用方法又缓存数据。

1. 先向数据库保存更新的数据
2. 将返回的结果进行缓存

==需要注意的是，默认的key是方法入参，因为查询时使用的key是id，所以应该设置key为入参的id==

测试：

```java
@Cacheable(cacheNames = "emp")
public Employee getById(Integer id){
    return employeeDao.getById(id);
}


@CachePut(cacheNames = "emp")
public Employee update(Employee employee){
    employeeDao.update(employee);
    return employee;
}
```

1）先获取员工1的数据，将数据缓存

![1572512650233](D:\1笔记\image\1572512650233.png)

![1572512637952](D:\1笔记\image\1572512637952.png)

2）在执行修改方法，修改员工数据

![1572512754604](D:\1笔记\image\1572512754604.png)

![1572512768913](D:\1笔记\image\1572512768913.png)

成功执行update sql，修改了数据库中的数据

3）再获取员工1数据

![1572512799857](D:\1笔记\image\1572512799857.png)

![1572512806556](D:\1笔记\image\1572512806556.png)

再次请求1号员工，发现数据是修改后的数据，并且控制台没有请求数据库，说明成功缓存

## 四、@CacheEvict

删除缓存，也比较简单，将Cache中根据key删除

一些属性：

- allEntries：true or false，代表是否清除全部数据，如果选择，则清除emp中的全部数据
- beforeInvocation：默认false，即在方法执行之后进行缓存清除，这样可以避免异常导致删除操作没有执行成功，但缓存清除了。

```java
@CacheEvict(cacheNames = "emp")
public void deleteById(Integer id){
    System.out.println("delete emp id="+id);
    //employeeDao.delete(id);
}
```

测试：

1）请求获取员工1

![1572515371346](D:\1笔记\image\1572515371346.png)

2）删除员工1

![1572515395387](D:\1笔记\image\1572515395387.png)

![1572515407928](D:\1笔记\image\1572515407928.png)

成功执行

3）再次请求员工1，看看是否请求数据库

![1572515441131](D:\1笔记\image\1572515441131.png)

再次请求数据库，说明缓存被成功清除