# ! be included in: BabelNAR.jl @ module BabelNAR

"""
Computer Implement of NARS (CIN) | NARS计算机实现
- 核心功能：负责与「NARS的具体计算机实现」沟通
  - 无论其为exe、jar、py、jl……
"""
module CIN

# 导入 #
using ...Utils # ! 引入在「主包外的同级」，故需要三个点（两个点跳出本模块，第三个点代指同级路径）

# 引入 & 导出 #

# * CIN通用类型

## * 通用的CIN配置
include("struct/CINConfig.jl")


# * 通用CIN程序定义

## * 抽象的CIN
include("program/CINProgram.jl")

## * 基于命令行的CIN
include("program/CINCmdline.jl")

## * 基于Julia模块的CIN
include("program/CINJuliaModule.jl")

end
