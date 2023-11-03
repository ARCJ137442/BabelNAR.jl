# 预先条件引入 # ! 不引入会导致无法使用符号
@isdefined(BabelNARImplements) || include(raw"test_console$import.jl")

"覆盖：输出分类型进行解析 fallback"
main_output_interpret(::Val{nars_type}, CIN_config::CINConfig, line::String) where {nars_type} = (
    CIN_config.output_interpret(line)
)
