# 预先条件引入 # ! 不引入会导致无法使用符号
@isdefined(BabelNARImplements) || include(raw"test_console$import.jl")

# 常量池 # ! 具体CIN类型参见<native.jl/NATIVE_CIN_CONFIGS>
const TYPE_OPENNARS = :OpenNARS
const TYPE_ONA = :ONA
const TYPE_NARS_PYTHON = :Python
const TYPE_OPEN_JUNARS = :OpenJunars

# 使用NAVM包 # ! 下面的符号截止至【2023-11-02 22:49:36】
using NAVM: @nair, Backend, BackendModule, Frontend, FrontendModule
using NAVM: CMD_CYC, CMD_DEL, CMD_HLP, CMD_INF, CMD_LOA, CMD_NEW, CMD_NSE, CMD_REM, CMD_RES, CMD_SAV, CMD_VOL
using NAVM: NAIR, NAIR_CMD, NAIR_FOLDS, NAIR_GRAMMAR, NAIR_INSTRUCTIONS, NAIR_INSTRUCTION_INF_KEYS, NAIR_INSTRUCTION_SET, NAIR_RULES, NARSESE_TYPE, NAVM, NAVM_Module
using NAVM: chain, form_cmd, load_cmds, parse_cmd, source_type, target_type, transform, try_form_cmd, try_transform, tryparse_cmd
@show names(NAVM)

# 使用NAVM包的实现 # ! 下面的符号截止至【2023-11-02 22:49:36】
include("./../../../NAVM/implements/Implements.jl")
@show names(Implements)
using .Implements: BE_NARS_Python, BE_ONA, BE_OpenJunars, BE_OpenNARS, BE_PyNARS
using .Implements: FE_TextParser
using .Implements: Implements

"覆盖：使用NAVM进行解析"
main_received_convert(consoleWS::NARSConsoleWithServer, message::String)::Vector{String} = NAIR_interpret(
    # 根据NARS类型分派
    Val(getNARSType(consoleWS.console.program) |> Symbol),
    message
)

"NAVM分派：String总体fallback 深入CMD"
function NAIR_interpret(val::Val{nars_type}, message::String)::Vector{String} where {nars_type}
    try
        cmd = parse_cmd(message)
        # 进一步针对CMD解析
        return @show NAIR_interpret(val, cmd)
    catch err
        @error "NAIR CMD parse error：" err
        return ""
    end
end

"NAVM分派：CMD总体fallback 恒等"
function NAIR_interpret(::Val{nars_type}, cmd::NAIR_CMD)::Vector{String} where {nars_type}
    @info "NAIR_interpret@CMD:fallback" nars_type cmd
    return message
end

# "NAVM分派：CMD/NSE fallback 纯CommonNarsese输入" # ! 现在使用了专门的后端，这个定义将导致歧义
# (NAIR_interpret(::Val{nars_type}, cmd::CMD_NSE)::Vector{String}) where {nars_type} = string(cmd.narsese)

# * 各个后端终于派上用场了 * #

const instance_BE_OpenNARS = BE_OpenNARS()
"NAVM分派：CMD OpenNARS 使用OpenNARS后端"
NAIR_interpret(::Val{TYPE_OPENNARS}, cmd::NAIR_CMD)::Vector{String} = transform(instance_BE_OpenNARS, cmd)

const instance_BE_ONA = BE_ONA()
"NAVM分派：CMD ONA 使用ONA后端"
NAIR_interpret(::Val{TYPE_ONA}, cmd::NAIR_CMD)::Vector{String} = transform(instance_BE_ONA, cmd)

const instance_BE_NARS_Python = BE_NARS_Python()
"NAVM分派：CMD NARS-Python 使用NARS-Python后端"
NAIR_interpret(::Val{TYPE_NARS_PYTHON}, cmd::NAIR_CMD)::Vector{String} = transform(instance_BE_NARS_Python, cmd)

const instance_BE_OpenJunars = BE_OpenJunars()
"NAVM分派：CMD OpenJunars 使用OpenJunars后端"
NAIR_interpret(::Val{TYPE_OPEN_JUNARS}, cmd::NAIR_CMD)::Vector{String} = transform(instance_BE_OpenJunars, cmd)
