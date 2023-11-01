"用于快速启动交互式CIN控制台（带有可选的Websocket服务器）"

# push!(LOAD_PATH, "../src") # 用于直接打开（..上一级目录）
# push!(LOAD_PATH, "src") # 用于VSCode调试（项目根目录起）
push!(LOAD_PATH, "../Implements") # 用于从cmd打开
push!(LOAD_PATH, "Implements") # 用于从VSCode打开

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

not_VSCode_running::Bool = "test" ⊆ pwd()

# ! 避免「同名异包问题」最好的方式：只从「间接导入的包」里导入「直接导入的包」
using BabelNARImplements
@show names(BabelNARImplements)
using BabelNARImplements.BabelNAR # * ←这里就是「直接导入的包」
@show names(BabelNAR)

# !【2023-11-02 01:30:04】新增的「检验函数」，专门在「导入的包不一致」的时候予以提醒
if BabelNARImplements.BabelNAR !== BabelNAR
    error("报警：俩包不一致！")
end

"================Test for Console================" |> println

while true
    # type::String = "ONA"
    global type::String = not_VSCode_running ? inputType("NARS Type(OpenNARS/ONA/Python/Junars): ") : "OpenNARS"
    isempty(type) && (type = "OpenNARS")
    # 检验合法性
    # isvalid(type, NATIVE_CIN_CONFIGS) && break
    for t in keys(NATIVE_CIN_CONFIGS)
        @show t == type
    end
    @show type NATIVE_CIN_CONFIGS
    type in keys(NATIVE_CIN_CONFIGS) && break
    printstyled("Invalid Type!\n"; color=:red)
end

# 自动决定exe路径

EXECUTABLE_ROOT = joinpath(dirname(@__DIR__), "executables") # 获取文件所在目录的上一级目录（包根目录）
JER(name) = joinpath(EXECUTABLE_ROOT, name)

paths::Dict = Dict([
    "OpenNARS" => "opennars.jar" |> JER
    "ONA" => "NAR.exe" |> JER
    "Python" => "main.exe" |> JER
    "Junars" => raw"..\..\..\..\OpenJunars-main"
])

path = paths[type]

# 启动终端
console = NARSConsole(
    type,
    NATIVE_CIN_CONFIGS[type],
    path,
    "JuNEI.$type> ",
)

not_VSCode_running ? launch!(console) : @show console

@info "It is done."
