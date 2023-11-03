export NARSOutputType

"""
采自PyNARS，用于统一所有CIN的「输出类型」标签
- 后续将传递到Matriangle等NARS测试环境中
- # ! 还是不建议使用@enum宏，因为这玩意儿没法存字符串
    - # * 无语之@enum宏只支持数值类型
"""
NARSOutputType = (;
    IN="IN",
    OUT="OUT",
    ERROR="ERROR",
    ANSWER="ANSWER",
    ACHIEVED="ACHIEVED",
    EXE="EXE",
    INFO="INFO",
    COMMENT="COMMENT"
)

NARSOperationVec = String[]