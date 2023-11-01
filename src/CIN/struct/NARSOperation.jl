# ! be included in: CIN.jl @ module CIN

# 导出
export NARSOperation, @NARSOperation_str, has_parameters, to_literal


raw"""NARSOperation
「NARS操作」本质上是
- 一个「长度>1」的列表，首个参数是「操作符字符串」、后续参数是「参数项字符串」
  - # ! 「操作符」的字符串**不带尖号**，「带尖号版本」建议调用`to_literal(op)`将其转换为「全Narsese字符串数组」
  - @example `["op", "arg1_atom", "(*, arg2_component1, arg2_component2)", "{arg3}", ...]`
  - 只存储「操作符」和「所有参数项」的**字符串形式**，具体解析交给JuNarsese处理
  - # * 「操作符」的字串长度可以为零，但这样的操作符（一般）没有意义，也难以被构造出来（CommonNarsese不支持）
- 存储一个Narsese意义上的「操作」
  - 如Narsese `<(*, args) --> ^op>` | `op(args)`

# 主要功能：记录其名字，并方便语法嵌入
- 附加功能：记录操作执行的参数（词项组）

实用举例：
- Operation("pick", ("{SELF}", "{t002}"))
    - 源自OpenNARS「EXE: $0.10;0.00;0.08$ ^pick([{SELF}, {t002}])=null」

"""
struct Operation
    "操作名"
    operator_name::String

    "操作参数" # 使用「Vararg{类型}」表示「任意长度的指定类型」（包括空元组Tuple{}）
    parameters::Tuple{Vararg{String}}

    """
    默认构造方法：接受一个名称与一个元组
    - *优先匹配*（避免下面的构造方法递归）
    - 为何是内部构造方法？避免：
        - 传入SubString报错：String方法
        - 空字串参数：filter方法（预处理）
    """
    Operation(name::Union{AbstractString,Symbol}, parameters::Tuple{Vararg{String}}) = new(
        string(name),
        filter(!isempty, parameters) # filter过滤掉「空字符串」，使空字符串无效化
    )
end

"通用（外部）构造方法：名称+任意数量元组"
Operation(name::Union{AbstractString,Symbol}, parameters::Vararg{String}) = Operation(name, parameters)

"自动转换"

"快捷定义方式@宏：定义一个「无参操作」（只有一个操作符）"
macro Operation_str(str::String)
    :(Operation($str))
end

# !【2023-11-01 21:11:02】现在`EMPTY_Operation`使用nothing代替

"检测「是否有参数」"
has_parameters(op::Operation) = !isempty(op.parameters)

"返回名称"
Base.nameof(op::Operation) = op.operator_name
# ↑必须使用Base

"传递「索引读取」到「参数集」"
Base.getindex(op::Operation, i) = Base.getindex(op.parameters, i)

"字符串转化&插值"
Base.string(op::Operation)::String = "$(nameof(op))($(join(op.parameters,',')))"

"格式化显示：名称+参数"
Base.repr(op::Operation)::String = "<NARS Operation $(string(op))>"

"控制在show中的显示形式"
@redefine_show_to_to_repr op::Operation

"转换为「字符串向量」（操作符不带尖号）"
Base.Vector(op::Operation) = [nameof(op), op.parameters...]