"覆盖：默认OpenNARS"
main_type(default_type) = "OpenNARS"

"覆盖：使用默认地址"
main_address() = (
    host="127.0.0.1",
    port=8765
)

# 最终引入
include("test_console_WSServer.jl")