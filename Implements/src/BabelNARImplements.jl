# ! root module

"""
所有的「具体CIN类型」与「CIN配置」实现

目前接口中可用的CIN类型
- OpenNARS(Java)
- ONA(C/C++)
- Python(Python)
- Junars(Julia)【WIP】
- 【未来还可更多】
"""
module BabelNARImplements

# 导入 #
using BabelNAR.Utils # ! 引入在「主包外的同级」，故需要三个点（两个点跳出本模块，第三个点代指同级路径）
using BabelNAR

# 引入 & 导出 #

# * 「具体CIN实现」交给下面的jl：抽象接口与具体注册分离
## * 原生CIN
include("CIN/CINOpenJunars.jl")


# * 「具体CIN配置」交给下面的jl：抽象接口与具体注册分离
## * 原生CIN配置：目前（2023-11-01）包括OpenNARS、ONA、NARS-Python与OpenJunars
include("CINConfig/native.jl")

end
