using GLM
using DataFrames
using DataFramesMeta
using StatsModels
using StanSample
using StableRNGs

rng = StableRNG(1)

df = DataFrame(
    y = rand(rng, 9), 
    a = 1:9, 
    b = rand(rng, 9), 
    c = repeat(["d","e","f"], 3))

f = @formula(y ~ 1 + a + b + c + b&c)
f = apply_schema(f, schema(f, df))

f |> display
println()

resp, pred = modelcols(f, df);

pred |> display
println()

coefnames(f) |> display
println()

lm1 = lm(@formula(log(y) ~ 1 + a + b), df)
lm1 |> display
println()
