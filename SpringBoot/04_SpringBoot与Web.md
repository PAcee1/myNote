**使用环境Springboot1.5.10，对于Springboot2.x来说，某些源码改动，例如1.3中设置主页的源码变动**

## 一、SpringBoot对静态资源映射

通过前面的学习，对于这种映射我们知道都需要去看底层的自动配置类，而静态资源属于Web数据，所以我们打开`WebMvcAutoConfiguration`查看

```java
@EnableConfigurationProperties({ WebMvcProperties.class, ResourceProperties.class })
@Order(0)
public static class WebMvcAutoConfigurationAdapter implements WebMvcConfigurer {
```

首先往下可以看到导入了一个`ResourceProperties`类，就是我们要找的资源配置类

```java
@ConfigurationProperties(prefix = "spring.resources", ignoreUnknownFields = false)
public class ResourceProperties {

   private static final String[] CLASSPATH_RESOURCE_LOCATIONS = { "classpath:/META-INF/resources/",
         "classpath:/resources/", "classpath:/static/", "classpath:/public/" };
```

可以设置与静态资源有关的参数，参数属性为`spring.resources`开头，然后可以看到我们静态资源存放路径：

```
"classpath:/META-INF/resources/",
"classpath:/resources/",
"classpath:/static/",
"classpath:/public/"
"/"：当前目录根路径
```

### 1.1.webjars

对于静态资源，我们可以使用springboot带的webjars来使用：http://www.webjars.org/

```java
@Override
public void addResourceHandlers(ResourceHandlerRegistry registry) {
   if (!this.resourceProperties.isAddMappings()) {
      logger.debug("Default resource handling disabled");
      return;
   }
   Duration cachePeriod = this.resourceProperties.getCache().getPeriod();
   CacheControl cacheControl = this.resourceProperties.getCache().getCachecontrol().toHttpCacheControl();
    // 对于/webjars/**的请求，会到classpath:/META-INF/resources/webjars/寻找静态文件
   if (!registry.hasMappingForPattern("/webjars/**")) {
      customizeResourceHandlerRegistration(registry.addResourceHandler("/webjars/**")
            .addResourceLocations("classpath:/META-INF/resources/webjars/")
            .setCachePeriod(getSeconds(cachePeriod)).setCacheControl(cacheControl));
   }
   String staticPathPattern = this.mvcProperties.getStaticPathPattern();
   if (!registry.hasMappingForPattern(staticPathPattern)) {
      customizeResourceHandlerRegistration(registry.addResourceHandler(staticPathPattern)
            .addResourceLocations(getResourceLocations(this.resourceProperties.getStaticLocations()))
            .setCachePeriod(getSeconds(cachePeriod)).setCacheControl(cacheControl));
   }
}
```

**使用方法**：

根据文档在pom文件引入需要的组件，比如jquery：

```xml
<dependency>
    <groupId>org.webjars</groupId>
    <artifactId>jquery</artifactId>
    <version>3.3.1</version>
</dependency>
```

![1571822073253](C:\Users\S1\AppData\Roaming\Typora\typora-user-images\1571822073253.png)

可以看到maven库里已经有这个静态文件了，根据源码可知，访问路径为`/webjars/**`的会去`classpath:/META-INF/resources/webjars/`下找，我们测试下访问`jquery.js`

![1571822229943](C:\Users\S1\AppData\Roaming\Typora\typora-user-images\1571822229943.png)

正确访问

### 1.2.任何资源

```java
private String staticPathPattern = "/**";

String staticPathPattern = this.mvcProperties.getStaticPathPattern();
if (!registry.hasMappingForPattern(staticPathPattern)) {
   customizeResourceHandlerRegistration(registry.addResourceHandler(staticPathPattern)
         .addResourceLocations(getResourceLocations(this.resourceProperties.getStaticLocations()))
         .setCachePeriod(getSeconds(cachePeriod)).setCacheControl(cacheControl));
}
```

根据源码可知，对于访问任何资源如"/**"，会去ResourceProperties寻找

```java
getResourceLocations(this.resourceProperties.getStaticLocations())
```

![1571822631492](C:\Users\S1\AppData\Roaming\Typora\typora-user-images\1571822631492.png)

就会发现其实获取的路径是我们上面说的静态资源存放的路径

![1571822705334](C:\Users\S1\AppData\Roaming\Typora\typora-user-images\1571822774762.png)

我们测试一下：访问/asserts/js/Chart.min.js

![成功访问](C:\Users\S1\AppData\Roaming\Typora\typora-user-images\1571823047885.png)

### 1.3.设置主页

在Springboot1.x时

```java
@Bean
public WelcomePageHandlerMapping welcomePageHandlerMapping(
    ResourceProperties resourceProperties) {
    return new WelcomePageHandlerMapping(resourceProperties.getWelcomePage(),
                                         this.mvcProperties.getStaticPathPattern());
}
```

可以根据源码得知，对于欢迎页面是先请求ResourceProperties的getWelcomePage方法

```java
private String[] getStaticWelcomePageLocations() {
    String[] result = new String[this.staticLocations.length];
    for (int i = 0; i < result.length; i++) {
        String location = this.staticLocations[i];
        if (!location.endsWith("/")) {
            location = location + "/";
        }
        result[i] = location + "index.html";
    }
    return result;
}
```

然后获取静态资源目录下是否存放index.html文件

![1571823872402](C:\Users\S1\AppData\Roaming\Typora\typora-user-images\1571823872402.png)

### 1.4.设置网址icon

```java
@Bean
public SimpleUrlHandlerMapping faviconHandlerMapping() {
   SimpleUrlHandlerMapping mapping = new SimpleUrlHandlerMapping();
   mapping.setOrder(Ordered.HIGHEST_PRECEDENCE + 1);
   mapping.setUrlMap(Collections.singletonMap("**/favicon.ico",
         faviconRequestHandler()));
   return mapping;
}
```

根据源码得知，在静态文件下存放favicon.ico命名的文件便自动配置为网站的icon

![1571824040913](C:\Users\S1\AppData\Roaming\Typora\typora-user-images\1571824040913.png)