# ! be included in: BabelNARImplements.jl @ BabelNARImplements

"""
本文件主要用于预设「一般情况下使用的CIN配置」
- 目前支持的CIN类型（截止至2023-11-04）：
    - OpenNARS
    - ONA
    - NARS-Python
    - OpenJunars

对外JSON输出的格式，可参考Matriangle`src/mods/NARFramework/NARSTypes.type.ts`:
```typescript
export type WebNARSOutput = {
	interface_name?: string
	output_type?: string
	content?: string
	output_operation?: string[]
}
```
"""

# 使用NAVM包 # ! 下面的符号截止至【2023-11-02 22:49:36】
using NAVM: @nair, Backend, BackendModule, Frontend, FrontendModule
using NAVM: CMD_CYC, CMD_DEL, CMD_HLP, CMD_INF, CMD_LOA, CMD_NEW, CMD_NSE, CMD_REM, CMD_RES, CMD_SAV, CMD_VOL
using NAVM: NAIR, NAIR_CMD, NAIR_FOLDS, NAIR_GRAMMAR, NAIR_INSTRUCTIONS, NAIR_INSTRUCTION_INF_KEYS, NAIR_INSTRUCTION_SET, NAIR_RULES, NARSESE_TYPE, NAVM, NAVM_Module
using NAVM: chain, form_cmd, load_cmds, parse_cmd, source_type, target_type, transform, try_form_cmd, try_transform, tryparse_cmd
@debug names(NAVM)

# 使用NAVM包的实现 # ! 下面的符号截止至【2023-11-02 22:49:36】
include("./../../../../NAVM/implements/Implements.jl")
@debug names(Implements)
using .Implements: BE_NARS_Python, BE_ONA, BE_OpenJunars, BE_OpenNARS, BE_PyNARS
using .Implements: FE_TextParser
using .Implements: Implements

export NATIVE_CIN_CONFIGS
export NATIVE_CIN_TYPES, TYPE_OPENNARS, TYPE_ONA, TYPE_NARS_PYTHON, TYPE_OPEN_JUNARS

# 常量池 #

# CIN类型
@isdefined(TYPE_OPEN_JUNARS) || const TYPE_OPEN_JUNARS::CINType = :OpenJunars # ! CINOpenJunars.jl已定义
const NATIVE_CIN_TYPES = [
    const TYPE_OPENNARS::CINType = :OpenNARS
    const TYPE_ONA::CINType = :ONA
    const TYPE_NARS_PYTHON::CINType = :Python
    TYPE_OPEN_JUNARS # ! 可能在别的模块中定义，但一定得有
]

# NAVM后端实例
const NATIVE_BE_INSTANCES = [
    const instance_BE_OpenNARS = BE_OpenNARS()
    const instance_BE_ONA = BE_ONA()
    const instance_BE_NARS_Python = BE_NARS_Python()
    const instance_BE_OpenJunars = BE_OpenJunars()
]

#= NARS「输出前缀」翻译
    # * 主要处理如「Input: <<(* x) --> ^left> ==> A>. 【……】」中「Input⇒IN」这样的例子 =#
const translate_dict_OpenNARS = Dict([
    "IN" => NARSOutputType.IN,
    "OUT" => NARSOutputType.OUT,
    "EXE" => NARSOutputType.EXE,
    "ANTICIPATE" => NARSOutputType.ANTICIPATE,
    # ! OpenNARS特有
    "CONFIRM" => "CONFIRM",
])
const translate_dict_ONA = Dict([
    "Input" => NARSOutputType.IN,
    "Derived" => NARSOutputType.OUT,
    "Answer" => NARSOutputType.ANSWER,
    # ! "EXE" "ANTICIPATE" 会在ONA的「转译函数」中专门处理，形如「EXE ^right executed with args」没有冒号
    # "EXE" => NARSOutputType.EXE,
])
const translate_dict_NARS_Python = Dict([
    "IN" => NARSOutputType.IN,
])
const translate_dict_OpenJunars = Dict([
])
"惰性求值的类型转换 @ OpenNARS"
function typeTranslate_OpenNARS(type::AbstractString)::String
    local type_string::String = string(type)
    if haskey(translate_dict_OpenNARS, type_string)
        return translate_dict_OpenNARS[type_string]
    else
        # ! 默认将其转为全大写形式
        @warn "未定义的NARS输出类型「$type」"
        return uppercase(type_string)
    end
end
"惰性求值的类型转换 @ ONA"
function typeTranslate_ONA(type::AbstractString)::String
    local type_string::String = string(type)
    if haskey(translate_dict_ONA, type_string)
        return translate_dict_ONA[type_string]
    else
        # ! 默认将其转为全大写形式
        @warn "未定义的NARS输出类型「$type」"
        return uppercase(type_string)
    end
end
"惰性求值的类型转换 @ NARS_Python"
function typeTranslate_NARS_Python(type::AbstractString)::String
    local type_string::String = string(type)
    if haskey(translate_dict_NARS_Python, type_string)
        return translate_dict_NARS_Python[type_string]
    else
        # ! 默认将其转为全大写形式
        @warn "未定义的NARS输出类型「$type」"
        return uppercase(type_string)
    end
end
"惰性求值的类型转换 @ OpenJunars"
function typeTranslate_OpenJunars(type::AbstractString)::String
    local type_string::String = string(type)
    if haskey(translate_dict_OpenJunars, type_string)
        return translate_dict_OpenJunars[type_string]
    else
        # ! 默认将其转为全大写形式
        @warn "未定义的NARS输出类型「$type」"
        return uppercase(type_string)
    end
end

# 主字典定义

"""
现有库所支持之CIN(Computer Implement of NARS)的注册项

📌注意：简化🆚效率
- 若想简化里面的「Dict(」与其它逗号（用Vector的向量表达，即vcat一类函数）
    - 尽可能把代码往CINRegistry.jl移
    - 用向量代替参数逗号
- 效率牺牲：依照上面的简化方式，时间从「未简化」到「简化」变「1.655→2.095」
    - 足足慢了0.4s
"""
const NATIVE_CIN_CONFIGS::CINConfigDict = CINConfigDict( # * Julia的「类型别名」是可以直接作构造函数的
    TYPE_OPENNARS => CINConfig(;

        # 使用命令行控制
        program_type=CINCmdline,

        # 程序启动命令
        launch_arg_generator=(executable_path::String) -> (
            `java -Xmx1024m -jar $executable_path`,
            String[
                "*volume=0",
            ]
        ),

        #= 输出转译 # !【2023-11-03 23:20:05】现在函数更名，并且不再只是「捕捉操作」
        # * @method (line::String) -> Vector{@NamedTuple{output_type::String,content::String,output_operation::NARSOperationVec}}
        - 现在「操作截取」已作为「output_operation::NARSOperationVec」以「字符串数组」的形式被兼容

        例句：
            IN: <{SELF} --> [left_blocked]>. :|: %1.00;0.90% {260624161|260624161 : (-5395980139128131839,106)}
            IN: (^left,{SELF}). :|: %1.00;0.90% {260624162|260624162 : (-5395980139128131839,107)}
            IN: <{SELF} --> [SAFE]>! :|: %1.00;0.90% {260624164|260624164 : (-5395980139128131839,108)}
            IN: <{SELF} --> [SAFE]>! :|: %1.00;0.90% {260624165|260624165 : (-5395980139128131839,109)}
            IN: <{SELF} --> [SAFE]>. :|: %1.00;0.90% {260624166|260624166 : (-5395980139128131839,110)}
            IN: <{SELF} --> [right_blocked]>. :|: %1.00;0.90% {260624167|260624167 : (-5395980139128131839,111)}
            IN: <{SELF} --> [SAFE]>! :|: %1.00;0.90% {260624169|260624169 : (-5395980139128131839,112)}
            EXE: $1.00;0.99;1.00$ ^left([{SELF}])=null
            Executed based on: $0.2904;0.1184;0.7653$ <(&/,<{SELF} --> [right_blocked]>,+7,(^left,{SELF}),+55) =/> <{SELF} --> [SAFE]>>. %1.00;0.53%
            ANTICIPATE: <{SELF} --> [SAFE]>
            IN: (^right,{SELF}). :|: %1.00;0.90% {260624170|260624170 : (-5395980139128131839,116)}
            IN: <{SELF} --> [SAFE]>. :|: %1.00;0.90% {260624172|260624172 : (-5395980139128131839,117)}
            CONFIRM: <{SELF} --> [SAFE]><{SELF} --> [SAFE]>
            IN: <{SELF} --> [SAFE]>! :|: %1.00;0.90% {260624174|260624174 : (-5395980139128131839,118)}
            IN: (^left,{SELF}). :|: %1.00;0.90% {260624176|260624176 : (-5395980139128131839,119)}
            IN: <{SELF} --> [right_blocked]>. :|: %1.00;0.90% {260624177|260624177 : (-5395980139128131839,120)}
            EXE: $1.00;0.99;1.00$ ^left([{SELF}])=null
            Executed based on: $0.3191;0.1188;0.8005$ <(&/,<{SELF} --> [right_blocked]>,+568,(^left,{SELF}),+4) =/> <{SELF} --> [SAFE]>>. %1.00;0.60%
            ANTICIPATE: <{SELF} --> [SAFE]>
            DISAPPOINT: <{SELF} --> [SAFE]>
            EXE: $1.00;0.99;1.00$ ^right([{SELF}, x])=null

        =#
        output_interpret=(line::String) -> begin

            @info "Output Interpret @ OpenNARS" line

            local objects::Vector{NamedTuple} = NamedTuple[]
            local match_type = match(r"^(\w+): ", line) # EXE: XXXX # ! 只截取「开头纯英文，末尾为『: 』」的内容，并提取其中的「纯英文」

            # * 头都是空的⇒不处理（返回空数组）
            if isnothing(match_type) #
            else
                # 统一获取输出内容
                local content = line[length(match_type[1])+1:end] # 翻译成统一的「NARS输出类型」
                local output_type = typeTranslate_OpenNARS(match_type[1])

                # * 操作截取：匹配「EXE: 」开头的行 # 例句：EXE: $1.00;0.99;1.00$ ^right([{SELF}, x])=null
                if output_type == NARSOutputType.EXE # ! 这里可能是SubString，所以不能使用全等号
                    # 使用正则表达式r"表达式"与「match」字符串方法，并使用括号选定其中返回的第一项
                    # 样例：`^left([{SELF}])`
                    local match_operation = match(r"(\^\w+)\(\[(.*)\]\)=\w+$", line) # ! 名称带尖号 # 【2023-11-05 01:18:15】目前操作最后还是以`=null`结尾
                    # 使用isnothing避免「假冒语句」匹配出错
                    if !isnothing(match_operation) && length(match_operation) > 1
                        push!(objects, (;
                            output_type,
                            content,
                            output_operation=[
                                match_operation[1],
                                # * 基于「括号匹配」的更好拆分
                                split_between_root_brackets(
                                    match_operation[2], # 样例：`{SELF}, x`
                                    # 分隔符
                                    ", ",
                                    # 开括弧和闭括弧是默认的
                                )... # !【2023-11-05 02:06:23】SubString也是成功的
                            ]
                        ))
                    end #
                # * 默认文本处理
                else
                    # 正则匹配取「英文单词」部分，如「IN」

                    # ! 由于先前的正则匹配，所以这个正则匹配必然有值
                    push!(objects, (;
                        output_type,
                        content
                        # output_operation=[] # ! 无操作⇒无需参数
                    ))
                end
            end
            return objects
        end,

        #= NAIR指令转译
        - # * 直接调用相应「NAVM后端」转译
        - # * 相应「NAVM后端」将一次性负责所有的「指令翻译」如
            - # * `NSE`⇒CommonNarsese文本输入」
            - # * `CYC`⇒CIN周期递进」
        =#
        NAIR_interpreter=(cmd::NAIR_CMD) -> transform(instance_BE_OpenNARS, cmd)
    ),
    TYPE_ONA => CINConfig(;

        # 使用命令行控制
        program_type=CINCmdline,

        # 程序启动命令
        launch_arg_generator=(executable_path::String) -> (
            `$executable_path shell`,
            String[
                "*volume=0",
            ]
        ),

        #= 输出转译
        # * @method (line::String) -> Vector{@NamedTuple{output_type::String,content::String,output_operation::NARSOperationVec}}
        - 现在「操作截取」已作为「output_operation::NARSOperationVec」以「字符串数组」的形式被兼容
        例句：
            Input: <<(* x) --> ^left> ==> A>. Priority=1.000000 Truth: frequency=1.000000, confidence=0.900000
            Derived: <<(* x) --> ^left> ==> <self --> good>>. Priority=0.245189 Truth: frequency=1.000000, confidence=0.810000
            Derived: <<self --> good> ==> <(* x) --> ^left>>. Priority=0.196085 Truth: frequency=1.000000, confidence=0.447514
            Answer: <B --> C>. creationTime=2 Truth: frequency=1.000000, confidence=0.447514
            Answer: None.
            ^deactivate executed with args
            ^say executed with args
            ^left executed with args (* {SELF})
            ^left executed with args ({SELF} * x)
            decision expectation=0.616961 implication: <((<{SELF} --> [left_blocked]> &/ ^say) &/ <(* {SELF}) --> ^left>) =/> <{SELF} --> [SAFE]>>. Truth: frequency=0.978072 confidence=0.394669 dt=1.000000 precondition: <{SELF} --> [left_blocked]>. :|: Truth: frequency=1.000000 confidence=0.900000 occurrenceTime=50

        =#
        output_interpret=(line::String) -> begin

            @info "Output Interpret @ ONA" line

            local objects::Vector{NamedTuple} = NamedTuple[]

            # * 操作截取：匹配「EXE: 」开头的行
            if contains(line, "executed") # 越短越好
                # ! 假定：必定能匹配到「操作被执行」
                local match_operation::RegexMatch = match(r"^(\^\w+) executed with args(?: \((.*)\))?$", line)
                # 使用正则表达式r"表达式"与「match」字符串方法，并使用括号选定其中返回的第一项
                # * 操作无参数 样例：`^say executed with args`
                if isnothing(match_operation[2])
                    push!(objects, (
                        output_type=NARSOutputType.EXE,
                        content=line, # 暂无特殊截取
                        output_operation=[match_operation[1]]
                    ))#
                # * 操作有参数 样例：`^left executed with args (* {SELF})` | `^left executed with args ({SELF} * x)`
                else
                    # 分「二元操作」和「前缀操作」（二元操作老是想着「标新立异」而不是「整齐划一」……说白了就是为了好看）
                    local match_args::Vector{SubString} = (
                        startswith(match_operation[2], "* ") ?
                        # 样例：`* {SELF}` # !【2023-11-05 02:50:32】截止至目前，没经过测试
                        split_between_root_brackets(match_operation[2][3:end], " ") :
                        # 样例：`{SELF} * x` # *【2023-11-05 02:51:15】测试成功
                        split_between_root_brackets(match_operation[2], " *") # 必须把「*」也视作分隔符（根部）
                    )
                    @show match_args
                    push!(objects, (
                        output_type=NARSOutputType.EXE,
                        content=line, # 暂无特殊截取
                        output_operation=[match_operation[1], match_args...]
                    ))
                end#
            # * 特殊处理「预期」 "decision expectation"⇒ANTICIPATE
            elseif startswith(line, "decision expectation")
                push!(objects, (
                    output_type=NARSOutputType.ANTICIPATE,
                    content=line[length("decision expectation")+1:end],
                    output_operation=[] #! 空数组⇒无操作
                )) #
            # * 特殊处理「无回答」
            elseif line == "Answer: None." # ! 这里可能是SubString，所以不能使用全等号
            # 不产生任何输出
            # * 默认文本处理
            else
                local head = findfirst(r"^\w+: ", line) # EXE: XXXX # ! 只截取「开头纯英文，末尾为『: 』」的内容
                isnothing(head) || push!(objects, (
                    output_type=typeTranslate_ONA(line[head][1:end-2]),
                    content=line[last(head)+1:end],
                    output_operation=[] #! 空数组⇒无操作
                ))
            end

            return objects
        end,

        #= NAIR指令转译
        - # * 直接调用相应「NAVM后端」转译
        - # * 相应「NAVM后端」将一次性负责所有的「指令翻译」如
            - # * `NSE`⇒CommonNarsese文本输入」
            - # * `CYC`⇒CIN周期递进」
        =#
        NAIR_interpreter=(cmd::NAIR_CMD) -> transform(instance_BE_ONA, cmd)
    ),
    TYPE_NARS_PYTHON => CINConfig(;

        # 使用命令行控制
        program_type=CINCmdline,

        # 程序启动命令
        launch_arg_generator=(executable_path::String) -> (
            `$executable_path`,
            String[]
        ),

        #= 输出转译
        # * @method (line::String) -> Vector{@NamedTuple{output_type::String,content::String,output_operation::NARSOperationVec}}
        - 现在「操作截取」已作为「output_operation::NARSOperationVec」以「字符串数组」的形式被兼容
        例句：
            EXE: ^left based on desirability: 0.9
            PROCESSED GOAL: SentenceID:2081:ID ({SELF} --> [SAFE])! :|: %1.00;0.03%from SentenceID:2079:ID ({SELF} --> [SAFE])! :|: %1.00;0.00%,SentenceID:2080:ID ({SELF} --> [SAFE])! :|: %1.00;0.02%,
            PREMISE IS TRUE: ((*,{SELF}) --> ^right)
            PREMISE IS SIMPLIFIED ({SELF} --> [SAFE]) FROM (&|,({SELF} --> [SAFE]),((*,{SELF}) --> ^right))

            # TODO：找到NARS Python中「带参操作」的例句
        =#
        output_interpret=(line::String) -> begin
            @info "Output Interpret @ NARS Python" line

            local objects::Vector{NamedTuple} = NamedTuple[]

            # * 特殊处理「派生目标」 "PROCESSED GOAL"⇒？？？（暂且不明）
            if startswith(line, "PROCESSED GOAL") # ! 暂不处理
            # * 特殊处理「前提为真」 "PREMISE IS TRUE"⇒？？？（暂且不明）
            elseif startswith(line, "PREMISE IS TRUE") # ! 暂不处理
            # * 特殊处理「前提简化」 "PREMISE IS SIMPLIFIED"⇒？？？（暂且不明）
            elseif startswith(line, "PREMISE IS SIMPLIFIED") # ! 暂不处理
            # * 无头⇒不理
            elseif isnothing(local match_type = match(r"^(\w+): ", line)) # ! 只截取「开头纯英文，末尾为『: 』」的内容
            # fallback：返回空
            # * 操作截取：匹配「EXE: 」开头的行
            elseif match_type[1] == "EXE" # ! 这里可能是SubString，所以不能使用全等号
                # 使用正则表达式r"表达式"与「match」字符串方法，并使用括号选定其中返回的第一项
                match_operator = match(r"\^*(\^\w+)", line) # ! 带尖号，但只用一个 # 不知为何会有多个，输入的是`^left`结果是`EXE: ^^right based on desirability: 0.5126576876329072`
                isnothing(match_operator) || push!(objects, (
                    # `interface_name`交给外部调用者包装
                    output_type=NARSOutputType.EXE, # !【2023-11-05 03:07:07】检验正常
                    content=line[length(match_type)+1:end], # "^^left based on desirability: 0.9"
                    output_operation=[match_operator[1]]
                )) #
            # * 默认文本处理
            else
                isnothing(match_type) || push!(objects, (
                    output_type=typeTranslate_NARS_Python(match_type[1]),
                    content=line[length(match_type)+3:end],
                    output_operation=[] #! 空数组⇒无操作
                ))
            end
            # * fallback：返回空
            return objects
        end,

        #= NAIR指令转译
        - # * 直接调用相应「NAVM后端」转译
        - # * 相应「NAVM后端」将一次性负责所有的「指令翻译」如
            - # * `NSE`⇒CommonNarsese文本输入」
            - # * `CYC`⇒CIN周期递进」
        =#
        NAIR_interpreter=(cmd::NAIR_CMD) -> transform(instance_BE_NARS_Python, cmd)
    ),
    TYPE_OPEN_JUNARS => CINConfig(; #= 因此依赖于OpenJunars.jl =#

        # 使用特制Junars类控制
        program_type=CINOpenJunars,

        # 程序启动命令（不使用）
        launch_arg_generator=(executable_path::String) -> nothing,

        #= 输出转译(WIP)
        # * @method (line::String) -> Vector{@NamedTuple{output_type::String,content::String,output_operation::NARSOperationVec}}
        - 现在「操作截取」已作为「output_operation::NARSOperationVec」以「字符串数组」的形式被兼容
        # !【2023-11-01 23:55:36】目前OpenJunars并不支持NAl-8，且（在不修改源码的情况下）难以捕获输出

        =#
        output_interpret=(line::String) -> begin
            @warn "Junars尚未支持「输出转译」: $line"
            []
        end,

        #= NAIR指令转译
        - # * 直接调用相应「NAVM后端」转译
        - # * 相应「NAVM后端」将一次性负责所有的「指令翻译」如
            - # * `NSE`⇒CommonNarsese文本输入」
            - # * `CYC`⇒CIN周期递进」
        =#
        NAIR_interpreter=(cmd::NAIR_CMD) -> transform(instance_BE_OpenJunars, cmd)
    ),
)