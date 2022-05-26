using DataFrames
using CSV
using Dates
using StatsPlots
using LaTeXStrings

##Plots.default(size=(600,300))
## Plots.GRBackend()

date_min = 1995
date_max = 2055

##
## UL 90% CL B(tau -> mu gamma)
##
## 2e-9      0    0     "SuperB 75ab-1"  2025 guest
##

data = """
val       uncp uncm  event             year type
4.4e-8    0    0     "BaBar 2010"      2010 pub
4.5e-8    0    0     "Belle 2008"      2008 pub
1e-9      0    0     "BelleII"         2025 est
5e-9      0    0     "SCT/STCF"        2030 guest
1e-9      0    0     "CEPC (Z)"        2035 guest
2e-9      0    0     "FCC-ee (Z)"      2040 est
"""

df = DataFrame(CSV.File(IOBuffer(data), delim=' ', ignorerepeated=true))
df = dropmissing(df, disallowmissing=true)

type_to_color = Dict("pub" => :green, "est" => :red, "guest" => :orange)
df.color = [type_to_color[type] for type in df.type]

@df df Plots.plot(
  :year,
  :val,
  series_annotations = text.(:event, :left, :bottom, rotation=45, 9),
  title=L"${\cal B}(\tau\rightarrow \mu\gamma)$",
  ## xlabel="year",
  ylabel="90% CL UL",
  xlims=(date_min, date_max),
  ylims=(2e-10, 1e-6),
  xrotation=30,
  color = :color,
  msw = 0,
  legend = false,
  seriestype=:scatter,
  yscale=:log10,
  markersize = 7,
  framestyle = (:box, :grid)
)
