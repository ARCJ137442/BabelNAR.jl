export NARSOutputType

"""
采自PyNARS，用于统一所有CIN的「输出类型」标签
- 后续将传递到Matriangle等NARS测试环境中
- # ! 还是不建议使用@enum宏，因为这玩意儿没法存字符串
    - # * 无语之@enum宏只支持数值类型
"""
NARSOutputType = (;
    IN = "IN",
    OUT = "OUT",
    ERROR = "ERROR",
    ANSWER = "ANSWER",
    ACHIEVED = "ACHIEVED",
    EXE = "EXE",
    INFO = "INFO",
    COMMENT = "COMMENT",
    ANTICIPATE = "ANTICIPATE",
    OTHER = "OTHER"
    # *【2024-01-25 15:27:03】`OTHER`类型用于存储「暂无法格式化识别」的其它信息
    #     * @example 如OpenNARS的`executed based on`（操作执行的证据基础，用于验证「系统是否习得知识」）
    #     * 🎯用于在后续实验中提取「推理器特异」的实用信息
)

NARSOperationVec = String[]
