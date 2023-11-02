push!(LOAD_PATH, dirname(@__DIR__)) # 用于从cmd打开
push!(LOAD_PATH, @__DIR__) # 用于从VSCode打开

not_VSCode_running::Bool = "test" ⊆ pwd()

# ! 避免「同名异包问题」最好的方式：只从「间接导入的包」里导入「直接导入的包」
using BabelNARImplements
@debug names(BabelNARImplements)
using BabelNARImplements.BabelNAR # * ←这里就是「直接导入的包」
@debug names(BabelNAR)
using BabelNARImplements.Utils: input

# !【2023-11-02 01:30:04】新增的「检验函数」，专门在「导入的包不一致」的时候予以提醒
if BabelNARImplements.BabelNAR !== BabelNAR
    error("报警：俩包不一致！")
end