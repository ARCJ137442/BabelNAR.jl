# ! be included in: BabelNAR.jl @ module BabelNAR

module extension

# 导入
using ...Utils # ! 引入在「主包外的同级」，故需要三个点（两个点跳出本模块，第三个点代指同级路径）
using ...CIN

# 引入 & 导出 #

# * 所有基于「BabelNAR CIN核心库」的扩展

## * 控制台
include("NARSConsole.jl")

## * 带服务器的控制台
include("NARSConsoleWithServer.jl")

end
