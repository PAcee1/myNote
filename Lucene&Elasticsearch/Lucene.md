# **Lucene 全文检索技术**

## 一、全文检索简介

### 1.1 数据的分类

​	1) 结构化数据：

​		格式固定，长度固定，数据类型固定，例如数据库中的数据

​	2) 非结构化数据：

​		格式不固定，长度不固定，数据类型不固定，例如word，txt中的数据

### 1.2 数据的查询

​	1) 结构化数据查询：直接使用sql查询，简单高效

​	2) 非结构化数据查询：

​		1.目测，数据量大时无法使用

​		2.使用程序，将文件读到内存顺序查找，效率低

​		**3.将非结构化数据转为结构化数据，再进行查询**

### 1.3 全文检索

​	例如：txt中有一句`I am spring`，这样我们可以根据空格拆分，得到单词列表，基于这个列表创建索引，根据索引查询找到包含`spring`的文档，这个过程就叫全文检索，即**将非结构化数据转为结构化数据查询的过程**。

​	应用场景：搜索引擎（百度，谷歌），站内搜索（论坛，微博，淘宝京东）

### 1.4 Lucene

​	Lucene是一个基于Java开发的工具包，Apache旗下，唯一的全文检索技术。之后的Elasticsearch等等底层都是Lucene。

## 二、Lucene实现流程

![1570502426948](https://raw.githubusercontent.com/PAcee1/myNote/master/image/1570502426948.png)

Lucene主要分为创建索引和查询索引两大过程

### 2.1.创建索引

#### 2.1.1.获得文档

基于**原始文档数据**进行全文检索，搜索引擎：爬虫来获取原始数据，站内搜索：数据库数据为原始数据。

#### 2.1.2.构建文档对象

![1570502884665](https://raw.githubusercontent.com/PAcee1/myNote/master/image/1570502884665.png)

每个原始文档创建一个Document对象，该对象有多个域（类似数据库字段），存放文档信息的映射关系。

#### 2.1.3.分析文档

即分词的过程，将每个关键词封装成一个**Term**对象，每个Term对象包含**关键词所在域，关键词本身**。

这样不同的域的相同关键词不会是一个Term对象。

#### 2.1.4.创建索引

![1570503201643](https://raw.githubusercontent.com/PAcee1/myNote/master/image/1570503201643.png)

创建一个索引库，索引库中包含：**索引，document，索引与document对应关系**。

![1570503216828](https://raw.githubusercontent.com/PAcee1/myNote/master/image/1570503216828.png)

一般情况下都是先选择 文档，再在文档里查询关键词，而这种是先找索引再根据映射关系找文档，即**倒排索引结构**。

### 2.2.查询索引

#### 2.2.1.用户查询接口

​	如搜索引擎中的搜索框，用户输入查询条件

#### 2.2.2.创建查询

​	将用户输入的关键词封装，封装成类似Term对象，即域名称以及关键词内容

#### 2.2.3.执行查询

​	向索引库查询，向对应的域查询对应关键词索引，把找到的文档id返回

#### 2.2.4.渲染结果

​	对结果进行渲染，比如关键词加亮以及分页等。

## 三、入门程序

环境：lucene7.4，jdk1.8

### 3.1.创建索引

步骤：

1. 创建Directory对象，用来存放索引保存位置
2. 创建IndexWriter，用来向磁盘写索引
3. 获取原始数据
4. 循环原始数据创建Document与Field域
5. 将域填充到Document中
6. 将Document放入indexWriter，即写入磁盘
7. 关闭indexWriter

```java
@Test
public void createIndex() throws Exception{
    // 1.创建Directory对象，指定保存索引库位置
    // 保存到内存中
    //Directory directory = new RAMDirectory();
    // 保存到磁盘上
    Directory directory = FSDirectory.open(new File("D:\\ideaProject\\Lucene\\index").toPath());

    // 2.创建IndexWriter，用来将索引库写入磁盘
    IndexWriter indexWriter = new IndexWriter(directory,new IndexWriterConfig());

    // 3.获取原始数据
    File dir = new File("D:\\ideaProject\\Lucene\\searchsource");
    File[] files = dir.listFiles();
    for(File file : files){
        // 4.根据每个原始数据文件创建Document对象
        Document document = new Document();
        // 获取文件数据，如文件名，文件内容，文件大小，文件路径
        String fileName = file.getName();
        String filePath = file.getPath();
        String fileContent = FileUtils.readFileToString(file, "utf-8");
        long fileSize = FileUtils.sizeOf(file);

        // 根据文件数据创建Field域
        Field fieldName = new TextField("name",fileName,Field.Store.YES);
        Field fieldPath = new TextField("path",filePath,Field.Store.YES);
        Field fieldContent = new TextField("content",fileContent,Field.Store.YES);
        Field fieldSize = new TextField("size",fileSize+"",Field.Store.YES);

        // 5.将Field填充到Document对象中
        document.add(fieldName);
        document.add(fieldContent);
        document.add(fieldPath);
        document.add(fieldSize);

        // 6.使用indexWriter将索引库写入磁盘
        indexWriter.addDocument(document);
    }
    // 7.关闭indexWriter
    indexWriter.close();
}
```

### 3.2.查询索引

步骤：

1. 创建Directory，存储索引库位置
2. 根据Directory创建IndexReader
3. 根据IndexReader创建IndexSearcher，用来查询索引
4. 创建Query对象，类似于查询语句，存放Field域名称以及关键词
5. 使用IndexSearch查询，返回topDocs对象，根据参数可以实现类似分页的查询
6. 根据topDocs获取scoreDocs总记录数，即文档数
7. 循环记录数，根据文档ID获取文档Document
8. 对结果数据进行渲染，即Document渲染
9. 关闭IndexReader结束查询

```java
@Test
public void searchIndex() throws Exception{
    // 1.创建Directory对象，指定索引位置
    Directory directory = FSDirectory.open(new File("D:\\ideaProject\\Lucene\\index").toPath());
    // 2.创建IndexReader对象，用来保存directory并初始化IndexSearch
    IndexReader indexReader = DirectoryReader.open(directory);
    // 3.创建IndexSearcher，用来搜索索引
    IndexSearcher indexSearcher = new IndexSearcher(indexReader);
    // 4.创建Query，用来做查询条件
    Query query = new TermQuery(new Term("content","spring"));
    // 5.执行查询，返回TopDocs对象
    TopDocs topDocs = indexSearcher.search(query, 10);// 类似分页10条数据

    // 6.取总记录数scoreDoc[]
    ScoreDoc[] scoreDocs = topDocs.scoreDocs;
    System.out.println(topDocs.totalHits);

    // 7.循环获取文档列表，进行渲染结果
    for(ScoreDoc doc : scoreDocs){
        int docId = doc.doc; //document文档id
        // 根据id获取文档数据
        Document document = indexSearcher.doc(docId);
        System.out.println(document.get("name")); // 打印结果
        /*System.out.println(document.get("path")); // 打印结果
        System.out.println(document.get("content")); // 打印结果*/
        System.out.println(document.get("size")); // 打印结果
        System.out.println("------------------------------");
    }
    // 8.关闭indexReader
    indexReader.close();
}
```

## 四、分析器

### 4.1.查看默认分析器分析效果

即查看分析后的数据，步骤：

1. 创建分析器，默认使用StandardAnalyzer
2. 分析器分析，返回TokenStream对象，即分析后的数据
3. 创建CharTermAttribute对象，类似指针，指向TokenStream，用来查看每一行数据
4. 调用TokenStream的reset()方法，重置指针位置，没有调用会抛异常
5. 循环TokenStream，查看数据
6. 关闭TokenStream

```java
@Test
public void testTokenStream() throws Exception{
    // 1.创建分析器
    Analyzer analyzer = new StandardAnalyzer();
    // 2.使用分析器获取TokenStream对象，用来查看分词效果
    TokenStream tokenStream = analyzer.tokenStream("","The Spring Framework provides a comprehensive programming and configuration model.");
    // 3.为TokenStream对象创建一个指针，用来指向引用
    CharTermAttribute charTermAttribute = tokenStream.addAttribute(CharTermAttribute.class);
    // 4.调用reset方法，将指针重置
    tokenStream.reset();
    // 5.循环查看分词效果
    while(tokenStream.incrementToken()){
        System.out.println(charTermAttribute.toString());
    }
    // 6.关闭TokenStream
    tokenStream.close();
}
```

### 4.2.IKAnalyzer分析器

使用IKAnalyzer分析器可以分析中文。

查看IK分析效果：只需将上节中代码创建分析器的`new StandardAnalyzer`改成`new IKAnalyzer`。

创建索引时使用IK：只需将第二步的创建`IndexWriter`对象时，配置下`IndexWriterConfig`

```java
// 2.创建IndexWriter，用来将索引库写入磁盘
// 使用IK分词器
IndexWriterConfig indexWriterConfig = new IndexWriterConfig(new IKAnalyzer());
IndexWriter indexWriter = new IndexWriter(directory,indexWriterConfig);
```

## 五、索引库维护

### 5.1.Field域类型

| Field类                                                      | 数据类型               | Analyzed   是否分析 | Indexed   是否索引 | Stored   是否存储 | 说明                                                         |
| ------------------------------------------------------------ | ---------------------- | ------------------- | ------------------ | ----------------- | ------------------------------------------------------------ |
| StringField(FieldName,   FieldValue,Store.YES))              | 字符串                 | N                   | Y                  | Y或N              | 这个Field用来构建一个字符串Field，但是不会进行分析，会将整个串存储在索引中，比如(订单号,姓名等)   是否存储在文档中用Store.YES或Store.NO决定 |
| LongPoint(String name, long... point)                        | Long型                 | Y                   | Y                  | N                 | 可以使用LongPoint、IntPoint等类型存储数值类型的数据。让数值类型可以进行索引。但是不能存储数据，如果想存储数据还需要使用StoredField。 |
| StoredField(FieldName, FieldValue)                           | 重载方法，支持多种类型 | N                   | N                  | Y                 | 这个Field用来构建不同类型Field   不分析，不索引，但要Field存储在文档中 |
| TextField(FieldName, FieldValue, Store.NO)   或   TextField(FieldName, reader) | 字符串   或   流       | Y                   | Y                  | Y或N              | 如果是一个Reader, lucene猜测内容比较多,会采用Unstored的策略. |

### 5.2.添加索引

步骤：

1. 创建IndexWriter
2. 创建Document
3. 向Document中添加Field
4. 将document存入IndexWriter
5. 关闭IndexWriter

```java
@Test
public void addDocument() throws Exception{
    // 1.创建IndexWriter，使用IK分析器
    IndexWriter indexWriter = 
            new IndexWriter(FSDirectory.open(new File("D:\\ideaProject\\Lucene\\index").toPath()),
                    new IndexWriterConfig(new IKAnalyzer()));
    // 2.创建Document
    Document document = new Document();
    // 3.向Document添加域
    document.add(new TextField("name","新的",Field.Store.YES));
    // 4.将document存入IndexWriter
    indexWriter.addDocument(document);
    // 5.关闭indexWriter
    indexWriter.close();
}
```

### 5.3.删除索引

有两种：删除全部，根据Query或Term删除文档

```java
@Test
public void deleteDocumentAll() throws Exception{
    // 1.创建IndexWriter，使用IK分析器
    IndexWriter indexWriter =
            new IndexWriter(FSDirectory.open(new File("D:\\ideaProject\\Lucene\\index").toPath()),
                    new IndexWriterConfig(new IKAnalyzer()));
    indexWriter.deleteAll();
    indexWriter.close();
}

@Test
public void deleteDocument() throws Exception{
    // 1.创建IndexWriter，使用IK分析器
    IndexWriter indexWriter =
            new IndexWriter(FSDirectory.open(new File("D:\\ideaProject\\Lucene\\index").toPath()),
                    new IndexWriterConfig(new IKAnalyzer()));
    // 根据Term删除
    indexWriter.deleteDocuments(new Term("name","apache"));
    indexWriter.close();
}
```

### 5.4.修改索引

Lucene更新索引是先删除再新增

```java
@Test
public void updateDocument() throws Exception{
    // 1.创建IndexWriter，使用IK分析器
    IndexWriter indexWriter =
            new IndexWriter(FSDirectory.open(new File("D:\\ideaProject\\Lucene\\index").toPath()),
                    new IndexWriterConfig(new IKAnalyzer()));
    // 2.创建Document
    Document document = new Document();
    // 3.向Document添加域
    document.add(new TextField("name","更新新的",Field.Store.YES));
    indexWriter.updateDocument(new Term("name","spring"),document);
    indexWriter.close();
}
```

## 六、索引库查询

Lucene索引库查询常见的有三种：

1）TermQuery：使用Field域名与关键词进行查询

2）RangeQuery：范围查询，例如：文件大小0-100的文档

3）QueryParser：先将要查询的内容先分词再查询，例如：百度搜索“Lucene的使用方法和说明”，就要先分词再查询，不能直接使用TermQuery。

```java
@Test
public void testQuery() throws Exception{
    Directory directory = FSDirectory.open(new File("D:\\ideaProject\\Lucene\\index").toPath());
    IndexReader indexReader = DirectoryReader.open(directory);
    IndexSearcher indexSearcher = new IndexSearcher(indexReader);

    // 创建Query，用来做查询条件
    // 普通TermQuery
    //Query query = new TermQuery(new Term("name","更新"));
    // Size查询，RangeQuery
    Query query = LongPoint.newRangeQuery("size",0l,100l);
    printResult(query,indexSearcher);
}

@Test
public void queryParser() throws Exception{
    Directory directory = FSDirectory.open(new File("D:\\ideaProject\\Lucene\\index").toPath());
    IndexReader indexReader = DirectoryReader.open(directory);
    IndexSearcher indexSearcher = new IndexSearcher(indexReader);

    // 创建queryPaser对象，两个参数：搜索域，分析器
    QueryParser queryParser = new QueryParser("name",new IKAnalyzer());
    // 使用QueryPaser创建一个Query对象
    Query query = queryParser.parse("Lucene的使用方法和说明");
    // 执行查询
    printResult(query,indexSearcher);
}
```