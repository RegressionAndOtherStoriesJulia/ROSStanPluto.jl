### A Pluto.jl notebook ###
# v0.19.5

using Markdown
using InteractiveUtils

# ╔═╡ 5084b8f0-65ac-4704-b1fc-2a9008132bd7
using Pkg, DrWatson

# ╔═╡ 550371ad-d411-4e66-9d63-7329322c6ea1
begin
	# Specific to this notebook
    using GLM

    # Specific to ROSStanPluto
    using StanSample
	
	# Graphics related
    using GLMakie
	using Makie
    using AlgebraOfGraphics
		
	# Include basic packages
	using RegressionAndOtherStories
end

# ╔═╡ 2580c05d-0b53-44d4-a137-45354270e899
md"#### In `Regression and Other Stories`, mcmc is _just_ a tool. Hence whether one uses Stan or Turing is not the main focus of the book. This notebook uses `ElectionsEconomy: hibbs.csv` to illustrate how Stan and other tools are used in the Julia _project_ ROSStanPluto.jl."

# ╔═╡ 62150db9-7078-4ab9-b193-63ec2a721dd2
md" ##### Over time I will expand below the list of topics:

1. Stan (StanSample.jl, ...)
2. Using median and mad to summarize a posterior distribution.
3. ...
4. Model comparison (TBD)
5. DAGs (TBD)
6. Graphs (TBD)
7. ...

"

# ╔═╡ eb7ea04a-da52-4e69-ac3e-87dc7f014652
md"##### See Chapter 1.2, Figure 1.1 in Regression and Other Stories."

# ╔═╡ cf39df58-3371-4535-88e4-f3f6c0404500
md" ##### Widen the cells."

# ╔═╡ 0616ece8-ccf8-4281-bfed-9c1192edf88e
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
md"###### A typical set of Julia packages to include in notebooks."

# ╔═╡ c2a838eb-eb08-41e8-9ea7-324c4ddf0e99
set_aog_theme!()

# ╔═╡ 5fdc1b11-ce9b-4f67-8e2e-5ab22cd75b70
md"
!!! note

All data files are available (as .csv files) in the data subdirectory of package RegressionAndOtherStories.jl.
"

# ╔═╡ 100e2ea9-17e5-4eef-b880-823311f5d496
ros_datadir()

# ╔═╡ bb6149fe-a599-40d2-bfb1-03c738dd7571
md"
!!! note

After evaluating above cell, use `ros_datadir(\"ElectionsEconomy\", \"hibbs.dat\")` to obtain data."

# ╔═╡ d830f41c-0fb6-4bff-9fe0-0bd51f444779
hibbs = CSV.read(ros_datadir("ElectionsEconomy", "hibbs.csv"), DataFrame)

# ╔═╡ 35bee056-5cd8-48ee-b9c0-74a8b53229bd
hibbs_lm = lm(@formula(vote ~ growth), hibbs)

# ╔═╡ 3c4672aa-d17e-4681-9863-9ee026fefee6
residuals(hibbs_lm)

# ╔═╡ a9970ef7-1e0e-4976-b8c9-1db4dd3a222b
mad(residuals(hibbs_lm))

# ╔═╡ f48df50b-5450-4998-8dab-014c8b9d42a2
std(residuals(hibbs_lm))

# ╔═╡ be41c745-c87d-4f3a-ab4e-a8ae3b9ae091
coef(hibbs_lm)

# ╔═╡ 06ab4f30-68cc-4e35-9fa2-b8f8f25d3776
let
	fig = Figure()
	hibbs.label = string.(hibbs.year)
	xlabel = "Average growth personal income [%]"
	ylabel = "Incumbent's party vote share"
	let
		title = "Forecasting the election from the economy"
		plt = data(hibbs) * 
			mapping(:label => verbatim, (:growth, :vote) => Point) *
			visual(Annotations, textsize=15)
		axis = (; title, xlabel, ylabel)
		draw!(fig[1, 1], plt; axis)
	end
	let
		title = "Data and linear fit"
		cols = mapping(:growth, :vote)
		scat = visual(Scatter) + linear()
		plt = data(hibbs) * cols * scat
		axis = (; title, xlabel, ylabel)
		draw!(fig[1, 2], plt; axis)
		annotations!("vote = 46.2 + 3.0 * growth"; position=(0, 41))
	end
	fig
end

# ╔═╡ ea9f97c9-7179-4e0d-97dc-c294a4df9638
md" #### Below some additional cells demonstrating the use of Stan."

# ╔═╡ 274dc84c-b416-4f9e-8ff2-6ca0f08a40cf
stan1_1 = "
functions {
}
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

# ╔═╡ df07541f-13ec-4192-acde-82c02ab6bcf6
md" #### Priors used in `stan_1_1` above."

# ╔═╡ 1786b700-0d99-4541-87d4-b6308a2331bc
let
	N = 10000
	nt = (
		a = rand(Normal(50, 20), N),
		b = rand(Normal(2, 10), N),
		σ = rand(Exponential(1), N),
	)

	fig = Figure()
	for (i, k) in enumerate(keys(nt))
		plt = data(nt) * mapping(k) * AlgebraOfGraphics.density()
		axis = (; title="Density $k")
		draw!(fig[1, i], plt; axis)
	end
	fig
end

# ╔═╡ 953eea61-f05f-4233-86aa-d5af3b47b41e
begin
	data1_1 = (N=16, vote=hibbs.vote, growth=hibbs.growth)
	m1_1s = SampleModel("hibbs", stan1_1)
	rc = stan_sample(m1_1s; data=data1_1)
end;

# ╔═╡ a95062e7-ede7-4be9-8feb-b8de4a999901
read_summary(m1_1s)

# ╔═╡ 77a2a293-e48f-46b5-a104-003772d8a922
read_samples(m1_1s, :dataframe)

# ╔═╡ 9d1a8b9a-2b0c-4b8d-af31-1717e7a5ecd7
if success(rc)
	sdf = read_summary(m1_1s)
	post1_1s_df = read_samples(m1_1s, :dataframe)
	post1_1s_df[!, :chain] = repeat(collect(1:m1_1s.num_chains);
		inner=m1_1s.num_samples)
	post1_1s_df[!, :chain] = categorical(post1_1s_df.chain)
end;

# ╔═╡ 9842ce96-98f9-4a87-9208-d32d16418c15
plot_chains(post1_1s_df, [:a, :b, :sigma])

# ╔═╡ 3a256571-459c-4346-a511-377a273cbb66
trankplot(post1_1s_df, "b")

# ╔═╡ 8abccff4-2015-467e-92d6-067bd8db4e10
let
	N = 100
	x = LinRange(-1, 4, N)
	a = rand(Normal(50, 20), N)
	b = rand(Normal(2, 10), N)
	mat1 = zeros(50, 100)
	for i in 1:50
		mat1[i, :] = a[i] .+ b[i] .* x
	end
	ā = sdf[sdf.parameters .== :a, :mean][1]
	b̄ = sdf[sdf.parameters .== :b, :mean][1]

	# Maybe could use a `link` function here
	mat2 = zeros(50, 100)
	for i in 1:50
		mat2[i, :] = post1_1s_df.a[i] .+ post1_1s_df.b[i] .* x
	end

	fig = Figure()
	xlabel = "Average growth personal income [%]"
	ylabel="Incumbent's party vote share"
	ax = Axis(fig[1, 1]; title="Lines based on prior samples", 
		xlabel, ylabel)
	ylims!(ax, 40, 65)
	series!(fig[1, 1], x, mat1, solid_color=:lightgrey)
	ax = Axis(fig[1, 2]; title="Lines based on posterior samples", 
		xlabel, ylabel)
	series!(fig[1, 2], x, mat2, solid_color=:lightgrey)
	scatter!(hibbs.growth, hibbs.vote)
	lines!(fig[1, 2], x, ā .+ b̄ * x, color = :red)

	fig
end

# ╔═╡ 99259579-97fa-46f5-93b4-710b3180ded2
begin
	fig = Figure()
	hibbs.label = string.(hibbs.year)
	xlabel = "Average growth personal income [%]"
	ylabel="Incumbent's party vote share"

	# Same figure as above
	let
		title = "Forecasting the election from the economy"
		plt = data(hibbs) * 
			mapping(:label => verbatim, (:growth, :vote) => Point) *
			visual(Annotations, textsize=12)
		axis = (; title, xlabel, ylabel)
		draw!(fig[1, 1], plt; axis)
	end

	# Superimpose Stan fit
	let
		ā = sdf[sdf.parameters .== :a, :mean][1]
		b̄ = sdf[sdf.parameters .== :b, :mean][1]
		title = "Compare GLM and Stan fitted lines"
		axis = (; title, xlabel, ylabel)
		df = DataFrame()
		df.x = 0:0.01:4
		df.y = ā .+ b̄ * df.x
		
		cols = mapping(:growth, :vote)
		scat = visual(Scatter) + linear()
		plt1 = data(hibbs) * cols * scat
		plt2 = data(df) * mapping(:x, :y) *
			visual(Lines, color=:red, linestyle=:dash, linewidth=3)
		layers = plt1 + plt2
		draw!(fig[1, 2], layers; axis)
		annotations!("vote = $(round(ā, digits=1)) + $(round(b̄, digits=0)) \
			* growth"; position=(0, 41), textsize=16)
	end
	fig
end

# ╔═╡ f3863e01-deae-4e9d-b044-5515c5a19ab4
describe(post1_1s_df)

# ╔═╡ 5efb6ee3-8f20-42e3-a8af-cbfbb9acd075
post1_1s_df

# ╔═╡ 750a66c1-47bc-466c-a7f1-567640e2e2bb
let
	N = 10000
	nt = (
		a = post1_1s_df.a,
		b = post1_1s_df.b,
		σ = post1_1s_df.sigma,
	)

	fig = Figure()
	for (i, k) in enumerate(keys(nt))
		plt = data(nt) * mapping(k) * AlgebraOfGraphics.density()
		axis = (; title="Density $k")
		draw!(fig[1, i], plt; axis)
	end
	fig
end

# ╔═╡ 95cdfe9f-a06f-49f3-888f-34e47025c810
md"#### Compute median and mad."

# ╔═╡ 063c9089-fc58-4038-9fe8-ce9b90b1a843
mod_sum = model_summary(post1_1s_df, [:a, :b, :sigma])

# ╔═╡ f544db54-86e2-4694-9cac-fc42e2c00e50
mod_sum[:a, :median]

# ╔═╡ 10b925db-5f9c-4603-b49a-bd9b9a2e64d0
md" ##### Alternative computation of mad()."

# ╔═╡ 14cbb5c2-db18-4bc1-a9b9-06ef2ab2ccec
let
	1.483 .* [median(abs.(post1_1s_df.a .- median(post1_1s_df.a))),
	median(abs.(post1_1s_df.b .- median(post1_1s_df.b))),
	median(abs.(post1_1s_df.sigma .- median(post1_1s_df.sigma)))]
end

# ╔═╡ f8e7241f-46a9-4e2b-bdc9-8c63da6bc8ab
md" ##### Quick simulation with median, mad, mean and std of Normal observations."

# ╔═╡ 1f44495d-50cf-4e92-97b2-d19a82c46c78
nt = (x=rand(Normal(5, 2), 10000),)

# ╔═╡ a72ca80f-b42e-4638-8ffd-f23dc70c7bc0
[median(nt.x), mad(nt.x), mean(nt.x), std(nt.x)]

# ╔═╡ 4db28bae-8901-44fe-a479-3272342413c6
sd_mean = round(mad(nt.x)/√10000; digits=2)

# ╔═╡ 0b711521-5b96-429e-8e73-e2d68d94c0ce
median(abs.(nt.x .- median(nt.x)))

# ╔═╡ e193199a-188b-4fa9-ae51-0fce401872e0
1.483 * median(abs.(nt.x .- median(nt.x)))

# ╔═╡ be3898d3-af87-4808-a1a7-4e2e76583ee2
let
	plt = data(nt) * mapping(:x) * AlgebraOfGraphics.density()
	axis = (; title="Density x")
	draw(plt; axis)
end

# ╔═╡ a2be1bd7-6897-438c-928f-787e36134ec7
quantile(nt.x, [0.025, 0.975])

# ╔═╡ 6ce605aa-9504-4ebc-bfdf-c4c54c048647
quantile(nt.x, [0.25, 0.75])

# ╔═╡ 86636b94-f945-4bb1-b7b9-90bc5cc0c836
md" #### A closer look at Stan's summary."

# ╔═╡ 45a307ad-4f6a-4cb6-9182-bda870c42679
sdf

# ╔═╡ 8a04158e-a24d-477f-9cf8-30f062ec29bb
md" ### Convert to a NamedArray."

# ╔═╡ a3277285-5acb-4117-a567-67fdfd2cd4ba
if success(rc)
	sdf1 = model_summary(m1_1s, [:a, :b, :sigma])
end

# ╔═╡ 4abb28cb-8a1f-4680-b39e-ee4166d52d43
md"

!!! note

If parameters are symbols, statistics are strings. If parameters are strings, both are strings."

# ╔═╡ bd15d29b-552e-4f62-bb55-c57dca312b5b
sdf1[:a, "n_eff"]

# ╔═╡ 13d53efa-c7fe-4841-b90a-e0c486a6addc
if success(rc)
	sdf1b = model_summary(m1_1s, ["a", "b", "sigma"])
end

# ╔═╡ 8703f610-71db-46fa-ad6b-d51ccd7b4ff2
sdf2 = model_summary(m1_1s, [:a, :b])

# ╔═╡ 2d1c65ed-f3e4-42fd-bf3f-f89efc543888
sdf3a = model_summary(m1_1s, [:lp__, :a, :b])

# ╔═╡ 6ac30593-ce04-4295-af51-2c094596c61e
sdf3b = model_summary(m1_1s, ["lp__", "a", "b"])

# ╔═╡ 01a11658-5678-49fc-8462-f823c8b21fbc
sdf4 = model_summary(m1_1s, [:lp__, :divergent__, :a, :b]; round_estimates=false)

# ╔═╡ 69024eb9-0681-4229-84b8-e28178de68b3
sdf5 = model_summary(m1_1s, [:lp__, :divergent__, :a, :b])

# ╔═╡ f0fb807a-470f-4279-b77f-516af6fc420b
md" ### Grouped DataFrames."

# ╔═╡ cd6021e3-6f29-464d-b778-5030ad6bf11e
gpdf=groupby(post1_1s_df, :chain)

# ╔═╡ 4cbfa904-adea-4e4e-8a1a-adcdaf61e63d
gpdf[1]

# ╔═╡ e0c715b6-ad06-49fb-b2d1-4b11bf9df63f
gpdf[[(chain=1,), (chain=3,)]]

# ╔═╡ e2d113fe-18cf-4f77-8d0f-6983a444fc07
combine(gpdf, valuecols(gpdf) .=> mean)

# ╔═╡ 2a1c72ff-b15c-4fdb-ae86-28d9d067b8f4
combine(gpdf, valuecols(gpdf) .=> mad)

# ╔═╡ Cell order:
# ╟─2580c05d-0b53-44d4-a137-45354270e899
# ╟─62150db9-7078-4ab9-b193-63ec2a721dd2
# ╟─eb7ea04a-da52-4e69-ac3e-87dc7f014652
# ╟─cf39df58-3371-4535-88e4-f3f6c0404500
# ╠═0616ece8-ccf8-4281-bfed-9c1192edf88e
# ╟─4755dab0-d228-41d3-934a-56f2863a5652
# ╠═5084b8f0-65ac-4704-b1fc-2a9008132bd7
# ╠═550371ad-d411-4e66-9d63-7329322c6ea1
# ╠═c2a838eb-eb08-41e8-9ea7-324c4ddf0e99
# ╟─5fdc1b11-ce9b-4f67-8e2e-5ab22cd75b70
# ╠═100e2ea9-17e5-4eef-b880-823311f5d496
# ╟─bb6149fe-a599-40d2-bfb1-03c738dd7571
# ╠═d830f41c-0fb6-4bff-9fe0-0bd51f444779
# ╠═35bee056-5cd8-48ee-b9c0-74a8b53229bd
# ╠═3c4672aa-d17e-4681-9863-9ee026fefee6
# ╠═a9970ef7-1e0e-4976-b8c9-1db4dd3a222b
# ╠═f48df50b-5450-4998-8dab-014c8b9d42a2
# ╠═be41c745-c87d-4f3a-ab4e-a8ae3b9ae091
# ╠═06ab4f30-68cc-4e35-9fa2-b8f8f25d3776
# ╟─ea9f97c9-7179-4e0d-97dc-c294a4df9638
# ╠═274dc84c-b416-4f9e-8ff2-6ca0f08a40cf
# ╟─df07541f-13ec-4192-acde-82c02ab6bcf6
# ╠═1786b700-0d99-4541-87d4-b6308a2331bc
# ╠═953eea61-f05f-4233-86aa-d5af3b47b41e
# ╠═a95062e7-ede7-4be9-8feb-b8de4a999901
# ╠═77a2a293-e48f-46b5-a104-003772d8a922
# ╠═9d1a8b9a-2b0c-4b8d-af31-1717e7a5ecd7
# ╠═9842ce96-98f9-4a87-9208-d32d16418c15
# ╠═3a256571-459c-4346-a511-377a273cbb66
# ╠═8abccff4-2015-467e-92d6-067bd8db4e10
# ╠═99259579-97fa-46f5-93b4-710b3180ded2
# ╠═f3863e01-deae-4e9d-b044-5515c5a19ab4
# ╠═5efb6ee3-8f20-42e3-a8af-cbfbb9acd075
# ╠═750a66c1-47bc-466c-a7f1-567640e2e2bb
# ╟─95cdfe9f-a06f-49f3-888f-34e47025c810
# ╠═063c9089-fc58-4038-9fe8-ce9b90b1a843
# ╠═f544db54-86e2-4694-9cac-fc42e2c00e50
# ╟─10b925db-5f9c-4603-b49a-bd9b9a2e64d0
# ╠═14cbb5c2-db18-4bc1-a9b9-06ef2ab2ccec
# ╟─f8e7241f-46a9-4e2b-bdc9-8c63da6bc8ab
# ╠═1f44495d-50cf-4e92-97b2-d19a82c46c78
# ╠═a72ca80f-b42e-4638-8ffd-f23dc70c7bc0
# ╠═4db28bae-8901-44fe-a479-3272342413c6
# ╠═0b711521-5b96-429e-8e73-e2d68d94c0ce
# ╠═e193199a-188b-4fa9-ae51-0fce401872e0
# ╠═be3898d3-af87-4808-a1a7-4e2e76583ee2
# ╠═a2be1bd7-6897-438c-928f-787e36134ec7
# ╠═6ce605aa-9504-4ebc-bfdf-c4c54c048647
# ╟─86636b94-f945-4bb1-b7b9-90bc5cc0c836
# ╠═45a307ad-4f6a-4cb6-9182-bda870c42679
# ╟─8a04158e-a24d-477f-9cf8-30f062ec29bb
# ╠═a3277285-5acb-4117-a567-67fdfd2cd4ba
# ╟─4abb28cb-8a1f-4680-b39e-ee4166d52d43
# ╠═bd15d29b-552e-4f62-bb55-c57dca312b5b
# ╠═13d53efa-c7fe-4841-b90a-e0c486a6addc
# ╠═8703f610-71db-46fa-ad6b-d51ccd7b4ff2
# ╠═2d1c65ed-f3e4-42fd-bf3f-f89efc543888
# ╠═6ac30593-ce04-4295-af51-2c094596c61e
# ╠═01a11658-5678-49fc-8462-f823c8b21fbc
# ╠═69024eb9-0681-4229-84b8-e28178de68b3
# ╟─f0fb807a-470f-4279-b77f-516af6fc420b
# ╠═cd6021e3-6f29-464d-b778-5030ad6bf11e
# ╠═4cbfa904-adea-4e4e-8a1a-adcdaf61e63d
# ╠═e0c715b6-ad06-49fb-b2d1-4b11bf9df63f
# ╠═e2d113fe-18cf-4f77-8d0f-6983a444fc07
# ╠═2a1c72ff-b15c-4fdb-ae86-28d9d067b8f4
