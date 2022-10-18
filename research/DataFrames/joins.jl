df1 = DataFrame(
           year = 1965:1970,
           G = rand(6),
       )

df2 = DataFrame(
           year = repeat(1965:1970, inner=2),
           id = rand(10_000:13_000, 12),
           s = rand(12),
       )

leftjoin(df2, df1; on=:year)
