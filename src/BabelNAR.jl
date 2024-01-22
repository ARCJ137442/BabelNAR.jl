# ! root module

module BabelNAR

# 导入 #
using Reexport: @reexport

# 引入 & 导出 #

# * 引入但不导出`Utils`模块 * #
include("Utils.jl")

# * 引入并导出`CIN`模块 * #
include("CIN/CIN.jl")
@reexport using ..CIN # ! 引入在主包内，故需要两个点

#= # * 引入并导出「具体CIN（配置）注册」 * #
include("implements/implements.jl")
@reexport using ..implements =#
# !【2023-11-02 00:49:56】↑现在把「具体实现」独立出来，以便分离和扩展

# * 引入并导出「CIN 应用/扩展」 * #
include("extension/extension.jl")
@reexport using ..extension


"测试用的「主函数」"
function main()
    @info "The Main Function of BabelNAR" names(Utils) names(CIN) names(extension)
    @info "It is done." names(BabelNAR)
end

end # module BabelNAR
