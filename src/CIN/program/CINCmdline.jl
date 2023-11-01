# ! be included in: CIN.jl @ module CIN

# 导出
export CINCmdline

export add_to_cmd!
export cached_inputs, cache_input!, num_cached_input, cache_input!, clear_cached_input!, flush_cached_input!


"""囊括所有使用「命令行语句IO」实现的CIN
- open一个子进程，异步运行CIN主程序
- 通过「println(process.in, input)」向CIN输入信息
"""
mutable struct CINCmdline <: CINProgram

    # 继承CINProgram #

    "存储对应CIN类型"
    type::String

    "（2023-11-02新）存储CIN配置"
    config::CINConfig

    "外接钩子"
    out_hook::Union{Function,Nothing}

    # 独有属性 #

    "程序路径"
    executable_path::String

    "缓存的输入"
    cached_inputs::Vector{String}

    "CIN进程"
    process::Base.Process

    """
    宽松的内部构造方法
    - 定义为**内部构造方法**之因：让`process`未定义，以便不用`Union{Nothing, ...}`
        - 因：但new顺序定死，没法灵活
    """
    function CINCmdline(
        type::String,
        config::CINConfig,
        executable_path::String,
        out_hook::Union{Function,Nothing}=nothing,
        cached_inputs::Vector{String}=String[] # Julia动态初始化默认值（每调用就计算一次，而非Python中只计算一次）
    )
        new(
            type,
            config,
            out_hook,
            executable_path,
            cached_inputs #=空数组=#
        )
    end
end

"实现：获取NARS类型"
getNARSType(cmd::CINCmdline)::String = cmd.type

"实现：获取配置"
getConfig(cmd::CINCmdline)::CINConfig = cmd.config

"实现：复制一份副本（所有变量），但不启动"
Base.copy(cmd::CINCmdline)::CINCmdline = CINCmdline(
    cmd.type,
    cmd.config,
    cmd.executable_path,
    cmd.out_hook,
    copy(cached_inputs), # 可变数组需要复制
)
"similar类似copy"
Base.similar(cmd::CINCmdline)::CINCmdline = copy(cmd)

# 📝Julia对引入「公共属性」并不看好

"存活依据：主进程非空"
isAlive(cmd::CINCmdline)::Bool =
    !@soft_isnothing_property(cmd.process) && # 进程是否非空
    # !eof(cmd.process) && # 是否「文件结束」（！会阻塞主进程）
    cmd.process.exitcode != 0 && # 退出码正常吗
    process_running(cmd.process) && # 是否在运行
    !process_exited(cmd.process) # 没退出吧
# 先判断「有无属性」，再判断「是否定义」，最后判断「是否为空」
# TODO：避免用符号「:process」导致「无法自动重命名」的问题
# 进展：没能编写出类似「@soft_isnothing_property cmd.process」自动化（尝试用「hasproperty($object, property_name)」插值「自动转换成Symbol」混乱，报错不通过）

"实现「启动」方法（生成指令，打开具体程序）"
function launch!(cmd::CINCmdline)
    # @super CINProgram launch!(cmd)
    # TODO：使用cmd间接启动「管不到进程」，直接启动「主进程阻塞」

    isempty(cmd.executable_path) && error("empty executable path!")

    # 输入初始指令 ？是要在cmd中启动，还是直接在命令中启动？
    startup_cmds::Tuple{Cmd,Vector{String}} = cmd.executable_path |> getConfig(cmd).launch_arg_generator

    launch_cmd::Cmd = startup_cmds[1]

    @async begin # 开始异步进行操作
        try

            # process::Base.Process = open(`cmd /c $launch_cmd`, "r+") # 打开后的进程不能直接赋值给结构体的变量？
            # cmd.process = process

            process::Base.Process = open(`cmd`, "r+") # 打开后的进程不能直接赋值给结构体的变量？
            cmd.process = process
            sleep(0.75)
            launch_cmd_str::String = replace("$launch_cmd"[2:end-1], "'" => "\"") # Cmd→String
            # 不替换「'」为「"」则引发「文件名或卷标语法不正确。」
            put!(cmd, launch_cmd_str) # Cmd转String

            @debug "Process opened with isAlive(cmd) = $(isAlive(cmd))"

            # ！@async中无法直接打开程序

            for startup_cmd ∈ startup_cmds[2]
                put!(cmd, startup_cmd)
            end

            sleep(0.25)

            !isAlive(cmd) && @warn "CIN命令行程序未启动：$cmd\n启动参数：$startup_cmds"
        catch e
            @error e
        end
    end

    @async async_read_out(cmd) # 开启异步读取

    sleep(1) # 测试

    @debug "Program launched with pid=$(getpid(cmd.process))"

    return isAlive(cmd) # 返回程序是否存活（是否启动成功）
end

"从stdout读取输出"
function async_read_out(cmd::CINCmdline)
    line::String = "" # Julia在声明值类型后必须初始化
    while isAlive(cmd)
        try # 注意：Julia中使用@async执行时，无法直接显示与跟踪报错
            line = readline(cmd.process)
            !isempty(line) && use_hook(
                cmd, line |> strip |> String # 确保SubString变成字符串
            ) # 非空：使用钩子
        catch e
            @error e
        end
    end
    "loop end!" |> println
end

# 📌在使用super调用超类实现后，还能再分派回本类的实现中（见clear_cached_input!）
"继承：终止程序（暂未找到比较好的方案）"
function terminate!(cmd::CINCmdline)
    @debug "CINCmdline terminate! $cmd"
    clear_cached_input!(cmd) # 清空而不置空（不支持nothing）

    # 【20230716 9:14:43】TODO：增加「是否强制」选项，用taskkill杀死主进程（java, NAR, main），默认为false
    # @async kill(cmd.process) # kill似乎没法终止进程
    # @async close(cmd.process) # （无async）close会导致主进程阻塞
    # try
    #     pid::Integer = getpid(cmd.process)
    #     `taskkill -f -im java.exe` |> run
    #     `taskkill -f -im NAR.exe` |> run
    #     `taskkill -f -im main.exe` |> run
    #     `taskkill -f -pid $pid` |> run # 无奈之举（但也没法杀死进程）
    # catch e
    #     @error e
    # end # 若使用「taskkill」杀死直接open的进程，会导致主进程阻塞

    # 【20230714 13:41:18】即便上面的loop end了，程序也没有真正终止
    cmd.process.exitcode = 0 # 设置标识符（无奈之举），让isAlive(cmd)=false
    # 【20230718 13:08:50】📝使用「Base.invoke」或「@invoke」实现Python的`super().方法`
    @invoke terminate!(cmd::CINProgram) # 构造先父再子，析构先子再父
end

"重载：直接添加至命令"
function Base.put!(cmd::CINCmdline, input::String)
    # @async add_to_cmd!(cmd, input) # 试图用异步而非「缓存」解决「写入卡死」问题
    cache_input!(cmd, input) # 先加入缓存
    flush_cached_input!(cmd) # 再执行&清除
end

"（慎用）【独有】命令行（直接写入）"
function add_to_cmd!(cmd::CINCmdline, input::String)
    # @info "Added: $input" # 【20230710 15:52:13】Add目前工作正常
    println(cmd.process.in, input) # 使用println输入命令
end

#= "实现方法：推理循环步进"
function cycle!(cmd::CINCmdline, steps::Integer)
    inp::String = getConfig(cmd).cycle(steps) # 套模板
    !isempty(inp) && add_to_cmd!(
        cmd,
        inp,
    ) # 增加指定步骤（println自带换行符）
end =#

"【独有】缓存的命令"
cached_inputs(cmd::CINCmdline)::Vector{String} = cmd.cached_inputs

"缓存的输入数量" # 注：使用前置宏无法在大纲中看到方法定义
num_cached_input(cmd::CINCmdline)::Integer = length(cmd.cached_inputs)

"将输入缓存（不立即写入CIN）"
cache_input!(cmd::CINCmdline, input::String) = push!(cmd.cached_inputs, input)

"清除缓存的输入"
clear_cached_input!(cmd::CINCmdline) = empty!(cmd.cached_inputs)

"将所有缓存的输入全部*异步*写入CIN，并清除缓存"
function flush_cached_input!(cmd::CINCmdline)
    for cached_input ∈ cmd.cached_inputs
        @async add_to_cmd!(cmd, cached_input)
    end
    clear_cached_input!(cmd)
end
