# TCLAscIITable
基于TCL的ASCII Table 打印函数

## TclAscIITable

TclAscIITable是一款基于TCL语言的纯文本表格打印函数包，具有以下功能：
- 允许以行/列优先输入数据
- 允许添加表格
- 允许添加表头
- 允许修改表格水平/垂直分割字符
- 允许修改表格打印风格

打印效果可参考以下范例

```
PrintTable -Row $Row -Header $Header -Title "TableTitle"
.-------------------------.
|       TableTitle        |
|-------+-------+---------|
| aaaaa | index | comment |
|   1   |  one  |  0.01   |
|   1   |  one  |  0.01   |
|   1   |  one  |  0.01   |
|   1   |  one  |  0.01   |
'-------------------------'

PrintTable -Row $Row -Header $Header  -FirstLine 0 -LastLine 0 -VSplitChar " " -Title "Title" -TopChar = -HSplitChar = -Margin "" -TitleCenter 0
Title
===========================
  aaaaa   index   comment
    1      one     0.01
    1      one     0.01
    1      one     0.01
    1      one     0.01

```
