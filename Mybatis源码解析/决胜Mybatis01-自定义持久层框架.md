## JDBC中的问题

刚开始学Java的时候，我们连接数据库进行操作，全是通过JDBC实现的，那么为什么后面使用Mybatis或者Hibernate 等ORM框架呢？那么肯定是JDBC中有令人困扰的问题，然后被主流ORM框架优化。

### JDBC实现流程

首先我们回顾一下JDBC的实现流程

1. 加载数据库驱动
2. 建立连接
3. 编写sql语句，生成预处理对象
4. 执行sql，获取结果集
5. 解析结果集

```java
public static void main(String[] args) {
    Connection connection = null;
    PreparedStatement preparedStatement = null;
    ResultSet resultSet = null;
    try {
        // 加载数据库驱动
        Class.forName("com.mysql.jdbc.Driver");
        // 建立连接
        connection = DriverManager.getConnection("jdbc:mysql://localhost:3306/mybatis?characterEncoding=utf-8", "root", "root");
        // 编写sql语句
        String sql = "select * from user where username = ?";
        // 获取预处理statement
        preparedStatement = connection.prepareStatement(sql);
        // 设置查询条件
        preparedStatement.setString(1, "tom");
        // 执行sql，获取结果集
        resultSet = preparedStatement.executeQuery();
        // 处理结果集
        while (resultSet.next()) {
            int id = resultSet.getInt("id");
            String username = resultSet.getString("username");
            // 封装到user中
            user.setId(id);
            user.setUsername(username);
        }
        System.out.println(user);
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        // 释放资源
        ···
    }
}
```

### JDBC存在的问题

![1586524262121](image/1586524262121.png)

我们通过颜色划分，不难看出有以下几个缺点：

| 代码                                | 问题                                                         | 解决方案                                                     |
| ----------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 加载驱动，获取数据库连接            | 1.数据库配置文件硬编码 2.每次使用都需要创建释放数据库连接    | 1.使用配置文件保存数据库配置 2.使用数据库连接池              |
| 定义sql，设置参数，获取结果集中数据 | sql，参数，获取结果都存在硬编码                              | 使用配置文件（单独的配置文件，和数据库配置文件分开，因为这些是常变配置，而数据库配置不常变） |
| 遍历解析结果集                      | 需要手动封装结果集，如果实体对象字段过多，手动封装任务繁琐且都是重复操作 | 使用反射，将结果映射到实体中，比如`BeanUtils.mapToBean()`    |

## 自定义持久层框架实现思路

我们针对上面JDBC展现出的问题，思考下如何优化，制作出一个简单的ORM框架，以便后期更简单的理解Mybatis实现原理。

思考：

```
首先我们的框架应该是一个独立的工程，打成jar包供客户端调用
客户端使用我们jar时，应该需要传入一些配置，比如数据库连接配置，sql，参数，返回值等，所以这些应该放在配置文件中
我们的框架实现时，需要读取解析这些配置文件
为了代码的优雅，我们应保存到对象中（面向对象原则）
通过配置文件建立数据库连接，执行sql，返回结果
```

通过上面的思考后，我们有了以下具体设计思路

### 使用端

引入自定义持久层框架jar包，调用方法进行获取数据

- 需提供的配置：数据库配置信息，sql配置信息，入参，返回值类型
- 需创建两种配置文件
  - `sqlMapConfig.xml`：存放数据库配置信息（也可以添加`mapper.xml`的路径，这样只需要传递一个配置文件，就可以获取两种配置文件的配置）
  - `mapper.xml`：存放sql，入参，返回值的配置

### 自定义框架

本质是对JDBC代码实现进行优雅的封装

1. 加载配置文件：将配置文件中的信息转成字节流，保存到内存中以待使用
   - 创建`Resource`类，方法：`InputStream getResourceAsStream(String xmlPath)`
2. 创建JavaBean：面向对象编程，将配置信息保存到Bean中
   - `Configuration`：核心配置类，保存`sqlMapConfig.xml`中的配置
   - `MappedStatement`：映射配置类，保存`mapper.xml`中的配置
3. 解析流中的配置到JavaBean：使用`dom4j`技术
   - 创建解析类：`SqlSessionFactoryBuilder`，方法：`build(InputStream is)`
   - 第一，使用`dom4j`将流中配置，解析存放到对象容器中
   - 第二，创建`SqlSessionFactory`，用来创建`SqlSession`（会话），<font color="red">使用到工厂模式</font>
4. 创建SqlSessionFactory接口：工厂模式，用于生成`SqlSession`
   - 第一，创建`openSession()`方法：生成`SqlSession`
   - 第二，创建默认实现类，`DefaultSqlSessionFactory`，遵循开闭原则
5. 创建`SqlSession`接口：封装CRUD方法
   - 第一，创建默认对数据库操作的方法，入：`selectAll()`，`insert()`，`delete()`，`update()`
   - 第二，创建默认实现类`DefaultSqlSession`
6. 创建`Executor`接口：实际操作数据库的代码
   - 第一，创建实际操作数据库方法：`query(Configuration conf,Object... params)`
   - 第二，创建默认实现类`DefaultExecutor`