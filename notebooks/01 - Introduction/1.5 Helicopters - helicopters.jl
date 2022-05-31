### A Pluto.jl notebook ###
# v0.19.5

using Markdown
using InteractiveUtils

# ╔═╡ 5084b8f0-65ac-4704-b1fc-2a9008132bd7
using Pkg, DrWatson

# ╔═╡ f27de704-7bc0-4e11-ae4b-a18ee0097782
begin
	# Specific to this notebook
    using GLM

	# Specific to ROSStanPluto
    using StanSample
	
	# Graphics related
	using GLMakie
	using Makie
    using AlgebraOfGraphics
	set_aog_theme!()

	# Common data files and functions
	using RegressionAndOtherStories
end

# ╔═╡ 0391fc17-09b7-47d7-b799-6dc6de13e82b
md"## Helicopters: helicopters.jl"

# ╔═╡ eb7ea04a-da52-4e69-ac3e-87dc7f014652
md"##### See Chapter 1.8 in Regression and Other Stories."

# ╔═╡ b95f0107-fdc3-4e90-95ef-b4ccb9bbf5b7
html"""
<style>
	main {
		margin: 0 auto;
		max-width: 2000px;
    	padding-left: max(160px, 10%);
    	padding-right: max(160px, 10%);
	}
</style>
"""

# ╔═╡ 4755dab0-d228-41d3-934a-56f2863a5652
md"###### Included Julia packages."

# ╔═╡ 74882014-7ec5-42c3-ac70-fd532d269ac4
helicopters = CSV.read(ros_datadir("Helicopters", "helicopters.csv"), DataFrame)

# ╔═╡ b1d5448e-7dc0-4d62-9f7f-cf5093fbcb71
md" ##### Simulate 40 helicopters."

# ╔═╡ a078b55c-d06a-4d1b-a9dd-b87963df3d6c
begin
	helis = DataFrame(width_cm = rand(Normal(5, 2), 40), length_cm = rand(Normal(10, 4), 40))
	helis.time_sec = 0.5 .+ 0.04 .* helis.width_cm .+ 0.08 .* helis.length_cm .+ 0.1 .* rand(Normal(0, 1), 40)
	helis
end

# ╔═╡ a80b9f49-5949-494c-80e1-153b6973db62
stan1_2 = "
data {
	int N;
	vector[N] w;
	vector[N] l;
	vector[N] y;
}
parameters {
	real a;
	real b;
	real c;
	real sigma;
}
model {
	// Priors
	a ~ normal(10, 5);
	b ~ normal(0, 5);
	sigma ~ exponential(1);

	// Likelihood time on width
	vector[N] mu;
	for ( i in 1:N )
		mu[i] = a + b * w[i] + c * l[i];
	y ~ normal(mu, sigma);
}
";

# ╔═╡ 7001ad1f-419b-448e-bacf-f79995d533ee
begin
	data1_2 = (N = nrow(helis), y = helis.time_sec, w = helis.width_cm, l = helis.length_cm)
	m1_2s = SampleModel("m1.2s", stan1_2);
	rc1_2 = stan_sample(m1_2s; data=data1_2)
end;

# ╔═╡ 20dea214-9997-4a6e-8d15-7a2bc42d33b6
if success(rc1_2)
	post1_2s_df = read_samples(m1_2s, :dataframe)
	post1_2s_df[!, :chain] = repeat(collect(1:m1_2s.num_chains);
		inner=m1_2s.num_samples)
	post1_2s_df[!, :chain] = categorical(post1_2s_df.chain)
	post1_2s_df
end

# ╔═╡ 8f825b88-b9ae-4cbf-b27f-946d6ef7c316
	means = mean(Array(post1_2s_df); dims=1)

# ╔═╡ 4a69ab96-7985-4d25-9b8d-5dbfa16d35e4
plot_chains(post1_2s_df, [:a, :b, :c])

# ╔═╡ 66c5408b-6a18-41e7-88ce-b3427a3961e1
let
	fig = Figure()
	
	let
		plt = data(post1_2s_df) * visual(Lines) * mapping(:sigma; color=:chain)
		axis = (; ylabel="sigma", xlabel="Iteration", title="Traces")
  		draw!(fig[1, 1], plt; axis)
	end
	
	let
		plt = data(post1_2s_df) * mapping(:sigma; color=:chain) * AlgebraOfGraphics.density()
		axis = (; title="Density sigma")
		draw!(fig[1, 2], plt; axis)
	end

	fig
end

# ╔═╡ be8ef59e-ba27-4432-8eed-99834498c5f3
begin
	w = 1.0:0.01:8.0
	l = 6.0:0.01:15.0
	f = Figure()
	ax = Axis(f[1, 1], title = "Time on width or width",
		xlabel = "Width/Length", ylabel = "Time in the air")
	lines!(w, mean(post1_2s_df.a) .+ mean(post1_2s_df.b) .* w .+ mean(post1_2s_df.c))
	lines!(l, mean(post1_2s_df.a) .+ mean(post1_2s_df.c) .* l .+ mean(post1_2s_df.b))

	current_figure()
end

# ╔═╡ 535ff11e-51f3-444b-8db4-f60ddc98ce37
mean(post1_2s_df.a)

# ╔═╡ Cell order:
# ╟─0391fc17-09b7-47d7-b799-6dc6de13e82b
# ╟─eb7ea04a-da52-4e69-ac3e-87dc7f014652
# ╠═b95f0107-fdc3-4e90-95ef-b4ccb9bbf5b7
# ╟─4755dab0-d228-41d3-934a-56f2863a5652
# ╠═5084b8f0-65ac-4704-b1fc-2a9008132bd7
# ╠═f27de704-7bc0-4e11-ae4b-a18ee0097782
# ╠═74882014-7ec5-42c3-ac70-fd532d269ac4
# ╟─b1d5448e-7dc0-4d62-9f7f-cf5093fbcb71
# ╠═a078b55c-d06a-4d1b-a9dd-b87963df3d6c
# ╠═a80b9f49-5949-494c-80e1-153b6973db62
# ╠═7001ad1f-419b-448e-bacf-f79995d533ee
# ╠═20dea214-9997-4a6e-8d15-7a2bc42d33b6
# ╠═8f825b88-b9ae-4cbf-b27f-946d6ef7c316
# ╠═4a69ab96-7985-4d25-9b8d-5dbfa16d35e4
# ╠═66c5408b-6a18-41e7-88ce-b3427a3961e1
# ╠═be8ef59e-ba27-4432-8eed-99834498c5f3
# ╠═535ff11e-51f3-444b-8db4-f60ddc98ce37
