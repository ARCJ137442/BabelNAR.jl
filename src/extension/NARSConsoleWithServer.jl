# ! be included in: extension.jl @ module extension

import ...CIN: launch!, terminate!, out_hook! # ! 扩展方法而避免命名冲突

# 导出
export NARSConsoleWithServer
export launch!, console!

"""
从CIN到交互的示例界面：NARS控制台
- 🎯面向用户命令行输入（手动输入NAL语句）
- 📄内置CINProgram
- 🔬展示「如何封装CIN」的简单例子
- ⚙️可选的「外接Websocket服务器」功能
    - 不作为直接的包依赖
"""
mutable struct NARSConsoleWithServer{
    Server<:Any,
    Connection<:Any,
    OutputInterpreterF<:Function,
    ServerLauncherF<:Function,
    ServerSendF<:Function,}

    "内置的NARS控制台"
    const console::NARSConsole

    "内置的（Websocket）服务器"
    server::Server

    "服务器连接上的（Websocket）连接"
    connections::Vector{Connection}

    """
    对「外部输出」进行「JSON转译」的函数
    - @method (::String) -> Vector{NamedTuple}
      - NamedTuple建议至少有`output_type`和`content`两个值

    @example outputInterpreter(
        "IN: <A --> B>. %1.00;0.90% {484518737 : (-7377897410676343301,0)}"
        ) -> (
            interface_name="BabelNAR" # ? ←这个是不是「PyNARS特定」的
            output_type="IN"
            content="<A --> B>. %1.00;0.90% {484518737 : (-7377897410676343301,0)}"
        )
    """
    output_interpreter::OutputInterpreterF

    """
    用于「启动服务器」的函数
    - @method (console::NARSConsoleWithServer, host::String, port::Int) -> Server
    """
    server_launcher::ServerLauncherF

    """
    用于「服务器发送数据」的函数
    - @method (console::NARSConsoleWithServer, interpreted_data::Vector{NamedTuple}) -> Nothing
    """
    server_send::ServerSendF

    # ?【2023-11-02 20:21:01】是否还需要「终止服务器函数」

    """
    内部构造方法
    - 主要存在之目的：用于自动更改内部控制台（的CIN程序）的钩子
    """
    function NARSConsoleWithServer(
        console::NARSConsole;
        # 除了「控制台」本身，其它都是关键字参数
        server::Server,
        connections::Vector{Connection}=Connection[],
        server_launcher::ServerLauncherF,
        output_interpreter::OutputInterpreterF,
        server_send::ServerSendF
    ) where {
        Server<:Any,
        Connection<:Any,
        OutputInterpreterF<:Function,
        ServerLauncherF<:Function,
        ServerSendF<:Function,
    }
        # 先构造自身 # ! 按指定顺序传递参数：类型名、配置、可执行文件路径、输出钩子
        consoleWS = new{Server,Connection,OutputInterpreterF,ServerLauncherF,ServerSendF}(
            # 内置的NARS控制台
            console,
            # ! 关键字参数⇒顺序参数
            server,
            connections,
            output_interpreter,
            server_launcher,
            server_send,
        )

        # 通过更改内部NARSConsole的钩子，实现「闭包传输」
        out_hook!(
            console.program,
            line -> on_console_out(consoleWS, line) # ! 只是这里从「控制台」变成了「带服务器控制台」
        )

        # 返回自身
        return consoleWS
    end

end

"""
默认输出钩子（包括console对象「自身」）
- 输出格式：字符串
- 自动发送到服务器
"""
function on_console_out(consoleWS::NARSConsoleWithServer, line::String)
    # 打印输出 # ! 这里的输出不是「程序本身的输出」，删除它也无法拦截程序自身的输出
    # consoleWS.console.launched && println(line)

    # 解析⇒发送到客户端 #
    isnothing(consoleWS.server) || begin
        # 调用`output_interpreter`方法，解析输出文本
        objects = consoleWS.output_interpreter(line)
        # 调用`server_send`方法，广播发送到客户端 # ! 广播行为要在`server_send`中实现
        isempty(objects) || consoleWS.server_send(consoleWS, objects)
    end
end

"""
（从指定主机和端口）启动控制台
- 启动服务器
- 自动进入控制台循环
"""
function launch!(
    consoleWS::NARSConsoleWithServer;
    host::AbstractString,
    port::Int,
    console!_kwargs...
)
    # 启动内部CIN程序
    launch!(consoleWS.console.program)

    # 调用「服务器启动函数」
    consoleWS.server_launcher(consoleWS, host, port)

    # 内部控制台进入循环
    console!(consoleWS.console; console!_kwargs...)
end

"终止控制台" # ?【2023-11-02 20:22:34】后续是否要支持服务器终止
terminate!(consoleWS::NARSConsoleWithServer) = terminate!(consoleWS.console)
