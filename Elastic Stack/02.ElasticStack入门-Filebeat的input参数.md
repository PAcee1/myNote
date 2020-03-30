## Filebeat的input参数

##### paths

日志加载的路径.例如加载某一子目录级别下面路径的日志:`/var/log/*/*.log`.这表示会去加载以.log结尾的/var/log下面的所有子目录,注意:这不包括`/var/log`这一级目录.可在paths前面加(-),指定多个目录路径

##### recursive_glob.enabled

这个特性可以在路径后面跟随`**`,表示加载这个路径下所有的文件,例如:`/foo/**`,表示加载`/foo,/foo/*,/foo/*/*`.这项特性默认是打开的,要关闭可以设置`recursive_glob.enabled=false`

##### encoding

encdoing根据输入的文本设置

- plain, latin1, utf-8, utf-16be-bom, utf-16be, utf-16le, big5, gb18030, gbk, hz-gb-2312,
- euc-kr, euc-jp, iso-2022-jp, shift-jis, and so on

##### exclude_lines

用一个数组匹配FIlebeat排除的行

如果使用了multiline这个设置的话,每一个multiline信息在被exclude_lines过滤之前都会被合并成一个简单行

下面这个例子表示,Filebeat会过滤掉所有的以DBG开头的行

```yml
Copyfilebeat.inputs:
- type: log
  ...
  exclude_lines: ['^DBG']
```

##### include_lines

和exclude_lines相反,Filebeat只会接受符合正则表达式的行

下面这个例子表示Filebeat将导出以ERR或WARN开头的所有行

```
Copyfilebeat.inputs:
- type: log
  ...
  include_lines: ['^ERR', '^WARN']
```

如果exclude_lines和include_lines都被定义了,那么Filebeat将先执行include_lines,然后再执行exclude_lines,两者没有顺序关系

下面这个例子表示Filebeat将导出所有包含sometext的列,但是除了以DBG开头的行

```
Copyfilebeat.inputs:
- type: log
  ...
  include_lines: ['sometext']
  exclude_lines: ['^DBG']
```

##### harvester_buffer_size

每个harvester的缓存大小,默认是16384

##### max_bytes

单个日志消息可以发送的最大字节,这个设置对multiline特别管用,默认是10MB

##### json

设置实例

```
Copyjson.keys_under_root: true
json.add_error_key: true
json.message_key: log
```

##### keys_under_root

默认情况下，解析的JSON位于输出文档中的“json”键下。如果启用此设置，则会在输出文档中将键复制到顶层。

##### overwriter_keys

如果启用了keys_under_root和此设置，则解码的JSON对象中的值将覆盖Filebeat通常添加的字段（类型，源，偏移等）以防发生冲突。

##### add_error_key

如果启用此设置，则Filebeat会在JSON解析错误或在配置中定义message_key但无法使用时添加“error.message”和“error.type：json”键

##### message_key

指定被过滤的行和multiline的key,如果指定了key,那么这个key必须在顶层,并且value必须是string类型, 要不然将不能被过滤或聚合分析

##### ignore_decoding_error

指定如果json解析错误是否应该被记日志,默认是false

##### multiline

将多行日志合并成一行

##### exclude_files

用正则表达式来匹配你想要Filebeat过滤的文件

下面这个例子表示,Filebeat会过滤以gz为扩展名的文件

```
Copyfilebeat.inputs:
- type: log
  ...
  exclude_files: ['\.gz$']
```

##### ignore_older

Filebeat将忽略在指定的时间跨度之前修改的所有文件.例如,如果你想要在启动Filebeat的时候只发送最新的files和上周的文件,你就可以用这个设置

你可以使用string类型的字符串表示例如2h(2 hours) and 5m(5 minutes),默认是0,

设置0和注释掉这个配置具有一样的效果

注意:**你必须设置ignore_older大于close_inactive**

两类文件会受此设置的影响

1.文件未被harvest

2.文件被harvest但是没有更新的时间超过ignore_older设置的时间

##### close_*

用来关闭harvester在设置某个标准或时间之后.如果某个文件在被harvester关闭后更新,那么这个文件会在scan_frequency过去之后将再次被handler.

##### close_inactive

启用此选项后,如果文件尚未在指定的持续时间内harvested,那么会关闭文件handler.定义期间的计时器从harvester读最后一个文件开始.如果这个被关闭的文件内容再次改变,那么在scal_frequency之后会再次被pick up

我们推荐你设置这个值大于你频繁更新文件的时间,如果你更新log文件每几秒一次,那么你可以放心的设置close_inactive为1m,

##### close_renamed

如果设置这个值,Filebeat将会关闭文件处理当一个文件被改名了

##### close_timeout

给每个harvester设定一个生命周期,如果超过这个设定的时间,那么Filebeat将会停止读取这个文件,如果这个文件依然在更新, 那么会开始一个新的harvester,并重新计时.设置close_timeout可以使操作系统定期释放资源

如果你设置了close_timeout和ignore_older相等的时间,如果当harvester关闭后,这个文件被修改了,那么它也不会被pick up了.这通常会导致数据丢失. 如果正在处理multiline的时候close_timeout时间到了,那么可能只发送了部分文件.

##### clean_inactive

Filebeat将在设定的时间过后移除掉文件的读取状态,如果在移除文件的读取状态后,文件再次被更新,那么这个文件将再次被读取

这个设置可以有效的减少文件注册表的大小,特别是在每天有大量新的文件生成的系统中

##### clean_removed

Filebeat将会从注册表中移除这些文件,如果这些文件不能再磁盘中被找到.如果某个文件消失了,然后再次出现,那么这个文件将会被从头开始读.默认开启

##### scan_frequency

Filebeat检查指定用于读取的路径下的新文件的频率.我们推荐不要设置这个值小于1s,避免Filebeat过于频繁的扫描.默认是10s

如果想要近实时发送日志文件,请不要使用非常小的scan_frequency,使用close_inactive可以使文件持续的保持打开并不断的被轮询

##### tail_files

如果设置了这个值为true,那么Filebeat将会从尾读取这个文件

##### backoff

定义了Filebeat在达到EOF后再次检查文件之前等待的时间,默认值已经符合大多数的场景,默认1s.

##### harvester_limit

设置harvesters的并发量.默认设置为0,意思是没有做限制.如果设定了这个值, 意味着如果文件很多的话,并不会全部被托管,建议和close_*一起使用,这样能使新的文件被托管

##### tags

使用标签能够在Filebeat输出的每个事件中加入这个tags字段,这样能够被Kibana或Logstash轻松过滤

```
Copyfilebeat.inputs:
- type: log
  . . .
  tags: ["json"]
```

##### fields

可以向输出添加其他信息,例如可以加入一些字段过滤log数据

##### fields_under_root

如果设定为true,那么自定义字段将存储为输出文档中的顶级字段,而不是在子字段下的分组.如果自定义的字段与其他字段冲突了,那么自定义的字段会覆盖其他字段