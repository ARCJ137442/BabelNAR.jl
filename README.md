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

🔗参考[**NAVM.jl**的对应部分](https://github.com/ARCJ137442/navm.jl?tab=readme-ov-file#commonnarsese)

## 安装

作为一个**Julia包**，您只需：

1. 在安装`Pkg`包管理器的情况下，
2. 在REPL(`julia.exe`)运行如下代码：

```julia
using Pkg
Pkg.add(url="https://github.com/ARCJ137442/BabelNAR.jl")
```

## 使用

🔗参考[BabelNAR_Implements](https://github.com/ARCJ137442/BabelNAR_Implements)的具体实现

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

### 依赖

- [JuNarsese](https://github.com/ARCJ137442/JuNarsese.jl)
- [NAVM](https://github.com/ARCJ137442/NAVM.jl)
- [BabelNAR](https://github.com/ARCJ137442/BabelNAR.jl)
