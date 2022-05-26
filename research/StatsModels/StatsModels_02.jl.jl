using CSV
using GLM
using DataFrames
using DataFramesMeta
using StatsModels
using StatsBase
using StanSample
using StableRNGs

rng = StableRNG(1)

src_path = ENV["JULIA_ROS_HOME"]
ros_path(parts...) = normpath(joinpath(src_path, parts...))
ros_data(dataset, parts...) = normpath(joinpath(src_path, dataset, "data",
    parts...))

df = CSV.read(ros_data("ElectionsEconomy", "hibbs.dat"), DataFrame;
    delim=" ")

f = @formula(vote ~ 1 + growth)
f = apply_schema(f, schema(f, df))

f |> display
println()

resp, pred = modelcols(f, df);

resp |> display
println()

pred |> display
println()

X = modelmatrix(f, df)
X |> display
println()

X \ resp |> display
println()

coefnames(f) |> display
println()

lm1 = lm(f, df)
lm1 |> display
println()

stan1_1 = "
data {
    int<lower=1> N;      // total number of observations
    vector[N] growth;    // Independent variable: growth
    vector[N] vote;      // Dependent variable: votes 
}
parameters {
    real b;              // Coefficient independent variable
    real a;              // Intercept
    real<lower=0> sigma; // dispersion parameter
}
model {
    vector[N] mu;
    mu = a + b * growth;

    // priors including constants
    a ~ normal(50, 20);
    b ~ normal(2, 10);
    sigma ~ exponential(1);

    // likelihood including constants
    vote ~ normal(mu, sigma);
}";

data = (N=16, vote=df.vote, growth=df.growth);
m1_1s = SampleModel("hibbs", stan1_1)
rc = stan_sample(m1_1s; data)

if success(rc)
    sdf = read_summary(m1_1s)
    sdf[8:10, :] |> display
    println()
    post1_1s = read_samples(m1_1s, :dataframe)
    describe(post1_1s) |> display
    println()
end

(median=median(post1_1s.a), mad=mad(post1_1s.a), std=std(post1_1s.a)) |> display
println()
(median=median(post1_1s.b), mad=mad(post1_1s.b), std=std(post1_1s.b)) |> display
