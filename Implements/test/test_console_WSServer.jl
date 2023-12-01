#= 📝Julia加载依赖的方法
# ! Julia在父模块引入「本地子模块」时，
# ! 需要**本地子模块的Git存储库完成了提交**才会开始编译本地子模块**更改后的版本**
=#

# 预先条件引入 # ! 不引入会导致无法使用符号
@isdefined(BabelNARImplements) || include(raw"test_console$import.jl")

"启动Websocket服务器"
function launchWSServer(consoleWS::NARSConsoleWithServer, host::String, port::Int)

    @assert !isnothing(consoleWS.server)
    local ended = Condition()

    listen(consoleWS.server, :client) do ws

        # Julia自带侦听提示
        @info "Websocket connection established."
        @debug "ws=$ws"
        push!(consoleWS.connections, ws)

        listen(ws, :message) do message
            "转换后的字符串" # ! 可能「一输入多输出」
            local inputs::Vector{String} = main_received_convert(consoleWS, message)
            # 处理：通过「转译函数」后放入CIN，视作为「CIN自身的输入」 # ! 只有非空字符串才会输入进CIN
            isempty(inputs) || for input in inputs
                put!(consoleWS.console.program, input)
            end
        end

        listen(ws, :close) do reason
            @warn "Websocket connection closed" reason...
            notify(ended)
        end

    end

    listen(consoleWS.server, :connectError) do err
        notify(ended, err, error=true)
    end

    # @show server

    @async serve(consoleWS.server, port, host)
    # wait(ended) # ! 实际上可以直接异步
end

# ! 依赖：Websocket包SimpleWebsockets ! #
try
    using SimpleWebsockets: WebsocketServer, Condition, listen, notify, serve, send
catch e
    @warn "BabelNAR: 包「SimpleWebsockets」未能成功导入，WebSocket服务将无法使用！"
end

# ! 统一规范：使用JSON「对象数组」的方式传递数据 ! #
try
    using JSON: json
catch err
    @warn "BabelNAR: 包「JSON」未能成功导入，WebSocket服务将无法使用！" err
end

# * 配置服务器地址信息
@isdefined(main_address) || function main_address(
    host::Union{AbstractString,Nothing}=nothing,
    port::Union{Int,Nothing}=nothing;
    default_host::String="127.0.0.1",
    default_port::Int=8765
)::NamedTuple{(:host, :port),Tuple{String,Int}}
    # 获取默认值

    if isnothing(host)
        hostI = input("Host ($default_host): ")
        host = !isempty(hostI) ? hostI : default_host
    end

    if isnothing(port)
        port = tryparse(Int, input("Port ($default_port): "))
        port = isnothing(port) ? default_port : port
    end

    # 返回
    return (
        host=host,
        port=port
    )
end

# * 转换服务器收到的消息
@isdefined(main_received_convert) || (main_received_convert(::NARSConsoleWithServer, message::String) = (
    message
)) # ! 默认为恒等函数，后续用于NAVM转译

# * 转译CIN的命令输出，生成「具名元组」数据（后续编码成JSON，用于WebSocket传输）
@isdefined(main_output_interpret) || (main_output_interpret(::Val{nars_type}, CIN_config::CINConfig, line::String) where {nars_type} = begin
    objects::Vector{NamedTuple} = NamedTuple[]

    head = findfirst(r"^\w+:", line) # EXE: XXXX # ! 只截取「开头纯英文，末尾为『:』」的内容

    isnothing(head) || begin
        push!(objects, (
            interface_name="BabelNAR@$(nars_type)",
            output_type=line[head][begin:end-1],
            content=line[last(head)+1:end]
        ))
    end

    return objects
end)

"""
用于高亮「输出颜色」的字典
"""
const output_color_dict = Dict([
    NARSOutputType.IN => :white
    NARSOutputType.OUT => :white
    NARSOutputType.EXE => :light_cyan
    NARSOutputType.ANTICIPATE => :yellow
    NARSOutputType.ANSWER => :light_green
    NARSOutputType.ACHIEVED => :light_green
    NARSOutputType.INFO => :light_black
    NARSOutputType.COMMENT => :light_black
    NARSOutputType.ERROR => :light_red
    # ! ↓这俩是OpenNARS附加的
    "CONFIRM" => :light_blue
    "DISAPPOINT" => :magenta
])

"""
用于分派「颜色反转」的集合
"""
const output_reverse_color_dict = Set([
    NARSOutputType.EXE
    # NARSOutputType.ANSWER
    # NARSOutputType.ACHIEVED
])

"覆盖：生成「带Websocket服务器」的NARS终端"
function main_console(type::CINType, path, CIN_configs)::NARSConsoleWithServer
    # 先定义一个临时函数，将其引用添加进服务器定义——然后添加「正式使用」的方法
    _temp_input_interpreter(x::Nothing) = x

    local server = NARSConsoleWithServer(
        # 先内置一个终端 #
        NARSConsole(
            type,
            CIN_configs[type],
            path;
            input_prompt="BabelNAR.$type> ",
            input_interpreter=_temp_input_interpreter # ! 与「来源网络」的一致
        );
        # 然后配置可选参数 #
        # 服务器
        server=WebsocketServer(),
        # 连接默认就是空
        connections=[],
        # 启动服务器
        server_launcher=launchWSServer,
        # 转译输出
        output_interpreter=(line::String) -> main_output_interpret(Val(Symbol(type)), CIN_configs[type], line)
        #= # !【2023-11-26 14:03:23】下面这段注释原先用于「统一的CIN输出」，但因「程序自身输出无法拦截屏蔽」而作罢
        begin
            local outputs::Vector{NamedTuple} = main_output_interpret(Val(Symbol(type)), CIN_configs[type], line)
            for output in outputs
                println("[$(output.output_type)] $(output.content)")
            end
            return outputs
        end =#,
        # 发送数据
        server_send=(consoleWS::NARSConsoleWithServer, datas::Vector{NamedTuple}) -> begin
            # 只用封装一次JSON
            local text::String = json(datas)
            for data in datas
                printstyled(
                    "[$(data.output_type)] $(data.content)\n";
                    color=get(output_color_dict, data.output_type, :default),
                    reverse=data.output_type in output_reverse_color_dict,
                    bold=true # 所有都加粗，以便和「程序自身输出」对比
                    )
            end
            # * 遍历所有连接，广播之
            for connection in consoleWS.connections
                send(connection, text)
            end
        end
    )
    # 定义方法
    _temp_input_interpreter(input::String) = main_received_convert(server, input)
    return server
end


"覆盖：可选启动服务器"
main_launch(consoleWS) = launch!(
    consoleWS;
    main_address()...
)

# 最终引入
include("test_console.jl")
