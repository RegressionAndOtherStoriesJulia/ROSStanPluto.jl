# m6.7s.jl

using Pkg, DrWatson

@quickactivate "AoG"
using DataFrames, NamedTupleTools
using StanSample, Distributions
using Makie, AlgebraOfGraphics, CairoMakie
using CategoricalArrays, Random
using AlgebraOfGraphics: density

N = 100
df = DataFrame(
  :h0 => rand(Normal(10,2 ), N),
  :treatment => vcat(zeros(Int, Int(N/2)), ones(Int, Int(N/2)))
);
df[!, :fungus] = [rand(Binomial(1, 0.5 - 0.4 * df[i, :treatment]), 1)[1] for i in 1:N]
df[!, :h1] = [df[i, :h0] + rand(Normal(5 - 3 * df[i, :fungus]), 1)[1] for i in 1:N]

stan6_7 = "
data {
  int <lower=1> N;
  vector[N] h0;
  vector[N] h1;
  vector[N] treatment;
  vector[N] fungus;
}
parameters{
  real a;
  real bt;
  real bf;
  real<lower=0> sigma;
}
model {
  vector[N] mu;
  vector[N] p;
  a ~ lognormal(0, 0.2);
  bt ~ normal(0, 0.5);
  bf ~ normal(0, 0.5);
  sigma ~ exponential(1);
  for ( i in 1:N ) {
    p[i] = a + bt*treatment[i] + bf*fungus[i];
    mu[i] = h0[i] * p[i];
  }
  h1 ~ normal(mu, sigma);
}
"

data = Dict(
  :N => nrow(df),
  :h0 => df[:, :h0],
  :h1 => df[:, :h1],
  :fungus => df[:, :fungus],
  :treatment => df[:, :treatment]
)

m6_7s = SampleModel("m6.7", stan6_7)
rc6_7s = stan_sample(m6_7s; data)

if success(rc6_7s)
  post6_7s_df = read_samples(m6_7s; output_format=:dataframe)
  post6_7s_df[!, :chain] = repeat(collect(1:m6_7s.n_chains[1]);
    inner=m6_7s.method.num_samples)
  post6_7s_df[!, :chain] = categorical(post6_7s_df.chain)
end;

if success(rc6_7s)
  let
    fig = Figure()
    
    let
      plt = data(post6_7s_df) * visual(Lines) * mapping(:a; color=:chain)
      axis = (; title="Traces")
      draw!(fig[1, 1], plt; axis)
    end
    
    let
      plt = data(post6_7s_df) * mapping(:a; color=:chain) * density()
      axis = (; title="Density")
      draw!(fig[1, 2], plt; axis)
    end
    

    let
      plt = data(post6_7s_df) * visual(Lines) * mapping(:bt, color=:chain)
      axis = (; ylabel="Draw", title="Traces")
        draw!(fig[2, 1], plt; axis)
    end
    
    let
      plt = data(post6_7s_df) * mapping(:bt; color=:chain) * density()
      axis = (; title="Density")
      draw!(fig[2, 2], plt; axis)
    end
    
    let
      plt = data(post6_7s_df) * visual(Lines) * mapping(:bf, color=:chain)
      axis = (; ylabel="Draw", title="Traces")
        draw!(fig[3, 1], plt; axis)
    end
    
    let
      plt = data(post6_7s_df) * mapping(:bf; color=:chain) * density()
      axis = (; title="Density")
      draw!(fig[3, 2], plt; axis)
    end

    fig
  end
end

stan6_8 = "
data {
  int <lower=1> N;
  vector[N] h0;
  vector[N] h1;
  vector[N] treatment;
}
parameters{
  real a;
  real bt;
  real<lower=0> sigma;
}
model {
  vector[N] mu;
  vector[N] p;
  a ~ lognormal(0, 0.2);
  bt ~ normal(0, 0.5);
  sigma ~ exponential(1);
  for ( i in 1:N ) {
    p[i] = a + bt*treatment[i];
    mu[i] = h0[i] * p[i];
  }
  h1 ~ normal(mu, sigma);
}
"

m6_8s = SampleModel("m6.8s", stan6_8)
rc6_8s = stan_sample(m6_8s; data)

if success(rc6_8s)
  part6_8s = read_samples(m6_8s; output_format=:particles);
  part6_8s |> display
end



# End of m6.7s.jl
