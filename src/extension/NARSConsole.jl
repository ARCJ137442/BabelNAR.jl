# ! be included in: extension.jl @ module extension

# 导入
using ...Utils # ! 引入在「主包外的同级」，故需要三个点（两个点跳出本模块，第三个点代指同级路径）

import ...CIN: launch!, terminate!, out_hook! # ! 扩展方法而避免命名冲突
using ...CIN

# 导出
export NARSConsole
export launch!, console!


"""
从CIN到交互的示例界面：NARS控制台
- 🎯面向用户命令行输入（手动输入NAL语句）
- 📄内置CINProgram
- 🔬展示「如何封装CIN」的简单例子
- ⚙️可选的「外接Websocket服务器」功能
    - 不作为直接的包依赖
"""
mutable struct NARSConsole

    # 内置程序（引用）
    const program::CINProgram

    input_prompt::String
    launched::Bool # 用于过滤「无关信息」

    NARSConsole(
        type::String,
        config::CINConfig,
        executable_path::String,
        input_prompt::String="Input: "
    ) = begin
        # 先构造自身
        console = new(
            (config.program_type)( # 使用配置中的类型
                type, # 传入Program
                config, # 传入CIN配置
                executable_path, # CINCmdline
                identity, # 占位符
            ),
            input_prompt, # 留存prompt
            false, # 默认未启动
        )
        # 通过更改内部Program的钩子，实现「闭包传输」类似PyNEI中「self」参数的目的
        out_hook!(console.program, line -> use_hook(console, line))
        return console
    end
end

try
    using JSON: json
catch e
    @warn "JuNEI: 包「JSON」未能成功导入，WebSocket服务将无法使用！"
end
"默认输出钩子（包括console对象「自身」）"
function use_hook(console::NARSConsole, line::String)
    console.launched && println(line)
    # 发送到客户端 #
    # 解析—— # TODO: 后续交给NAVM
    global server, connectedSocket
    if !isnothing(server)
        objs = []
        head = findfirst(r"\w+:", line) # EXE: XXXX
        if !isnothing(head)
            type = line[head][begin:end-1]
            content = line[last(head)+1:end]
            push!(objs, Dict(
                "interface_name" => "JuNEI",
                "output_type" => type,
                "content" => content
            ))
            # 传输
            for ws in connectedSocket
                send(ws, json(objs))
            end
        end
    end
end

"配置WS服务器信息"
function configServer(
    console::NARSConsole,
    host::Union{AbstractString,Nothing}=nothing,
    port::Union{Int,Nothing}=nothing,
)::NARSConsole
    needServer = !isnothing(host) || !isnothing(port) || !isempty(input("Server? (\"\") "))
    if needServer
        if isnothing(host)
            hostI = input("Host (127.0.0.1): ")
            host = !isempty(hostI) ? hostI : "127.0.0.1"
        end

        if isnothing(port)
            port = tryparse(Int, input("Port (8765): "))
            port = isnothing(port) ? 8765 : port
        end

        launchWSServer(console, host, port)
    end
    return console
end

try
    using SimpleWebsockets: WebsocketServer, Condition, listen, notify, serve, send
catch e
    @warn "JuNEI: 包「SimpleWebsockets」未能成功导入，WebSocket服务将无法使用！"
end
server = nothing
connectedSocket = []
function launchWSServer(console::NARSConsole, host::String, port::Int)

    global server, connectedSocket
    server = WebsocketServer()
    ended = Condition()

    listen(server, :client) do ws

        # Julia自带侦听提示
        @info "Websocket connection established with ws=$ws"
        push!(connectedSocket, ws)

        listen(ws, :message) do message
            # 直接处理
            put!(console.program, message)
        end

        listen(ws, :close) do reason
            @warn "Websocket connection closed" reason...
            notify(ended)
        end

    end

    listen(server, :connectError) do err
        notify(ended, err, error=true)
    end

    # @show server

    @async serve(server, port, host)
    # wait(ended) # ! 实际上可以直接异步
end

"启动终端"
function launch!(
    console::NARSConsole,
    host::Union{AbstractString,Nothing}=nothing,
    port::Union{Int,Nothing}=nothing,
)
    launch!(console.program) # 启动CIN程序
    configServer(console, host, port)
    console!(console)
end

"开始终端循环"
function console!(console::NARSConsole)
    while true
        console.launched = true
        inp = input(console.input_prompt)
        put!(console.program, inp)
    end
end

"终止终端"
terminate!(console::NARSConsole) = terminate!(console.program)
