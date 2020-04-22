## 从案例开始分析原始开发方式的问题

这里我们忘记Spring，看看以前Servlet是如何开发Web项目的，存在哪些问题，应该如何优化？

这里以银行转账为例子，具体代码后期会放到Github上

该例子也很简单，就是A向B转账，然后对数据库中的金额进行增减

![1587228227963](image/1587228227963.png)![1587228237648](image/1587228237648.png)

这里贴几个关键代码：

### Servlet层

```java
@WebServlet(name="transferServlet",urlPatterns = "/transferServlet")
public class TransferServlet extends HttpServlet {

    // 1. 实例化service层对象
    private TransferService transferService = new TransferServiceImpl();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        doPost(req,resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // 设置请求体的字符编码
        req.setCharacterEncoding("UTF-8");

        String fromCardNo = req.getParameter("fromCardNo");
        String toCardNo = req.getParameter("toCardNo");
        String moneyStr = req.getParameter("money");
        int money = Integer.parseInt(moneyStr);

        Result result = new Result();

        try {

            // 2. 调用service层方法
            transferService.transfer(fromCardNo,toCardNo,money);
            result.setStatus("200");
        } catch (Exception e) {
            e.printStackTrace();
            result.setStatus("201");
            result.setMessage(e.toString());
        }

        // 响应
        resp.setContentType("application/json;charset=utf-8");
        resp.getWriter().print(JsonUtils.object2Json(result));
    }
}
```

### Service层

```java
public interface TransferService {
    void transfer(String fromCardNo,String toCardNo,int money) throws Exception;
}

public class TransferServiceImpl implements TransferService {

    private AccountDao accountDao = new JdbcAccountDaoImpl();

    @Override
    public void transfer(String fromCardNo, String toCardNo, int money) throws Exception {
        Account from = accountDao.queryAccountByCardNo(fromCardNo);
        Account to = accountDao.queryAccountByCardNo(toCardNo);

        from.setMoney(from.getMoney()-money);
        to.setMoney(to.getMoney()+money);

        accountDao.updateAccountByCardNo(to);
        accountDao.updateAccountByCardNo(from);
    }
}
```

### Dao层

```java
public interface AccountDao {

    Account queryAccountByCardNo(String cardNo) throws Exception;

    int updateAccountByCardNo(Account account) throws Exception;
}

public class JdbcAccountDaoImpl implements AccountDao {

    @Override
    public Account queryAccountByCardNo(String cardNo) throws Exception {
        //从连接池获取连接
        Connection con = DruidUtils.getInstance().getConnection();
        String sql = "select * from account where cardNo=?";
        PreparedStatement preparedStatement = con.prepareStatement(sql);
        preparedStatement.setString(1,cardNo);
        ResultSet resultSet = preparedStatement.executeQuery();

        Account account = new Account();
        while(resultSet.next()) {
            account.setCardNo(resultSet.getString("cardNo"));
            account.setName(resultSet.getString("name"));
            account.setMoney(resultSet.getInt("money"));
        }

        resultSet.close();
        preparedStatement.close();
        con.close();

        return account;
    }

    @Override
    public int updateAccountByCardNo(Account account) throws Exception {

        // 从连接池获取连接
        Connection con = DruidUtils.getInstance().getConnection();
        String sql = "update account set money=? where cardNo=?";
        PreparedStatement preparedStatement = con.prepareStatement(sql);
        preparedStatement.setInt(1,account.getMoney());
        preparedStatement.setString(2,account.getCardNo());
        int i = preparedStatement.executeUpdate();

        preparedStatement.close();
        con.close();
        return i;
    }
}
```

### 问题分析

通过这些简单的代码实现，我们不难发现以下几个问题，如图所示：

![1587228307534](image/1587228307534.png)

## 原始开发方式解决思路

我们刚刚发现，原始开发方式有两个重点问题

- 一是new关键字将不同层级的类耦合在了一起
- 二是没有添加事务控制

### 实例化耦合解决思路

new关键字是用来实例化对象的，如果想要不适用new来实例化，那么还有什么实例化方式呢？那就是**反射技术**，使用`Class.forName("全限定类名")`来实现对象实例化。

使用反射会发现全限定类名也耦合到类中了，如果想解耦，关于这种配置的东西都可以放在配置文件里，所以我们可以创建`xml`文件来保存全限定类名。

但还存在一个问题，如果类有很多，那么每个类都需要使用反射创建对象，如果直接写在业务类中比如`ServiceImpl`，那么会有大量重复代码，所以我们可以**使用工厂模式**，让工厂使用反射生产对象，当我们业务类需要使用时，直接去工厂拿。

![1587563277473](image/1587563277473.png)

### 实例化解决方案代码实现

#### 创建配置文件

首先我们需要使用XML配置文件，来保存类的全限定类名

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!--跟标签beans，里面配置一个又一个的bean子标签，每一个bean子标签都代表一个类的配置-->
<beans>
    <!--id标识对象，class是类的全限定类名-->
    <bean id="accountDao" class="com.lagou.edu.dao.impl.JdbcTemplateDaoImpl">
    </bean>
    <bean id="transferService" class="com.lagou.edu.service.impl.TransferServiceImpl">
    </bean>
</beans>
```

#### 创建对象工厂

使用Dom4j解析XML文件，使用反射创建对象，使用Map保存对象

```java
public class BeanFactory {

    // 创建Map，用来保存类id与类对象
    private static Map<String,Object> map = new HashMap<>();

    // 根据id获取Bean
    public static Object getBean(String id){
        return map.get(id);
    }

    // 加载时初始化
    // 一、读取配置文件
    // 二、使用反射实例化
    static {
        // 获取配置文件流
        InputStream inputStream = BeanFactory.class.getClassLoader().getResourceAsStream("beans.xml");

        // 使用dom4j解析配置文件
        SAXReader reader = new SAXReader();
        try {
            Document document = reader.read(inputStream);
            // 获取根标签
            Element rootElement = document.getRootElement();
            // 获取bean标签
            List<Element> beanNodes = rootElement.selectNodes("//bean");

            // 循环bean，使用反射创建对象，保存到容器中
            for (Element element : beanNodes) {
                String id = element.attributeValue("id"); // 获取id 当key
                String clazz = element.attributeValue("class"); // 获取全限定类名，用作反射

                // 反射创建对象
                Class<?> aClass = Class.forName(clazz);
                Object o = aClass.newInstance();
                // 保存到容器中
                map.put(id,o);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        // 关闭流
        try {
            inputStream.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

#### 修改new处代码

```java
public class TransferServiceImpl implements TransferService {

    // private AccountDao accountDao = new JdbcAccountDaoImpl();
    private AccountDao accountDao = (AccountDao) BeanFactory.getBean("accountDao");
    //···
}

@WebServlet(name="transferServlet",urlPatterns = "/transferServlet")
public class TransferServlet extends HttpServlet {

    // 1. 实例化service层对象
    //private TransferService transferService = new TransferServiceImpl();
    private TransferService transferService = (TransferService) BeanFactory.getBean("transferService");
    //···
}
```

修改完后，我们会发现这样使用工厂的getBean方法获取对象，也不够优雅，最完美的形式应该是下面这样

```java
public class TransferServiceImpl implements TransferService {

    // private AccountDao accountDao = new JdbcAccountDaoImpl();
    //private AccountDao accountDao = (AccountDao) BeanFactory.getBean("accountDao");
    // 完美形式
    private AccountDao accountDao;
    //···
}
```

这样应该如何实现呢，首先我们必须为成员变量AccountDao赋值，方式一般为两种，构造方法或`set`方法

这里我们使用`set`方法，然后我们可以将此类所依赖的对象配置到配置文件中，然后再工厂创建对象时，使用反射调用`set`方法为其成员变量赋值。

#### 优化实现方式

##### Service类中添加set方法

```java
public class TransferServiceImpl implements TransferService {

    // private AccountDao accountDao = new JdbcAccountDaoImpl();
    //private AccountDao accountDao = (AccountDao) BeanFactory.getBean("accountDao");
    // 完美形式
    private AccountDao accountDao;

    public void setAccountDao(AccountDao accountDao) {
        this.accountDao = accountDao;
    }
    // ···
}
```

这里就不在Servlet类中添加了，因为Servlet有自己的容器初始化规则

##### 配置文件添加配置

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!--跟标签beans，里面配置一个又一个的bean子标签，每一个bean子标签都代表一个类的配置-->
<beans>
    <!--id标识对象，class是类的全限定类名-->
    <bean id="accountDao" class="com.lagou.edu.dao.impl.JdbcTemplateDaoImpl">
    </bean>
    <bean id="transferService" class="com.lagou.edu.service.impl.TransferServiceImpl">
        <!--set+ name 之后锁定到传值的set方法了，通过反射技术可以调用该方法传入对应的值-->
        <property name="AccountDao" ref="accountDao"></property>
    </bean>
</beans>
```

这里在需要对成员变量赋值的bean标签中，添加property标签，设置需要设置的成员变量名，和对应的实例化id

##### 修改对象工厂代码

```java
public class BeanFactory {

    // 创建Map，用来保存类id与类对象
    private static Map<String,Object> map = new HashMap<>();

    // 根据id获取Bean
    public static Object getBean(String id){
        return map.get(id);
    }

    // 加载时初始化
    // 一、读取配置文件
    // 二、使用反射实例化
    static {
        // 获取配置文件流
        InputStream inputStream = BeanFactory.class.getClassLoader().getResourceAsStream("beans.xml");

        // 使用dom4j解析配置文件
        SAXReader reader = new SAXReader();
        try {
            Document document = reader.read(inputStream);
            // 获取根标签
            Element rootElement = document.getRootElement();
            // 获取bean标签
            List<Element> beanNodes = rootElement.selectNodes("//bean");

            // 循环bean，使用反射创建对象，保存到容器中
            for (Element element : beanNodes) {
                String id = element.attributeValue("id"); // 获取id 当key
                String clazz = element.attributeValue("class"); // 获取全限定类名，用作反射

                // 反射创建对象
                Class<?> aClass = Class.forName(clazz);
                Object o = aClass.newInstance();
                // 保存到容器中
                map.put(id,o);
            }

            // 优化实例化方式，获取带有property的标签，将其所属父标签的实例进行依赖注入
            List<Element> propertyNodes = rootElement.selectNodes("//property");
            for (Element element : propertyNodes) {
                // 获取标签中的name与ref
                String name = element.attributeValue("name");
                String ref = element.attributeValue("ref");
                String methodName = "set" + name; // set方法名称

                // 获取父标签
                Element parent = element.getParent();
                // 获取父标签的id，好从Map容器中拿出
                String parId = parent.attributeValue("id");
                Object parentObject = map.get(parId);
                // 获取该对象的所有方法
                Method[] methods = parentObject.getClass().getMethods();
                // 循环方法，找到set + name方法
                for (Method method : methods) {
                    if(method.getName().equalsIgnoreCase(methodName)){
                        // 依赖注入
                        Object propertyObject = map.get(ref); // 依赖的对象
                        method.invoke(parentObject,propertyObject);
                    }
                }

                // 设置完依赖后，将该对象重新放入容器
                map.put(parId,parentObject);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        // 关闭流
        try {
            inputStream.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

