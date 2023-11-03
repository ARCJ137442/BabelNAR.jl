# 引入配置
include(raw"test_console_NAVM$config.jl")
include(raw"test_console_ServerOutFormat$config.jl")

# 最终引入
include("test_console_WSServer.jl")
