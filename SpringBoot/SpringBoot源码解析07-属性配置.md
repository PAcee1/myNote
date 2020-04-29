## SpringBoot属性配置方式

SpringBoot提供了17种属性配置方式，有以下这些

1. Devtools全局配置
2. 测试环境@TestPropertySource注解
3. 测试环境properties属性
4. 命令行参数
5. SPRING_APPLICATION_JSON属性
6. ServletConfig初始化参数
7. ServletContext初始化参数
8. JDNI属性
9. JAVA系统属性
10. 操作系统环境变量
11. RandomValuePropertySource随机值属性
12. jar包外的application-{profile}.properties属性
13. jar包内的application-{profile}.properties属性
14. jar包外的application.properties属性
15. jar包内的application.properties属性
16. @PropertySource绑定属性
17. 默认属性

属性从上到下，优先级从高到低

属性很多，有的常用有的不常用，下面我们挑几个常用的进行测试

## 属性配置实战

我们从低到高进行实战，只选择一些常用的，不常用的了解即可

为了测试，我们需要使用上一节学到的启动加载器，在SpringBoot启动后，打印属性，属性使用`prop_test`

```java
@Component
@Order(1)
public class PropApplicationRunner implements ApplicationRunner {

    @Autowired
    private Environment environment;

    @Override
    public void run(ApplicationArguments args) throws Exception {
        System.out.println(environment.getProperty("prop_test"));
    }
}
```

### 默认属性

需要实例化SpringApplication，然后设置默认属性

```java
@SpringBootApplication
public class MainApplication {

    public static void main(String[] args) {
        SpringApplication springApplication = new SpringApplication(MainApplication.class);
        Properties properties = new Properties();
        properties.setProperty("prop_test","prop_1");
        springApplication.setDefaultProperties(properties);
        springApplication.run(args);
    }
}
```

![1588151579621](image/1588151579621.png)

### @PropertySource绑定属性

创建一个demo.properties

```properties
prop_test=prop_2
```

然后再主程序类添加注解绑定属性

```java
@SpringBootApplication
@PropertySource("demo.properties")
public class MainApplication {
```

![1588152085661](image/1588152085661.png)

成功替换第一个，说明优先级更高

### application

application配置方式是最常用的方式，分为Properties和yml两种方式，properties会比yml优先级更高，还有就是外部application会比内部优先级高，对于这个内外部就不演示了

创建`application.yml`

```yml
prop_test: prop_3
```

![1588152231469](image/1588152231469.png)

创建`application.properties`

```properties
prop_test=prop_4
```

![1588152263402](image/1588152263402.png)

### application-{profile}

这种是多环境配置，我们后面会了解到，Spring Profile默认profile=default

所以我们创建`application-default.properties`，这里就不测试yml形式了，和之前是一样的

```properties
prop_test=prop_5
```

![1588152358588](image/1588152358588.png)

### 命令行参数

命令行参数就是在启动时添加的参数，对于idea可以这样设置

![1588152409030](image/1588152409030.png)

对于java启动，可以设置为`java -jar --prop_test=prop_6 xxx.jar`

![1588152445349](image/1588152445349.png)