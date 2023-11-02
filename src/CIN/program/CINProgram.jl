# ! be included in: CIN.jl @ module CIN

# 导出
export CINProgram

export has_hook, use_hook, out_hook!
export isAlive, launch!, terminate!
export getNARSType, getConfig # async_read_out

# export cycle!


"""具体与纳思通信的「程序」
核心功能：负责与「NARS的具体计算机实现」沟通
- 例：封装好的NARS程序包（支持命令行交互）
"""
abstract type CINProgram end

"抽象属性声明：使用外部构造方法"
function CINProgram(
    type::AbstractString,
    out_hook::Union{Function,Nothing}=nothing,
)
    @debug "Construct: CINProgram with $out_hook, $type"
    return new(out_hook, type) # 返回所涉及类的一个实例（通用构造方法名称）
end

"复制一份副本（所有变量），但不启动"
Base.copy(program::CINProgram)::CINProgram = copy(program)
"similar类似copy"
Base.similar(program::CINProgram)::CINProgram = copy(program)

# 析构函数
function Base.finalize(program::CINProgram)::Nothing
    terminate!(program)
end

# 程序相关 #

"判断「是否有钩子」"
has_hook(program::CINProgram)::Bool = !isnothing(program.out_hook)

"（有钩子时）调用钩子（输出信息）"
use_hook(program::CINProgram, content::String) = (
    has_hook(program) && program.out_hook(content)
)

"设置对外接口：函数钩子"
function out_hook!(program::CINProgram, newHook::Union{Function,Nothing})::Union{Function,Nothing}
    program.out_hook = newHook
end

"重载：函数第一位，以支持do语法"
out_hook!(newHook::Union{Function,Nothing}, program::CINProgram)::Union{Function,Nothing} = (
    out_hook!(program, newHook)
)

"（API）程序是否存活（开启）"
isAlive(::CINProgram)::Bool = @abstractMethod(isAlive)  # 抽象属性变为抽象方法

"（API）启动程序"
launch!(::CINProgram)::Nothing() = @abstractMethod(launch!)

"终止程序"
function terminate!(program::CINProgram)
    program.out_hook = nothing # 置空
    @debug "CINProgram terminate!"
end

# NAL相关 #

"""
获取CIN的「NARS类型」
- 【2023-11-02 00:11:08】实现方法：下放给各CIN实现
"""
getNARSType(program::CINProgram) = @abstractMethod(program)

"""
获取CIN的配置
- 【20230723 14:00:47】目的：解耦——通过「函数声明」摆脱CIN本身对Register的依赖
- 【2023-11-02 00:11:08】实现方法：下放给各CIN实现
"""
getConfig(program::CINProgram) = error("$program: 方法未实现！")

"分派给Program做构造方法"
CINConfig(program::CINProgram) = getConfig(program)

"（API）添加输入（NAL语句字符串）：对应PyNEI的「write_line」"
Base.put!(::CINProgram, ::String) = @abstractMethod

"针对「可变长参数」的多项输入" # 不强制inputs的类型
function Base.put!(program::CINProgram, input1, input2, inputs...) # 不强制Nothing
    # 使用多个input参数，避免被分派到自身
    put!(program, (input1, input2, inputs...))
end

"针对「可变长参数」的多项输入" # 不强制inputs的类型
function Base.put!(program::CINProgram, inputs::Union{Vector,Tuple}) # 不强制Nothing
    # 注意：Julia可变长参数存储在Tuple而非Vector中
    for input ∈ inputs
        put!(program, input)
    end
end

# !【2023-11-02 00:32:04】↓现在不再实现「cycle!」，转由NAVM指令「CMD_CYC」实现
# "（API）【立即？】增加NARS的工作循环：对应PyNEI的「add/update_inference_cycle」"
# cycle!(::CINProgram, steps::Integer)::Nothing = @abstractMethod
# !【20230706 10:11:04】Program不再内置「inference_cycle_frequency」，由调用者自行决定（分派cycle!）
