# 预先条件引入 # ! 不引入会导致无法使用符号
@isdefined(BabelNARImplements) || include(raw"test_console$import.jl")

# 引入其它配置 #
include(raw"test_console_NAVM$config.jl")
include(raw"test_console_ServerOutFormat$config.jl")

# 覆盖配置 #

"覆盖：使用默认地址，但端口可配置（默认8765）"
function main_address(
    ::Union{AbstractString,Nothing}=nothing,
    port::Union{Int,Nothing}=nothing;
    default_host::String="127.0.0.1",
    default_port::Int=8765
)::NamedTuple{(:host, :port),Tuple{String,Int}}

    # 获取默认值
    host = default_host
    @info "主机地址：$host"

    if isnothing(port)
        port = tryparse(Int, input("Port ($default_port): "))
        port = isnothing(port) ? default_port : port
    end

    # 决定「是否输出详细信息」
    if !isempty(input("Detailed output (false)："))
        # * 启用DEBUG模式
        @debug "启用DEBUG模式！"
        ENV["JULIA_DEBUG"] = "all"
    end

    # 返回
    return (
        host=host,
        port=port
    )
end

# 最终引入
include("test_console_WSServer.jl")
