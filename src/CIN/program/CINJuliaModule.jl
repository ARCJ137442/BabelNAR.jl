# ! be included in: CIN.jl @ module CIN

# 导出
export CINJuliaModule


"""囊括所有使用「Julia模块」实现的CIN

一些看做「共有属性」的getter
- modules(::CINJuliaModule)::Dict{String, Module}: 存储导入的Junars模块
    - 格式：「模块名 => 模块对象」
"""
abstract type CINJuliaModule <: CINProgram end

# !【2023-11-02 00:22:48】抽象类不用实现「获取NARS类型」和「获取配置」的方法

"实现：复制一份副本（所有变量），但不启动"
Base.copy(jm::CINJuliaModule)::CINJuliaModule = CINJuliaModule(
    getNARSType(jm),
    jm.out_hook,
    jm.cached_inputs |> copy, # 可变数组需要复制
)
"similar类似copy"
Base.similar(jm::CINJuliaModule)::CINJuliaModule = copy(jm)

"（API）获取所持有的模块::Dict{String, Module}"
modules(::CINJuliaModule)::Dict{String,Module} = @abstractMethod

"""
检查CIN的模块导入情况
- 返回：检查的CIN「是否正常」
"""
function check_modules(jm::CINJuliaModule)::Bool
    # 遍历检查所有模块
    for module_name in jm.module_names
        if !haskey(modules(jm), module_name) || isnothing(modules(jm)[module_name]) # 若为空
            @debug "check_modules ==> 未载入模块`$module_name`！"
            return false
        end
    end
    return true
end
