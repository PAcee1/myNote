## 基础概念

在mongodb中是通过数据库、集合、文档的方式来管理数据，下边是mongodb与关系数据库的一些概念对比：

![1580717326496](../image/1580717326496.png)

![1580717334519](../image/1580717334519.png)

- 一个mongodb实例可以创建多个数据库
- 一个数据库可以创建多个集合
- 一个集合可以包括多个文档。

## 连接MongoDB

mongodb的使用方式是客户服务器模式，即使用一个客户端连接mongodb数据库（服务端）。

### 命令格式

```
mongodb://[username:password@]host1[:port1][,host2[:port2],...[,hostN[:portN]]][/[database][?
options]]
```

mongodb:// 固定前缀
username：账号，可不填
password：密码，可不填
host：主机名或ip地址，只有host主机名为必填项。
port：端口，可不填，默认27017
/database：连接某一个数据库
?options：连接参数，key/value对

例子：

```
mongodb://localhost 连接本地数据库27017端口 
mongodb://root:itcast@localhost 使用用户名root密码为itcast连接本地数据库27017端口 
mongodb://localhost,localhost:27018,localhost:27019，连接三台主从服务器，端口为27017、27018、27019
```

### 使用studio3T连接

### 使用java程序连接

详细参数：http://mongodb.github.io/mongo-java-driver/3.4/driver/tutorials/connect-to-mongodb/

添加依赖：

```xml
<dependency>
    <groupId>org.mongodb</groupId>
    <artifactId>mongo‐java‐driver</artifactId>
    <version>3.4.3</version>
</dependency>
```

连接MongoDB

```java
@Test
public void testConnection(){
    //创建mongodb 客户端
    MongoClient mongoClient = new MongoClient( "localhost" , 27017 );
    //或者采用连接字符串
    //MongoClientURI connectionString = new MongoClientURI("mongodb://root:root@localhost:27017");
  	//MongoClient mongoClient = new MongoClient(connectionString);    
    //连接数据库
    MongoDatabase database = mongoClient.getDatabase("test");
    // 连接collection
    MongoCollection<Document> collection = database.getCollection("student");
    //查询第一个文档
    Document myDoc = collection.find().first();
    //得到文件内容 json串
    String json = myDoc.toJson();
    System.out.println(json);
}
```

## 数据库

### 查询数据库

`show dbs` 查询全部数据库

`db` 显示当前数据库

### 创建数据库

命令格式：

```
use DATABASE_NAME
```

例子：

```
use test02
```

有test02数据库则切换到此数据库，没有则创建。

注意：新创建的数据库不显示，需要至少包括一个集合。

### 删除数据库

命令格式：

```
db.dropDatabase()
```

例子：删除test02数据库

先切换数据库：use test02

再执行删除：db.dropDatabase()

## 集合

集合相当于关系数据库中的表，一个数据库可以创建多个集合，一个集合是将相同类型的文档管理起来。

### 创建集合

```
db.createCollection(name, options)
name: 新创建的集合名称
options: 创建参数
```

### 删除集合

```
db.collection.drop()
例子：
db.student.drop() 删除student集合
```

## 文档

### 插入文档

mongodb中文档的格式是json格式，下边就是一个文档，包括两个key：_id主键和name

```json
{
    "_id" : ObjectId("5b2cc4bfa6a44812707739b5"),
    "name" : "Pace"
}
```

插入命令

```
db.COLLECTION_NAME.insert(document)
```

每个文档默认以_id作为主键，主键默认类型为ObjectId（对象类型），mongodb会自动生成主键值。

例子：

```
db.student.insert({"name":"Pace","age":10})
```

注意：同一个集合中的文档的key可以不相同！但是建议设置为相同的。

### 更新文档

```
db.collection.update(
   <query>,
   <update>,
   <options>
)
query:查询条件，相当于sql语句的where
update：更新文档内容
options：选项
```

1、替换文档

将符合条件 `"name":"Pace"` 的第一个文档替换为`{"name":"Pace1","age":10}`

```
db.student.update({"name":"Pace"},{"name":"Pace1","age":10})
```

2、`$set`修改器

使用`$set`修改器指定要更新的key，key不存在则创建，存在则更新。

将符合条件 `"name":"Pace" `的所有文档更新`name`和`age`的值。

```
db.student.update({"name":"Pace1"},{$set:{"name":"Pace","age":10}},{multi:true})
```

multi：false表示更新第一个匹配的文档，true表示更新所有匹配的文档。

### 删除文档

命令格式：

```
db.student.remove(<query>)
query：删除条件，相当于sql语句中的where
```

1、删除所有文档

`db.student.remove({})`

2、删除符合条件的文档

`db.student.remove({"name":"Pace"})`

### 查询文档

命令格式：

```
db.collection.find(query, projection)
query：查询条件，可不填
projection：投影查询key，可不填
```

1、查询全部

```
db.student.find()
```

2、按条件查询

```
db.student.find({"name":"Pace"})
```



3、投影查询

类似`select name,age from student`

例子：只显示name和age两个key，_id主键不显示。

```
db.student.find({"name":"Pace"},{name:1,age:1,_id:0})
```



## 用户

### 创建用户

语法格式：

```
mongo>db.createUser(
{ user: "<name>",
  pwd: "<cleartext password>",
  customData: { <any information> },
  roles: [
    { role: "<role>", db: "<database>" } | "<role>",
    ...
  ]}
)
```

示例：

```
use admin
db.createUser(
     {
       user:"root",
       pwd:"123",
       roles:[{role:"root",db:"admin"}]
     }
)
```

### 认证登录

为了安全需要，Mongodb要打开认证开关，即用户连接Mongodb要进行认证，其中就可以通过账号密码方式进行
认证

1. 在mono.conf中设置 auth=true
2. 重启Mongodb
3. 使用账号和密码连接数据库

连接方式：

使用mongo.exe连接

```
mongo.exe -u root -p 123 --authenticationDatabase admin
```

使用Studio 3T连接

![1580719056110](../image/1580719056110.png)

### 查询用户

查询当前库下的所有用户：

`show users`

### 删除用户

```
db.dropUser("用户名")
db.dropUser("test1")
```

### 修改用户

```
db.updateUser(
  "<username>",
  {
    customData : { <any information> },
    roles : [
              { role: "<role>", db: "<database>" } | "<role>",
              ...
            ],
    pwd: "<cleartext password>"
    },
    writeConcern: { <write concern> })
```

例子： 

```
db.updateUser("root",{roles:[{role:"readWriteAnyDatabase",db:"admin"}]})
```

### 修改密码

```
db.changeUserPassword("username","newPasswd")
```

