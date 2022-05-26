### A Pluto.jl notebook ###
# v0.17.7

using Markdown
using InteractiveUtils

# ╔═╡ 6b5dd9ed-c886-42d4-8aad-de5fc0a098be
using Pkg, DrWatson

# ╔═╡ c9f68924-691e-46e3-a5fa-4cf7af78dedf
begin
	using DataFrames, NamedTupleTools
	using StanSample, Distributions
	using Makie, AlgebraOfGraphics, GLMakie
	using CategoricalArrays, Random
	using AlgebraOfGraphics: density
end

# ╔═╡ 7ce3e13b-7aa0-437a-a92f-291b341e4f3e
md" #### Plot of chains example"

# ╔═╡ 1da8223d-7587-47a7-8dca-1449d16cb0ba
begin
	N = 100
	df = DataFrame(
	  :h0 => rand(Normal(10,2 ), N),
	  :treatment => vcat(zeros(Int, Int(N/2)), ones(Int, Int(N/2)))
	);
	df[!, :fungus] =
		[rand(Binomial(1, 0.5 - 0.4 * df[i, :treatment]), 1)[1] for i in 1:N]
	df[!, :h1] =
		[df[i, :h0] + rand(Normal(5 - 3 * df[i, :fungus]), 1)[1] for i in 1:N]
end;

# ╔═╡ ba29663b-498b-4700-9a9d-0a4c607fac75
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
";

# ╔═╡ 93d84fe8-2783-41d9-ade4-7fa7016af156
m6_7_data = Dict(
  :N => nrow(df),
  :h0 => df[:, :h0],
  :h1 => df[:, :h1],
  :fungus => df[:, :fungus],
  :treatment => df[:, :treatment]
);

# ╔═╡ 2b662fbf-20c9-46ff-a692-533c8f2a6294
begin
	m6_7s = SampleModel("m6.7", stan6_7)
	rc6_7s = stan_sample(m6_7s; data=m6_7_data)
end;

# ╔═╡ 14463efc-79e2-4cb9-a04a-c0ae6442f8e1
if success(rc6_7s)
  post6_7s_df = read_samples(m6_7s, :dataframe)
end

# ╔═╡ 5618b97b-0c08-4959-9013-eaba8076ee8e
begin
  post6_7s_df[!, :chain] = repeat(collect(1:m6_7s.num_cpp_chains);
		inner=m6_7s.num_samples)
  post6_7s_df[!, :chain] = categorical(post6_7s_df.chain)
end;

# ╔═╡ 34f444a7-4835-471b-ab4f-6ed1e7e01f09
if success(rc6_7s)
	f4 = let
	  layers = data(post6_7s_df) * mapping(:bf; color=:chain) * density()
	  axis = (; ylabel="Density")
	  draw(layers; axis)
	end
end

# ╔═╡ 88edb261-7e66-49a6-9319-4af603e9c885
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
	
	fig
end

# ╔═╡ 08cdfdfc-e52b-4e0c-ae78-cd794c1a3b01
let
	fig = Figure(;)
	let
		plt = data(post6_7s_df) * visual(Lines) * mapping(:bt, color=:chain)
		axis = (; ylabel="Draw", title="Traces")
  		draw!(fig[1, 1], plt; axis)
	end
	
	let
		plt = data(post6_7s_df) * mapping(:bt; color=:chain) * density()
		axis = (; title="Density")
		draw!(fig[1, 2], plt; axis)
	end
	
	let
		plt = data(post6_7s_df) * visual(Lines) * mapping(:bf, color=:chain)
		axis = (; ylabel="Draw", title="Traces")
  		draw!(fig[2, 1], plt; axis)
	end
	
	let
		plt = data(post6_7s_df) * mapping(:bf; color=:chain) * density()
		axis = (; title="Density")
		draw!(fig[2, 2], plt; axis)
	end

	fig
end

# ╔═╡ 8ad10c4d-ff27-4b64-8302-28a0408b2aa8
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

# ╔═╡ c6fa5e59-3fcc-4ea6-bc6a-d903de78a882
md" #### End of plot of chains example"

# ╔═╡ Cell order:
# ╟─7ce3e13b-7aa0-437a-a92f-291b341e4f3e
# ╠═6b5dd9ed-c886-42d4-8aad-de5fc0a098be
# ╠═c9f68924-691e-46e3-a5fa-4cf7af78dedf
# ╠═1da8223d-7587-47a7-8dca-1449d16cb0ba
# ╠═ba29663b-498b-4700-9a9d-0a4c607fac75
# ╠═93d84fe8-2783-41d9-ade4-7fa7016af156
# ╠═2b662fbf-20c9-46ff-a692-533c8f2a6294
# ╠═14463efc-79e2-4cb9-a04a-c0ae6442f8e1
# ╠═5618b97b-0c08-4959-9013-eaba8076ee8e
# ╠═34f444a7-4835-471b-ab4f-6ed1e7e01f09
# ╠═88edb261-7e66-49a6-9319-4af603e9c885
# ╠═08cdfdfc-e52b-4e0c-ae78-cd794c1a3b01
# ╠═8ad10c4d-ff27-4b64-8302-28a0408b2aa8
# ╟─c6fa5e59-3fcc-4ea6-bc6a-d903de78a882
