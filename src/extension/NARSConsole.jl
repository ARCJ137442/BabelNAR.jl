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
mutable struct NARSConsole{InputInterpreterF<:Function}

    "内置程序（引用）"
    const program::CINProgram

    "输入的提示词"
    input_prompt::String

    """
    从「前端输入」到「后端计算」的「转译函数」
    - @method (input::String) -> String
    - 用于各类「输入预处理」
      - 如「NAVM指令转写」
      - # ! 不会影响CIN的读写和输出
    """
    input_interpreter::InputInterpreterF

    "是否已启动"
    launched::Bool # 用于过滤「无关信息」

    function NARSConsole(
        type::CINType,
        config::CINConfig,
        executable_path::String;
        # 可选参数
        input_prompt::String="Input: ",
        input_interpreter::InputInterpreterF=identity, # 默认为「恒等」，即「不做转译」
        on_out::Union{Function,Nothing}=nothing # 可配置的「输出钩子」（用于后续封装）
    ) where {InputInterpreterF<:Function}
        # 先构造自身 # ! 按指定顺序传递参数：类型名、配置、可执行文件路径、输出钩子
        console = new{InputInterpreterF}(
            (config.program_type)( # 使用配置中的类型
                type, # 传入Program
                config, # 传入CIN配置
                executable_path, # CINCmdline
                identity, # 占位符@out_hook
            ),
            input_prompt, # 留存prompt
            input_interpreter, # 留存转译函数
            false, # 默认未启动
        )
        # 通过更改内部Program的钩子，实现「闭包传输」 # * 类似PyNEI中「self」参数的目的
        out_hook!(
            console.program,
            isnothing(on_out) ? line -> on_console_out(console, line) :
            on_out
        )
        # 返回控制台
        return console
    end
end

"""
默认输出钩子（包括console对象「自身」）
- 输出格式：
"""
on_console_out(console::NARSConsole, line::String) = console.launched && println(line)

"启动控制台"
function launch!(console::NARSConsole; console!_kwargs...)
    launch!(console.program) # 启动CIN程序
    console!(console; console!_kwargs...) # 启动控制台循环
end

"""
开始控制台循环
- @param delay_between_input 每两次输入之间的等待时间（秒）
"""
function console!(console::NARSConsole; delay_between_input::Real=0, kwargs...)
    while true
        console.launched = true
        # 检测输入并注入CIN
        put!(
            console.program,
            # 再转译
            console.input_interpreter(
                # 键入
                input(console.input_prompt)
            )
        )
        # 等待指定秒数
        delay_between_input > 0 && sleep(delay_between_input)
    end
end

"终止控制台 = 终止CIN"
terminate!(console::NARSConsole) = terminate!(console.program)
