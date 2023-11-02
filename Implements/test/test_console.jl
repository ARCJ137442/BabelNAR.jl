"用于快速启动交互式CIN控制台（带有可选的Websocket服务器）"

#=
# !📝同名异包问题：直接导入≠间接导入 ! #
    ! 当在「加载路径」添加了太多「本地值」时，可能会把「依赖中的本地包」和「加载路径上的本地包」一同引入
    * 这样的引入会导致「看似都是同一个包（这里是BabelNAR），
      * 但实际上『从本地直接引入的一级包』和『从本地其它包二级引入的同名包』不一样」的场景
    * 本文件的例子就是：从`LOAD_PATH`和`BabelNARImplements`分别引入了俩`BabelNAR`，一个「纯本地」一个「纯本地被引入」
    * 📌没意识到的就是：这俩包 居 然 是 不 一 样 的
    ! 于是就会发生冲突——或者，「奇怪的不相等」
    * 比如「同样都是一个位置的同名结构」，两个「NARSType」死活不相等
    * ——就是因为「一级本地包中的 NARSType」与「二级本地包中的 NARSType」不一致
    * 然后导致了「缺方法」的假象
        * 一个「一级本地类A1」配一个「二级本地类B2」想混合着进函数f，
        * 结果`f(a::A1, b::B1)`和`f(a::A2, b::B2)`都匹配不上
    * 于是根子上就是「看起来`BabelNAR.CIN.NARSType`和`NARSType`是一致的，但实际上不同的是`BabelNAR`和`BabelNARImplements.BabelNAR`」的情况
    * 记录时间：【2023-11-02 01:36:43】
=#

# 条件引入
@isdefined(BabelNARImplements) || include(raw"test_console$import.jl")

"""
用于获取用户输入的「NARS类型」
- 逻辑：不断判断
"""
function get_valid_NARS_type_from_input(
    valid_types;
    default_type::String,
    input_prompt::String)::String

    local type::String

    while true
        type = input(input_prompt)
        # 输入后空值合并
        isempty(type) && (type = default_type)
        # * 合法⇒退出⇒返回
        type in valid_types && break
        # * 非法⇒警告⇒重试
        printstyled("Invalid Type $(type)!\n"; color=:red)
    end

    # 返回合法的类型
    return type
end

begin # * 可执行文件路径
    # 获取文件所在目录的上一级目录（包根目录）
    EXECUTABLE_ROOT = joinpath(dirname(dirname(@__DIR__)), "executables")
    JER(name) = joinpath(EXECUTABLE_ROOT, name)

    paths::Dict = Dict([
        "OpenNARS" => "opennars.jar" |> JER
        "ONA" => "NAR.exe" |> JER
        "Python" => "main.exe" |> JER
        "OpenJunars" => raw"..\..\..\..\OpenJunars-main"
    ])
end


# * 主函数 * #
# * 获取NARS类型
@isdefined(main_type) || (main_type(default_type) = begin
    global not_VSCode_running

    @isdefined(FORCED_TYPE) ? FORCED_TYPE :
    not_VSCode_running ? get_valid_NARS_type_from_input(
        keys(NATIVE_CIN_CONFIGS);
        default_type,
        input_prompt="NARS Type [$(join(keys(NATIVE_CIN_CONFIGS)|>collect, '|'))] ($default_type): "
    ) :
    "OpenNARS"
end)
# * 根据类型获取可执行文件路径
@isdefined(main_path) || (main_path(type) = paths[type])
# * 生成NARS终端
@isdefined(main_console) || (main_console(type, path, CIN_configs) = NARSConsole(
    type,
    CIN_configs[type],
    path;
    input_prompt="BabelNAR.$type> "
))
# * 启动
@isdefined(main_launch) || (main_launch(console) = launch!(
    console,
    ( # 可选的「服务器」
        (@isdefined IP) && (@isdefined PORT) ?
        (IP, PORT) : tuple()
    )...
))
# * 主函数
@isdefined(main) || function main()

    "================Test for Console================" |> println

    global not_VSCode_running

    # 获取NARS类型
    local type::String = main_type("OpenNARS")

    # 根据类型获取可执行文件路径
    local path::String = main_path(type)

    # 生成NARS终端
    local console = main_console(type, path, NATIVE_CIN_CONFIGS) # ! 类型无需固定

    # 启动NARS终端
    not_VSCode_running && @show console # VSCode（CodeRunner）运行⇒打印
    main_launch(console) # 无论如何都会启动 # * 用于应对「在VSCode启动服务器相对不需要用户输入」的情况
end

# * 现在可以通过「预先定义main函数」实现可选的「函数替换」
main()

@info "It is done."
