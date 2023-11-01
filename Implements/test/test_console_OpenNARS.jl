"用于快速启动OpenNARS服务端，可通过「命令行」与「Websocket」双通道输入指令"

push!(LOAD_PATH, "../src") # 用于直接打开（..上一级目录）
push!(LOAD_PATH, "src") # 用于VSCode调试（项目根目录起）
push!(LOAD_PATH, "../") # 用于从cmd打开

not_VSCode_running::Bool = "test" ⊆ pwd()

using JuNEI

"================Test for Console================" |> println

while true
    # type::String = "ONA"
    global type::String = "OpenNARS" # not_VSCode_running ? inputType("NARS Type(OpenNARS/ONA/Python/Junars): ") : "ONA"
    isempty(type) && (type = "ONA")
    # 检验合法性
    isvalid(type) && break
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
console = Console(
    type,
    path,
    "JuNEI.$(nameof(type))> ",
)

not_VSCode_running && launch!(console, "127.0.0.1", 8765)
