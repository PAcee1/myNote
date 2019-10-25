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

![1571822073253](../image/1571822073253.png)

可以看到maven库里已经有这个静态文件了，根据源码可知，访问路径为`/webjars/**`的会去`classpath:/META-INF/resources/webjars/`下找，我们测试下访问`jquery.js`

![1571822229943](../image/1571822229943.png)

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

![1571822631492](../image/1571822631492.png)

就会发现其实获取的路径是我们上面说的静态资源存放的路径

![1571822705334](../image/1571822774762.png)

我们测试一下：访问/asserts/js/Chart.min.js

![成功访问](../image/1571823047885.png)

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

![1571823872402](../image/1571823872402.png)

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

![1571824040913](../image/1571824040913.png)

## 二、模板引擎

模板引擎有很多，例如JSP，veloctiy，freemark，thymeleaf，主要用来方便html数据绑定的

![1571829800725](../image/1571829800725.png)

springboot推荐使用thymeleaf当做html模板引擎

### 2.1.引入Thymeleaf

```xml
<properties>
    <java.version>1.8</java.version>
    <thymeleaf.version>3.0.9.RELEASE</thymeleaf.version>
    <!-- 布局功能的支持程序  thymeleaf3主程序  layout2以上版本 -->
    <!-- thymeleaf2   layout1-->
	<thymeleaf-layout-dialect.version>2.2.2</thymeleaf-layout-dialect.version>
</properties>
    
<!--模板引擎模块-->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>
```

需要注意的是，springboot1.5.10版本默认使用thymeleaf2.x版本略低，所以改成了3.0.9版本，并使用layout2.x版本。

### 2.2.Thymeleaf的使用

```java
@ConfigurationProperties(prefix = "spring.thymeleaf")
public class ThymeleafProperties {

   private static final Charset DEFAULT_ENCODING = Charset.forName("UTF-8");

   private static final MimeType DEFAULT_CONTENT_TYPE = MimeType.valueOf("text/html");

   public static final String DEFAULT_PREFIX = "classpath:/templates/";

   public static final String DEFAULT_SUFFIX = ".html";
```

根据前面的学习，底层源码的研究，我们在自动配置类中找到Thymeleaf组件的ThymeleafProperties，会发现使用thymeleaf，只需在静态文件夹templates里放入html文件即可进行映射

1）编写一个html文件，放入到templates文件夹里

![1571832169357](../image/1571832169357.png)

2）写一个Controller类

```java
@Controller
public class HelloController {

    @RequestMapping("success")
    public String success(Map<String,Object> map){
        map.put("hello","你好，Thymeleaf");
        return "success";
    }
}
```

注意！要使用@Controller注解，而不是@RestController注解，这样才会返回给`classpath:/templates/success.html`

3）启动服务测试

![1571832490874](../image/1571832490874.png)

### 2.3.Thymeleaf的语法

语法可以查看文档第四章和第十章<https://www.thymeleaf.org/doc/tutorials/3.0/usingthymeleaf.pdf>

#### 语法：

![](../image/2018-02-04_123955.png)

#### 表达式

```properties
Simple expressions:（表达式语法）
    Variable Expressions: ${...}：获取变量值；OGNL；
    		1）、获取对象的属性、调用方法
    		2）、使用内置的基本对象：
    			#ctx : the context object.
    			#vars: the context variables.
                #locale : the context locale.
                #request : (only in Web Contexts) the HttpServletRequest object.
                #response : (only in Web Contexts) the HttpServletResponse object.
                #session : (only in Web Contexts) the HttpSession object.
                #servletContext : (only in Web Contexts) the ServletContext object.
                
                ${session.foo}
            3）、内置的一些工具对象：
#execInfo : information about the template being processed.
#messages : methods for obtaining externalized messages inside variables expressions, in the same way as they would be obtained using #{…} syntax.
#uris : methods for escaping parts of URLs/URIs
#conversions : methods for executing the configured conversion service (if any).
#dates : methods for java.util.Date objects: formatting, component extraction, etc.
#calendars : analogous to #dates , but for java.util.Calendar objects.
#numbers : methods for formatting numeric objects.
#strings : methods for String objects: contains, startsWith, prepending/appending, etc.
#objects : methods for objects in general.
#bools : methods for boolean evaluation.
#arrays : methods for arrays.
#lists : methods for lists.
#sets : methods for sets.
#maps : methods for maps.
#aggregates : methods for creating aggregates on arrays or collections.
#ids : methods for dealing with id attributes that might be repeated (for example, as a result of an iteration).

    Selection Variable Expressions: *{...}：选择表达式：和${}在功能上是一样；
    	补充：配合 th:object="${session.user}：
   <div th:object="${session.user}">
    <p>Name: <span th:text="*{firstName}">Sebastian</span>.</p>
    <p>Surname: <span th:text="*{lastName}">Pepper</span>.</p>
    <p>Nationality: <span th:text="*{nationality}">Saturn</span>.</p>
    </div>
    
    Message Expressions: #{...}：获取国际化内容
    Link URL Expressions: @{...}：定义URL；
    		@{/order/process(execId=${execId},execType='FAST')}
    Fragment Expressions: ~{...}：片段引用表达式
    		<div th:insert="~{commons :: main}">...</div>
    		
Literals（字面量）
      Text literals: 'one text' , 'Another one!' ,…
      Number literals: 0 , 34 , 3.0 , 12.3 ,…
      Boolean literals: true , false
      Null literal: null
      Literal tokens: one , sometext , main ,…
Text operations:（文本操作）
    String concatenation: +
    Literal substitutions: |The name is ${name}|
Arithmetic operations:（数学运算）
    Binary operators: + , - , * , / , %
    Minus sign (unary operator): -
Boolean operations:（布尔运算）
    Binary operators: and , or
    Boolean negation (unary operator): ! , not
Comparisons and equality:（比较运算）
    Comparators: > , < , >= , <= ( gt , lt , ge , le )
    Equality operators: == , != ( eq , ne )
Conditional operators:条件运算（三元运算符）
    If-then: (if) ? (then)
    If-then-else: (if) ? (then) : (else)
    Default: (value) ?: (defaultvalue)
Special tokens:
    No-Operation: _ 
```

关于语法，可以简单看看，不需要硬记，使用的时候查询下，用得多了自然就记住了

## 三、SpringMVC自动配置

<https://docs.spring.io/spring-boot/docs/1.5.10.RELEASE/reference/htmlsingle/#boot-features-developing-web-applications>

查看Spring MVC auto-configuration官方文档

SpringBoot会自动配置SpringMVC：

以下是Springboot对SpringMvc的自动配置：**WebMVCAutoConfiguration**

### 3.1.视图解析器

> Inclusion of `ContentNegotiatingViewResolver` and `BeanNameViewResolver` beans.

自动配置了视图解析器

`ContentNegotiatingViewResolver`:组合所有存在的视图解析器，并选择一个最适合的进行视图的解析转发。通过下面源码可知，视图解析器的组合是从容器中获取所有实现了ViewResolve的类，再进行选择

```java
@Override
public View resolveViewName(String viewName, Locale locale) throws Exception {
  ···
      List<View> candidateViews = getCandidateViews(viewName, locale, requestedMediaTypes);
      View bestView = getBestView(candidateViews, requestedMediaTypes, attrs);
  ···
}

protected void initServletContext(ServletContext servletContext) {
Collection<ViewResolver> matchingBeans =
				BeanFactoryUtils.beansOfTypeIncludingAncestors(getApplicationContext(), ViewResolver.class).values();
}
```

自定义：在容器中添加一个视图解析器，便会自动组合进`ContentNegotiatingViewResolver`

 ```java
  @SpringBootApplication
  public class Springboot04WebApplication {
  
      public static void main(String[] args) {
          SpringApplication.run(Springboot04WebApplication.class, args);
      }
      
      @Bean
      public ViewResolver myViewResolver(){
          return new MyViewResolver();
      }
      
      public static class MyViewResolver implements ViewResolver{
      
          @Override
          public View resolveViewName(String viewName, Locale locale) throws Exception {
              return null;
          }
      }
  }
 ```

![1571886850216](../image/1571886850216.png)

成功组合进视图解析器

### 3.2.静态资源

> Support for serving static resources, including support for WebJars (see below).
>
> Static `index.html` support.
>
> Custom `Favicon` support (see below).

会自动配置SpringMVC的webjars index以及favicon，在上面已经详细说过了

### 3.3.格式化转换器

> Automatic registration of `Converter`, `GenericConverter`, `Formatter` beans.
>
> Springboot自动注册了 `Converter`, `GenericConverter`, `Formatter` 这些格式化转换器。

`Converter`，`GenericConverter`：类型转换器，比如将18转成Integer，true转成Boolean类型

```java
@Bean
@ConditionalOnProperty(prefix = "spring.mvc", name = "date-format")
public Formatter<Date> dateFormatter() {
   return new DateFormatter(this.mvcProperties.getDateFormat());
}
```

`Formatter`：格式化器，比如转换日期格式，2019-01-01 =》 date，比如上面的代码可知，可以在配置文件中配置想要的日期格式

```java
@Override
public void addFormatters(FormatterRegistry registry) {
   for (Converter<?, ?> converter : getBeansOfType(Converter.class)) {
      registry.addConverter(converter);
   }
   for (GenericConverter converter : getBeansOfType(GenericConverter.class)) {
      registry.addConverter(converter);
   }
   for (Formatter<?> formatter : getBeansOfType(Formatter.class)) {
      registry.addFormatter(formatter);
   }
}
```

**根据底层源码可知，这些格式化转换器也是从容器中取出的，所以我们也可以模仿视图解析器一样自定义一些格式转换器，通过向容器添加实现了接口的Bean类。**

### 3.4.请求响应转换

> Support for `HttpMessageConverters` (see below).

 `HttpMessageConverters`：这是SpringMVC用来转换请求响应的，比如把map或Bean转成json格式。

这个组件也像上面的一样是从容器中获取的，所以也可以自定义HttpMessageConverter进行自动添加

### 3.5.其他的一些

> Automatic registration of `MessageCodesResolver` (see below).
>
> Automatic use of a `ConfigurableWebBindingInitializer` bean (see below).

官方文档中还提到了错误代码生成规则`MessageCodesResolver` 以及数据绑定器`WebBindingInitializer`

也是一样可以配置一个自定义的来替换默认的

### 3.6.总结

SpringBoot对SpringMVC的一些必要的解析器转换器进行了默认配置，我们根据源码可知，这些组件都是从容器中获取的，所以我们可以自定义一些组件来替换默认的或添加。

1. 创建一个自定义组件，实现某个接口，比如ViewResolver接口，即自定义视图解析器
2. 编写代码，根据需求
3. 添加@Bean注解以及@Component添加到容器中

这样SpringBoot在初始化自动配置类时，会先看容器中有没有用户自定义的一些组件（@Bean，@Component），如果有就用用户配置的，如果没有再加载默认自带的。

## 四、扩展SpringMVC

在以前，使用xml配置时，可以使用springmvc.xml配置一下视图映射或者拦截器等：

```xml
 <mvc:view-controller path="/hello" view-name="success"/>
    <mvc:interceptors>
        <mvc:interceptor>
            <mvc:mapping path="/hello"/>
            <bean></bean>
        </mvc:interceptor>
    </mvc:interceptors>
```

那么，在使用SpringBoot之后，应该如何进行扩展呢？

> If you want to keep Spring Boot MVC features, and you just want to add additional [MVC configuration](https://docs.spring.io/spring/docs/4.3.14.RELEASE/spring-framework-reference/htmlsingle#mvc) (interceptors, formatters, view controllers etc.) you can add your own `@Configuration` class of type `WebMvcConfigurerAdapter`, but **without** `@EnableWebMvc`. If you wish to provide custom instances of `RequestMappingHandlerMapping`, `RequestMappingHandlerAdapter` or `ExceptionHandlerExceptionResolver` you can declare a `WebMvcRegistrationsAdapter` instance providing such components.
>
> If you want to take complete control of Spring MVC, you can add your own `@Configuration` annotated with `@EnableWebMvc`.

由官方文档可知：

1）编写一个带有**@Configuration**且继承了`WebMvcConfigurerAdapter`的扩展类，并不要添加**@EnableWebMvc**

```java
@Configuration
public class MyMvcConfig extends WebMvcConfigurerAdapter {
}
```

2）根据需要，重新`WebMvcConfigurerAdapter`中的方法，比如`addViewController()`

```java
@Override
public void addViewControllers(ViewControllerRegistry registry) {
    // super.addViewControllers(registry);
    registry.addViewController("/hello").setViewName("success");
}
```

![1571898132822](../image/1571898132822.png)

还有一种方式也是很常见的：

```java
@Configuration
public class MyMvcConfig{

    @Bean
    public WebMvcConfigurerAdapter webMvcConfigurerAdapter(){
        return new WebMvcConfigurerAdapter() {
            @Override
            public void addViewControllers(ViewControllerRegistry registry) {
                registry.addViewController("/").setViewName("login");
                registry.addViewController("/index.html").setViewName("login");
            }
        };
    }
}
```

这样可以在这个Config类中配置多个Configuration配置了

### 扩展原理

1）在`WebMvcAutoConfiguration`中有一个内部类`WebMvcAutoConfigurationAdapter`

```java
@Import(EnableWebMvcConfiguration.class)
@EnableConfigurationProperties({ WebMvcProperties.class, ResourceProperties.class })
public static class WebMvcAutoConfigurationAdapter extends WebMvcConfigurerAdapter {
```

他import了一个`EnableWebMvcConfiguration`，即启动mvc配置

2）查看`EnableWebMvcConfiguration`，会发现继承自`DelegatingWebMvcConfiguration`

```jav
@Configuration
public static class EnableWebMvcConfiguration extends DelegatingWebMvcConfiguration {
```

3）在这个类中可以发现一个`setConfigurers()`的方法，用来设置mvc的配置

```
@Configuration
public class DelegatingWebMvcConfiguration extends WebMvcConfigurationSupport {

   private final WebMvcConfigurerComposite configurers = new WebMvcConfigurerComposite();

   @Autowired(required = false)
   public void setConfigurers(List<WebMvcConfigurer> configurers) {
      if (!CollectionUtils.isEmpty(configurers)) {
         this.configurers.addWebMvcConfigurers(configurers);
      }
   }
```

4）进入`addWebMvcConfigurers()`，会发现是从容器中获取全部的`WebMvcConfigurer`，并一起生效

```java
public void addWebMvcConfigurers(List<WebMvcConfigurer> configurers) {
   if (!CollectionUtils.isEmpty(configurers)) {
      this.delegates.addAll(configurers);
   }
}
```

5）这样的话我们设置的配置类因为继承了`WebMvcConfigurerAdapter`，而这个父类又实现了`WebMvcConfigurer`，所以会被当做MVC的配置类之一加载生效，就如同SSM开发时的xml被读取到容器中生效一样。

### 关于@EnableWebMvc

为啥文档说扩展mvc不要添加这个注解呢？因为添加了这个注解便不是拓展，是全面接管了，SpringBoot对MVC进行的默认配置会全部失效。

比如上面说到的静态资源映射，对于"/"会自定映射index作为主页，我们试一下如果添加了@EnableWebMvc注解，还会不会映射index。

![1571899484251](../image/1571899484251.png)

发现报出404错误，说明Springboot的默认配置未生效。

源码分析：

1）先看下**@EnableWebMvc**

```java
@Import(DelegatingWebMvcConfiguration.class)
public @interface EnableWebMvc {
}
//public class DelegatingWebMvcConfiguration extends WebMvcConfigurationSupport {
```

会发现这个注解间接导入了`WebMvcConfigurationSupport`类

2）再看一下`WebMVCAutoConfiguration`的约束注解

```java
@Configuration
@ConditionalOnWebApplication
@ConditionalOnClass({ Servlet.class, DispatcherServlet.class,
      WebMvcConfigurerAdapter.class })
@ConditionalOnMissingBean(WebMvcConfigurationSupport.class)
@AutoConfigureOrder(Ordered.HIGHEST_PRECEDENCE + 10)
@AutoConfigureAfter({ DispatcherServletAutoConfiguration.class,
      ValidationAutoConfiguration.class })
public class WebMvcAutoConfiguration {
```

**@ConditionalOnMissingBean(WebMvcConfigurationSupport.class)**，会发现只有不存在`WebMvcConfigurationSupport`这个类，才会生效，而从第一步可知，因为添加**@EnableWebMvc**注解，导致**Import**了这个类，所以SpringBoot对Mvc的默认配置便不生效了

## 五、CRUD项目

**我们通过一个简单的crud项目，进一步学习理解SpringBoot的Web开发**

### 5.1.初始化

![1571902932684](../image/1571902932684.png)

对应的文件放入对应的位置

修改默认访问主页，改为login.html，通过扩展SpringMVC

```java
@Configuration
public class MyMvcConfig extends WebMvcConfigurerAdapter {
    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        // super.addViewControllers(registry);
        registry.addViewController("/").setViewName("login");
        registry.addViewController("/index.html").setViewName("login");
    }
}
```

### 5.2.国际化

1）创建配置文件

![1571905108447](../image/1571905108447.png)

2）在配置文件中配置

想要在配置文件中配置，可以百度搜下如何配置，也可以根据源码，我们看下源码，SpringBoot对于国际化也有一个自动配置类MessageSourceAutoConfiguration：

```java
@ConfigurationProperties(prefix = "spring.messages")
public class MessageSourceAutoConfiguration {
    
private String basename = "messages"; // 默认对源路径下文件名为messages进行国际化

@Bean
public MessageSource messageSource() {
   ResourceBundleMessageSource messageSource = new ResourceBundleMessageSource();
   if (StringUtils.hasText(this.basename)) {
      messageSource.setBasenames(StringUtils.commaDelimitedListToStringArray(
          // 设置国际化的文件名，所以我们应该要改成login
            StringUtils.trimAllWhitespace(this.basename)));
   }
   if (this.encoding != null) {
      messageSource.setDefaultEncoding(this.encoding.name());
   }
   messageSource.setFallbackToSystemLocale(this.fallbackToSystemLocale);
   messageSource.setCacheSeconds(this.cacheSeconds);
   messageSource.setAlwaysUseMessageFormat(this.alwaysUseMessageFormat);
   return messageSource;
}
```

application.properties:

```properties
spring.messages.basename=i18n.login
```

3）配置对应的html文件

```html
<form class="form-signin" action="dashboard.html">
   <img class="mb-4" th:src="@{/asserts/img/bootstrap-solid.svg}" src="asserts/img/bootstrap-solid.svg" alt="" width="72" height="72">
   <h1 class="h3 mb-3 font-weight-normal" th:text="#{login.tip}">Please sign in</h1>
   <label class="sr-only" >Username</label>
   <input type="text" class="form-control" placeholder="Username" th:placeholder="#{login.username}" required="" autofocus="">
   <label class="sr-only" >Password</label>
   <input type="password" class="form-control" placeholder="Password" th:placeholder="#{login.password}" required="">
   <div class="checkbox mb-3">
      <label>
        <input type="checkbox" value="remember-me">[[#{login.remember}]]
      </label>
   </div>
   <button class="btn btn-lg btn-primary btn-block" type="submit" th:text="#{login.btn}">Sign in</button>
   <p class="mt-5 mb-3 text-muted">© 2019-2020</p>
   <a class="btn btn-sm">中文</a>
   <a class="btn btn-sm">English</a>
</form>
```

4）测试查看

发现根据浏览器语言进行了国际化切换

#### 原理

在WebMVCAutoConfiguration中，具有一个区域信息解析器LocaleResolver，由他根据区域信息Locale进行一些操作。

```java
@Bean
@ConditionalOnMissingBean
@ConditionalOnProperty(prefix = "spring.mvc", name = "locale")
public LocaleResolver localeResolver() {
   if (this.mvcProperties
         .getLocaleResolver() == WebMvcProperties.LocaleResolver.FIXED) {
      return new FixedLocaleResolver(this.mvcProperties.getLocale());
   }
   AcceptHeaderLocaleResolver localeResolver = new AcceptHeaderLocaleResolver();
   localeResolver.setDefaultLocale(this.mvcProperties.getLocale());
   return localeResolver;
}
```

通过AcceptHeaderLocaleResolver中的resolveLocale()方法进行解析

```java
@Override
public Locale resolveLocale(HttpServletRequest request) {
   Locale defaultLocale = getDefaultLocale();
   if (defaultLocale != null && request.getHeader("Accept-Language") == null) {
      return defaultLocale;
   }
   Locale requestLocale = request.getLocale();
   if (isSupportedLocale(requestLocale)) {
      return requestLocale;
   }
   Locale supportedLocale = findSupportedLocale(request);
   if (supportedLocale != null) {
      return supportedLocale;
   }
   return (defaultLocale != null ? defaultLocale : requestLocale);
}
```

根据源码可知，是由浏览器请求的request中拿去请求头，来进行国际化切换

5）通过按钮实现国际化

我们了解到了原理，便可自定义一个区域信息解析器，来制作我们自定义的国际化标准。

1. 自定义解析器

```java
public class MyLocaleResolver implements LocaleResolver {
    @Override
    public Locale resolveLocale(HttpServletRequest request) {
        // 判断请求中是否有leg参数，有便按参数进行国际化
        String leg = request.getParameter("leg");
        Locale locale = Locale.getDefault(); // 默认为操作系统语言
        if(!StringUtils.isEmpty(leg)){
            String[] split = leg.split("_");
            locale = new Locale(split[0],split[1]);
        }
        return locale;
    }

    @Override
    public void setLocale(HttpServletRequest request, HttpServletResponse response, Locale locale) {

    }
}
```

2. 添加到容器中

```java
@Configuration
public class MyMvcConfig{

    @Bean
    public WebMvcConfigurerAdapter webMvcConfigurerAdapter(){
       ······
    }

    @Bean
    public LocaleResolver localeResolver(){
        return new MyLocaleResolver();
    }

}
```

3. 设置html对应按钮操作

```html
<a class="btn btn-sm" th:href="@{/index.html(leg='zh_CN')}">中文</a>
<a class="btn btn-sm" th:href="@{/index.html(leg='en_US')}">English</a>
```

4. 测试

![1571907672874](../image/1571907698378.png)

### 5.3.拦截器

我们写一下登录操作，表单提交到`/user/login`，简单判断下，注意，**为了防止转发后表单重复提交，应使用重定向**

```java
@Controller
public class LoginController {

    @PostMapping(value = "/user/login")
    public String login(@RequestParam String username,
                        @RequestParam String password,
                        Map<String,Object> map){
        if(!StringUtils.isEmpty(username) && password.equals("123456")){
            // 防止表单重复提交，重定向到主页
            return "redirect:/main.html";
        }
        map.put("msg","登录失败");
        return "login";
    }
}
```

```html
<form class="form-signin" action="dashboard.html" th:action="@{/user/login}" method="post">
```

```java
@Bean
public WebMvcConfigurerAdapter webMvcConfigurerAdapter(){
    return new WebMvcConfigurerAdapter() {
        @Override
        public void addViewControllers(ViewControllerRegistry registry) {
            registry.addViewController("/").setViewName("login");
            registry.addViewController("/index.html").setViewName("login");
            registry.addViewController("/main.html").setViewName("dashboard");
        }
    };
}
```

这时候我们发现，如果没有登录，直接请求`http://localhost:8080/crud/main.html`，也是成功的，所以就需要添加一个拦截器。

自定义拦截器和添加其他组件一样，写一个类实现HandlerInterceptor，然后重写方法，注册到容器中，因为这个是WebMVCAutoConfiguration中的组件，所以应在WebMvc自动配置中addInterceptor，代码如下：

1）新建一个拦截器类MyHandlerInterceptor

```java
// 实现HandlerInterceptor，即这是一个拦截器
public class MyHandlerInterceptor implements HandlerInterceptor {

    // 目标执行方法前，先进行判断
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        Object userName = (String) request.getSession().getAttribute("userName");
        if(userName == null){
            // 错误，返回登录页
            request.setAttribute("msg","请先登录");
            request.getRequestDispatcher("/index.html").forward(request,response);
            return false;
        }else {
            return true;
        }
    }
```

2）注册到容器中

```java
@Configuration
public class MyMvcConfig{

    @Bean
    public WebMvcConfigurerAdapter webMvcConfigurerAdapter(){
        return new WebMvcConfigurerAdapter() {
            @Override
            public void addViewControllers(ViewControllerRegistry registry) {
                registry.addViewController("/").setViewName("login");
                registry.addViewController("/index.html").setViewName("login");
                registry.addViewController("/main.html").setViewName("dashboard");
            }

            // 添加拦截器组件，属于WebMvc的一个组件
            @Override
            public void addInterceptors(InterceptorRegistry registry) {
                registry.addInterceptor(new MyHandlerInterceptor()).addPathPatterns("/**")
                            .excludePathPatterns("/index.html","/","/user/login");
            }
        };
    }

```

