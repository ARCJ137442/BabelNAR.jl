# 预先条件引入 # ! 不引入会导致无法使用符号
@isdefined(BabelNARImplements) || include(raw"test_console$import.jl")

using NAVM: parse_cmd

"覆盖：使用NAVM进行解析"
main_received_convert(consoleWS::NARSConsoleWithServer, message::String)::Vector{String} = NAIR_interpret(
    consoleWS,
    message
)

"NAVM分派：String总体fallback 深入CMD"
function NAIR_interpret(consoleWS::NARSConsoleWithServer, message::String)::Vector{String}
    # * 跳过空字串
    isempty(message) && return String[]

    # * 尝试进一步针对CMD解析
    try
        local cmd = parse_cmd(message)
        return @show getConfig(consoleWS.console.program).NAIR_interpreter(cmd)
    catch err # * 解析错误⇒返回空
        @error "NAIR CMD parse error：" err
        return String[]
    end
end