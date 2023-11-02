# BabelNAR.jl

<!-- **简体中文** | [English](https://github.com/ARCJ137442/JuNarseseParsers.jl/blob/main/README-en.md) -->

[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)
[![Static Badge](https://img.shields.io/badge/julia-package?logo=julia&label=1.8%2B)](https://julialang.org/)

该项目使用[语义化版本 2.0.0](https://semver.org/)进行版本号管理。

基于[**JuNarsese**](https://github.com/ARCJ137442/JuNarsese.jl)、[**JuNarsese Parsers**](https://github.com/ARCJ137442/JuNarseseParsers.jl)、[**NAVM**](https://github.com/ARCJ137442/NAVM.jl)的CIN（NARS计算机实现）接口

- 前身自[**JuNEI**](https://github.com/ARCJ137442/JuNEI.jl)的「CIN」模块分离
  - 原 `JuNEI/Interface` 现成为 `BabelNAR/CIN`
- 旨在方便连接各类CIN，并通过**Websocket**等服务提供**通用统一交互接口**。

## 概念

### CIN (Computer Implement of NARS)

- 「NARS计算机实现」之英文缩写
- 指代所有**实现NARS**的计算机软件系统
  - 不要求完整实现NAL 1~9

### ***CommonNarsese***

- 由[Narsese Grammar (IO Format)](https://github.com/opennars/opennars/wiki/Narsese-Grammar-(Input-Output-Format))定义，
- 在各类NARS(Narsese)实现中，
- 最先产生规范，并最为广泛接受的一种语法

与其它方言、超集的不同点举例：

- 原子词项：
  - 一律使用`$`、`#`、`?`、`^`区分「独立变量」「非独变量」「查询变量」「操作」
  - 一律使用单独的`_`表示「像占位符」
- 复合词项：
  - 一律使用特殊括弧`{词项...}`、`[词项...]`表示「外延集」「内涵集」
  - 一律使用「圆括号+前缀表达式」`(连接符, 词项...)`形式表示「非外延集、内涵集的复合词项」
    - 如`(&, <A --> B>, ^op)`
    - 对「否定」不使用前缀表达式
    - 对其它「二元复合词项」不使用中缀表达式
- 陈述：
  - 一律使用尖括号表示陈述，没有其他选项
    - 如`<A --> B>`
  - 不使用「回顾性等价」`<\>`系词
    - 一律用表义能力等同的「预测性等价」`</>`系词代替
    - 如`<A <\> B>`将表示为`<B </> A>`

## 安装

作为一个**Julia包**，您只需：

1. 在安装`Pkg`包管理器的情况下，
2. 在REPL(`julia.exe`)运行如下代码：

```julia
using Pkg
Pkg.add(url="https://github.com/ARCJ137442/BabelNAR.jl")
```

## 快速开始

### 可执行文件

运行CIN所需的所有**可执行文件**（需要用到的`.jar`、`.exe`等），都需放在与`src`同级的`executables`目录；

这个路径也可通过通过配置`test_console.jl`中的`paths`变量：

```julia
paths::Dict = Dict([
    "OpenNARS" => "opennars.jar" |> JER
    "ONA" => "NAR.exe" |> JER
    "Python" => "main.exe" |> JER
    "Junars" => raw"..\..\..\..\OpenJunars-main"
])
```

格式：

```julia
"【CIN类名】" => "【文件名】"
```

### 依赖路径问题

介于开发效率方面的需求，本Julia包如 [NAVM](https://github.com/ARCJ137442/NAVM.jl) 一样

### 快速启动

在有Julia环境的电脑上，可尝试运行源码中的`Implements/test/test_console.jl`：

```bash
cd BabelNAR
julia Implements/test/test_console.jl
```

或运行`Implements/test/test_console_WSServer.jl`

- 需要Julia环境安装有 **SimpleWebsockets** 、 **JSON** 包

```bash
cd BabelNAR
julia Implements/test/test_console_WSServer.jl
```

## 代码规范 Notes

### 文件头部注释

形如

```julia
# ! be included in: 【文件名】.jl @ module 【模块名】
```

的文件头代码，意味着该文件夹将被包含在名为【文件名】文件的名为【模块名】的模块中。
这同样约定了：

1：`【文件名】.jl`中会出现如下形式的代码：

```julia
module 【模块名】
# ...
include("XXX/【文件名】.jl")
# ...
end
```

2：当前文件中的所有的`export 【符号名】`语句，将会从名为【模块名】的模块里导出名为【符号名】的符号，如：

```julia
# ! be included in: CIN.jl @ module CIN
export inputType
```

将意味着模块`CIN`将会导出符号`inputType`——这使得其可通过`using CIN: inputType`访问

## 参考

### CIN

- [OpenNARS (Java)](https://github.com/opennars/opennars)
- [ONA (C)](https://github.com/opennars/OpenNARS-for-Applications)
- [NARS-Python (Python)](https://github.com/ccrock4t/NARS-Python)
- [OpenJunars (Julia)](https://github.com/AIxer/OpenJunars)
<!-- - [PyNARS (Python)](https://github.com/bowen-xu/PyNARS)
- [Narjure (Clojure)](https://github.com/opennars/Narjure)
- [NARS-Swift (Swift)](https://github.com/maxeeem/NARS-Swift) -->
