# * 导入自身源码文件
push!(LOAD_PATH, "../", "../src/")

# 导入依赖

println('='^16 * "Test of BabelNAR" * '='^16)

using BabelNAR: BabelNAR, main
# using NAVM

main()

# @info NAVM names(NAVM)
@info BabelNAR names(BabelNAR)