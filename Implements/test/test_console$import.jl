push!(LOAD_PATH, dirname(@__DIR__)) # 用于从cmd打开
push!(LOAD_PATH, @__DIR__) # 用于从VSCode打开

not_VSCode_running::Bool = "test" ⊆ pwd()

# ! 避免「同名异包问题」最好的方式：只从「间接导入的包」里导入「直接导入的包」
using BabelNARImplements
@debug names(BabelNARImplements)
using BabelNARImplements.BabelNAR # * ←这里就是「直接导入的包」
@debug names(BabelNAR)
using BabelNARImplements.Utils: input, _INTERNAL_MODULE_SEARCH_DICT # ! ←这个用于注入Junars

# 引入OpenJunars # ! 但这是本地目录，所以在别的地方需要稍加修改
push!(LOAD_PATH, "../../../OpenJunars-main")
import DataStructures
import Junars
@debug names(Junars) names(DataStructures)
# 注入 # * Symbol(模块)=模块名（符号）
for m in [Junars, DataStructures]
    _INTERNAL_MODULE_SEARCH_DICT[Symbol(m)] = m
end

# !【2023-11-02 01:30:04】新增的「检验函数」，专门在「导入的包不一致」的时候予以提醒
if BabelNARImplements.BabelNAR !== BabelNAR
    error("报警：俩包不一致！")
end