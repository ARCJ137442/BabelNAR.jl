# 预先条件引入 # ! 不引入会导致无法使用符号
@isdefined(BabelNARImplements) || include(raw"test_console$import.jl")

# 使用NAVM包
using NAVM: @nair, Backend, BackendModule, CMD_CYC, CMD_DEL, CMD_HLP, CMD_INF, CMD_LOA, CMD_NEW, CMD_NSE, CMD_REM, CMD_RES, CMD_SAV, CMD_VOL, Frontend, FrontendModule, NAIR, NAIR_CMD, NAIR_FOLDS, NAIR_GRAMMAR, NAIR_INSTRUCTIONS, NAIR_INSTRUCTION_INF_KEYS, NAIR_INSTRUCTION_SET, NAIR_RULES, NARSESE_TYPE, NAVM, NAVM_Module, chain, form_cmd, load_cmds, parse_cmd, source_type, target_type, transform, try_form_cmd, try_transform, tryparse_cmd
@show names(NAVM)

# 使用NAVM包的实现
include("./../../../NAVM/implements/Implements.jl")
@show names(Implements)
using .Implements: BE_NARS_Python, BE_ONA, BE_OpenJunars, BE_OpenNARS, BE_PyNARS, FE_TextParser, Implements

"覆盖：使用NAVM进行解析"
main_received_convert(consoleWS::NARSConsoleWithServer, message::String) = NAIR_interpret(
    # 根据NARS类型分派
    Val(getNARSType(consoleWS.console.program) |> Symbol),
    message
)

"NAVM分派：String总体fallback"
function NAIR_interpret(val::Val{nars_type}, message::String)::String where {nars_type}
    @info "NAIR_interpret@string" nars_type message
    try
        cmd = parse_cmd(message)
        # 进一步针对CMD解析
        return NAIR_interpret(val, cmd)
    catch err
        @error "NAIR CMD parse error：" err
        return ""
    end
end

"NAVM分派：CMD总体fallback"
function NAIR_interpret(::Val{nars_type}, cmd::NAIR_CMD)::String where {nars_type}
    @info "NAIR_interpret@CMD" nars_type cmd
    # TODO: 转译操作
    return message
end

"NAVM分派：CMD/NSE 纯CommonNarsese输入"
function NAIR_interpret(::Val{nars_type}, cmd::CMD_NSE)::String where {nars_type}
    @info "NAIR_interpret@CMD" nars_type cmd
    return string(cmd.narsese)
end