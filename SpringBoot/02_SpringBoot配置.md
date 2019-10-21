## 一、配置文件

Springboot不同于Spring，其配置文件有严格要求：

- application.properties
- application.yml(yaml)

只能是这两种才可以，名称固定。

一般来说Springboot在底层已经配置好，如果需要自己进行配置，便可以通过这个配置文件修改

例如：

```yaml
server:
  port: 8081
```

## 二、YAML语法

### 2.1.基本语法

yaml由键值对组成，k: v（注意冒号后要跟一个空格）

yaml对空格敏感，对于层级的控制也是由空格来判断的，空格对齐的数据是在一个层级

```yaml
server:
    port: 8081
    	test: 123
    path: /hello
    	name: haha
```

上面的例子，即port与path在一个层级，test与name在第三层级。

并且大小写敏感