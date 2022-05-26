using GLM
using DataFrames
using DataFramesMeta
using StatsModels
using StanSample
using StableRNGs

d = DataFrame(a = [1, 2, 3], b = ["x", "y", "z"])

d2 = d[d.a .> 1 .|| d.b .== "z", :]
d2 |> display

d3 = @chain d begin
   @subset @byrow begin
       :a > 1 || :a == "z"
   end
end
d3 |> display

x = @chain [1, 2, 3] filter(!=(2), _) sqrt.(_) sum
x |> display

x == sum(sqrt.(filter(!=(2), [1, 2, 3])))
x |> display

x = @chain begin
  [1, 2, 3]
  filter(!=(2), _)
  sqrt.(_)
  #sum
end
x |> display

x = @chain [1, 2, 3] begin
  filter(!=(2), _)
  sqrt.(_)
  sum
end
x |> display
