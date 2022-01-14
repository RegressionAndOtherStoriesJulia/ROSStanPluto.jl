# Intro

using Pkg, DrWatson

begin
    using CSV, DelimitedFiles, Unicode
    using DataFrames
    using StanSample
    using StatsPlots
end

md"### Overview"

md"""#### 1.1 The three challenges of statistics

The three challenges of statistical inference are:

1. Generalizing from sample to population, a problem that is associated with survey sampling but actually arises in nearly every application of statistical inference;
2. Generalizing from treatment to control group, a problem that is associated with causal inference, which is implicitly or explicitly part of the interpretation of most regressions we have seen; and
3, Generalizing from observed measurements to the underlying constructs of interest, as most of the time our data do not record exactly what we would ideally like to study. (p. 3, emphasis in the original)
"""

md"""#### 1.2 Why learn regression?

“Regression is a method that allows researchers to summarize how predictions or average values of an outcome vary across individuals defined by a set of predictors” (p. 4, emphasis in the original). To get a sense, load the hibbs.dat data.
"""

ROS_dir = "/Users/rob/Projects/R/Ros-Examples/ElectionsEconomy/data/"

hibbs = CSV.read(joinpath(ROS_dir, "hibbs.dat"), DataFrame; delim=" ")

df |> display
