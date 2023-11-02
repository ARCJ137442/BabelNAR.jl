# ! be included in: CIN.jl @ module CIN

# 导出
export CINConfig, CINConfigDict, @CINConfig_str

"""CINConfig
「CIN（启动）配置」的实现
- 配置一个CIN的启动、运作行为，以及其处理函数
  - 这种加载是**一次性**的：一旦配置被加载，后续对配置的修改将**不再保证**「能及时更新到CIN」
- 包含对应PyNEI中的「template_语句」常量集
- 使用「字符串函数」封装模板
    - 因：Julia对「格式化字符串」支持不良
        - 没法使用「%s」组成「模板字符串」
    - 使用方法：直接封装一个「字符串生成函数」
        - 输入：若无特殊说明，则为对应的一个参数
        - 输出：字符串
- 亦封装「从『操作字符串』中截取操作」的部分

# ! 现在一个「CIN配置」不再和一个「CIN类型」绑定
## * 亦即：可以对每个NARS程序使用不同的配置进行管理

TODO: 目前的「配置机制」仍显杂乱，仍需优化重构整理
"""
struct CINConfig{
    ProgramType<:Type,
    LaunchArgGeneratorF<:Function, #启动参数生成函数
    OperationCatchF<:Function, # 捕捉操作的函数
    NAIRInterpreterF<:Function} # 指令转换的函数

    #= 程序特性 =#

    """
    用于构造一个「`CINProgram`实例」的构造函数
    对应PyNEI中的「TYPE_CIN_DICT」，存储Type以达到索引「目标类构造方法」的目的
    - @method (type::String, config::CINConfig, executable_path::String) -> CINProgram
    """
    program_type::ProgramType

    raw"""
    启动函数
    - @method (executable_path::String, args...; kwargs...) -> Tuple{Cmd,Vector{String}}
      - (可执行文件路径, 其它有序或无序参数)⇒(执行用Cmd, 初始cmd命令序列)
      - @example (path::String) -> (`java -jar $path`, ["*volume=0"])
      - 对应PyNEI中被各个类实现的「launch_program」函数
    """ # *【2023-11-01 21:18:33】💭这里Julia（语法功能/扩展）和TypeScript的差别就是，Julia比较难构造「see also」或类似「{@link XXX}」的结构
    launch_arg_generator::LaunchArgGeneratorF

    """
    对应PyNEI中被各个类实现的「catch_operation」函数（现需要直接从字符串中获得操作）
    - @method line::String -> Union{NARSOperation, Nothing}
      - 包含「空操作」即nothing
    """
    operation_catch::OperationCatchF

    """
    用于把NAIR命令转换为直接输入到CIN的命令
    - @method (cmd::NAVM.NAIR_CMD) -> String
    - @example `NSE <A --> B>.` ⇒ `(A --> B).`

    # !【2023-11-02 00:51:59】目前这里涉及到了`NAVM`包，但API暂且并不需要直接依赖它
    # * 所以也无需依赖`JuNarsese`和`JuNarseseParsers`
    """
    NAIR_interpreter::NAIRInterpreterF

    # !【2023-11-01 20:40:45】至于「语句模板」模块，现不再于BabelNAR中使用
    ## * BabelNAR只负责「NAIR Cmd的输入输出」
    ## * 这些有关Narsese和NAL的问题，交给更高层次的「外部接口」解决

    """
    基于「命名参数」的内部构造方法
    - @example `args` [1,2,3] | Dict(:a => 1, :b => 2)
    """
    function CINConfig(;
        # ! 以下全为可变参数
        program_type::ProgramType,
        launch_arg_generator::LaunchArgGeneratorF,
        operation_catch::OperationCatchF,
        NAIR_interpreter::NAIRInterpreterF
    ) where {
        #= 类型参数 =#
        ProgramType<:Type,
        LaunchArgGeneratorF<:Function,
        OperationCatchF<:Function,
        NAIRInterpreterF<:Function}
        return new{
            ProgramType,
            LaunchArgGeneratorF,
            OperationCatchF,
            NAIRInterpreterF
        }(
            program_type,
            launch_arg_generator,
            operation_catch,
            NAIR_interpreter
        )
    end
end

"""
外部构造方法：可迭代对象⇒有序参数展开
- @example `args` [1,2,3]
"""
CINConfig(args) = CINConfig(args...)

"""外部构造方法：可迭代对象⇒参数展开（支持无序参数）
- @example `kwargs` (a=1, b=2) | Dict(:a => 1, :b => 2)
"""
CINConfig(args, kwargs) = CINConfig(args...; kwargs...)


"CIN配置字典的类型：NARS类型 => CIN配置"
const CINConfigDict::Type = Dict{String,CINConfig}

#= 注：不把以下代码放到templates.jl中，因为：
- Program要用到NARSType
- 以下代码要等Register注册
- Register要等Program类声明
因此不能放在一个文件中
=#
begin # * 功能

    "Type→Register（需要字典）"
    Base.convert(
        ::Core.Type{CINConfig},
        type::String,
        register_dict::CINConfigDict
    )::CINConfig = register_dict[type]

    "验证合法性"
    Base.isvalid(type::String, register_dict::CINConfigDict)::Bool = haskey(register_dict, type)

    #= # !【2023-11-01 23:42:27】迁移了所有涉及`CINProgram`的函数，解耦合

    =#

end