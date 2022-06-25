### A Pluto.jl notebook ###
# v0.19.9

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

# ╔═╡ df07541f-13ec-4192-acde-82c02ab6bcf6
md" #### Priors used in the Stan model."

# ╔═╡ f11b4bdc-3ad4-467d-b75c-37da5e9dcb2c
stan1_0 = "
parameters {
	real b;              // Coefficient independent variable
	real a;              // Intercept
	real<lower=0> sigma; // dispersion parameter
}
model {
	// priors including constants
	a ~ normal(50, 20);
	b ~ normal(2, 10);
  	sigma ~ exponential(1);
}";

# ╔═╡ db6a5dab-a738-42d3-a97a-4ca60894b9ca
begin
	m1_0s = SampleModel("hibbs", stan1_0)
	rc1_0s = stan_sample(m1_0s)
	success(rc1_0s) && model_summary(m1_0s)
end

# ╔═╡ 9e471ad3-6c48-4f8a-b204-4ee864837898
post1_0s = read_samples(m1_0s, :dataframe)

# ╔═╡ 10395123-f9c9-441d-a497-cb7be9fa7b18
let
	fig = Figure()
	xlabel = "Average growth personal income [%]"
	ylabel="Incumbent's party vote share"
	ax = Axis(fig[1, 1]; title="Lines based on prior samples", 
		xlabel, ylabel)
	ylims!(ax, 40, 65)
	xrange = LinRange(-1, 4, 200)
	for i = 1:100
		lines!(xrange, post1_0s.a[i] .+ post1_0s.b[i] .* xrange, color = :grey)
	end
	fig
end

# ╔═╡ 1786b700-0d99-4541-87d4-b6308a2331bc
let
	f = Figure()
	ax = Axis(f[1, 1]; title="Density :a")
	density!(f[1, 1], post1_0s.a)
	ax = Axis(f[1, 2]; title="Density :b")
	density!(f[1, 2], post1_0s.b)
	ax = Axis(f[1, 3]; title="Density :sigma")
	density!(f[1, 3], post1_0s.sigma)
	f
end

# ╔═╡ 261c1e49-13be-4950-b211-29c35e0da5e8
md" #### Conditioning based on the available data."

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

# ╔═╡ 953eea61-f05f-4233-86aa-d5af3b47b41e
let
	data = (N=16, vote=hibbs.vote, growth=hibbs.growth)
	global m1_1s = SampleModel("hibbs", stan1_1)
	global rc1_1s = stan_sample(m1_1s; data)
	success(rc1_1s) && model_summary(m1_1s)
end;

# ╔═╡ 77a2a293-e48f-46b5-a104-003772d8a922
read_samples(m1_1s, :dataframe)

# ╔═╡ 9d1a8b9a-2b0c-4b8d-af31-1717e7a5ecd7
if success(rc1_1s)
	sdf = read_summary(m1_1s)
	post1_1s = read_samples(m1_1s, :dataframe)
end

# ╔═╡ 9842ce96-98f9-4a87-9208-d32d16418c15
plot_chains(post1_1s, [:a, :b, :sigma])

# ╔═╡ 3a256571-459c-4346-a511-377a273cbb66
trankplot(post1_1s, "b")

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
		mat2[i, :] = post1_1s.a[i] .+ post1_1s.b[i] .* x
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

# ╔═╡ a872c820-57b6-45d5-a7e9-2ab7349c81e7
let
	f = Figure()
	ax = Axis(f[1, 1]; title="Density :a")
	xlims!(ax, -10, 125)
	density!(post1_0s.a)
	ax = Axis(f[1, 2]; title="Density :b")
	xlims!(ax, -40, 45)
	density!(post1_0s.b)
	ax = Axis(f[1, 3]; title="Density :sigma")
	density!(post1_1s.sigma)
	
	ax = Axis(f[2, 1]; title="Density :a")
	density!(post1_1s.a)
	xlims!(ax, -10, 125)
	ax = Axis(f[2, 2]; title="Density :b")
	xlims!(ax, -40, 45)
	density!(post1_1s.b)
	ax = Axis(f[2, 3]; title="Density :sigma")
	density!(post1_1s.sigma)
	f
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
describe(post1_1s)

# ╔═╡ 5efb6ee3-8f20-42e3-a8af-cbfbb9acd075
ms1_1s = model_summary(post1_1s, [:a, :b, :sigma])

# ╔═╡ 750a66c1-47bc-466c-a7f1-567640e2e2bb
let
	N = 10000
	nt = (
		a = post1_1s.a,
		b = post1_1s.b,
		σ = post1_1s.sigma,
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

# ╔═╡ 10b925db-5f9c-4603-b49a-bd9b9a2e64d0
md" ##### Alternative computation of mad()."

# ╔═╡ 14cbb5c2-db18-4bc1-a9b9-06ef2ab2ccec
let
	1.483 .* [
		median(abs.(post1_1s.a .- median(post1_1s.a))),
		median(abs.(post1_1s.b .- median(post1_1s.b))),
		median(abs.(post1_1s.sigma .- median(post1_1s.sigma)))]
end

# ╔═╡ f1041467-bd19-4ef5-9359-98e38d272142
model_summary(post1_1s, [:a, :b, :sigma])

# ╔═╡ 42bfca0d-cf71-4064-bbd6-1466c1267d9a
model_summary(m1_1s)

# ╔═╡ a8278cde-4b35-4807-bc06-f522b1f8c49d
md"
!!! note

There is a difference between `model_summary(::DataFrame, ...)` and `model_summary(::SampleModel)`. The latter I use to get a very quick indication of the validity of the mcmc chains (i.e., the `:ess` and `:r_hat` columns). It returns a Dataframe for better display in Pluto notebooks.

Calling `model_summary(::DataFrame, [vector of parameters])` returns primarily what's used in the Regression And Other Stories book (`:median` and `:mad_sd`). It returns a NamedArray to make it easy the get individual entries.

Typically I don't assign the result of the DataFrame version to a variable, but do so for the NamedArray version. See also the end of this notebook."

# ╔═╡ f544db54-86e2-4694-9cac-fc42e2c00e50
ms1_1s[:a, :median]

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
md" ###### A closer look at Stan's summary. Below the full version:"

# ╔═╡ 45a307ad-4f6a-4cb6-9182-bda870c42679
sdf

# ╔═╡ 8a04158e-a24d-477f-9cf8-30f062ec29bb
md" ###### Usually I use the abbreviated version:"

# ╔═╡ a3277285-5acb-4117-a567-67fdfd2cd4ba
success(rc1_1s) && model_summary(m1_1s)

# ╔═╡ 28640925-0d67-4f07-8ac3-eb4e4960380d
md" ###### This DataFrame is a different type then above created NamedArray `ms1_1s`."

# ╔═╡ fef949ca-ba53-407c-81db-14aa48e0706c
let
	df = model_summary(m1_1s)
	df[df.parameters .== :a, :ess]
end

# ╔═╡ bd15d29b-552e-4f62-bb55-c57dca312b5b
ms1_1s

# ╔═╡ 8703f610-71db-46fa-ad6b-d51ccd7b4ff2
sdf2 = model_summary(m1_1s, [:a, :b])

# ╔═╡ 2d1c65ed-f3e4-42fd-bf3f-f89efc543888
sdf3 = model_summary(m1_1s, [:lp__, :a, :b])

# ╔═╡ 29c2e746-a79d-4bef-84d2-2f2172807185
sdf3[:a, :r_hat]

# ╔═╡ 6ac30593-ce04-4295-af51-2c094596c61e
sdf4 = model_summary(m1_1s, ["lp__", "a", "b"])

# ╔═╡ d7c7f194-2a2b-4150-824c-dca609c5c692
sdf4["lp__", "std"]

# ╔═╡ 31b47c0f-fd45-4a40-a57c-43cfbfe6d721
md" ###### I use Strings if parameters are Vectors, otherwise I prefer Symbols."

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
# ╠═d830f41c-0fb6-4bff-9fe0-0bd51f444779
# ╠═35bee056-5cd8-48ee-b9c0-74a8b53229bd
# ╠═3c4672aa-d17e-4681-9863-9ee026fefee6
# ╠═a9970ef7-1e0e-4976-b8c9-1db4dd3a222b
# ╠═f48df50b-5450-4998-8dab-014c8b9d42a2
# ╠═be41c745-c87d-4f3a-ab4e-a8ae3b9ae091
# ╠═06ab4f30-68cc-4e35-9fa2-b8f8f25d3776
# ╠═df07541f-13ec-4192-acde-82c02ab6bcf6
# ╠═f11b4bdc-3ad4-467d-b75c-37da5e9dcb2c
# ╠═db6a5dab-a738-42d3-a97a-4ca60894b9ca
# ╠═9e471ad3-6c48-4f8a-b204-4ee864837898
# ╠═10395123-f9c9-441d-a497-cb7be9fa7b18
# ╠═1786b700-0d99-4541-87d4-b6308a2331bc
# ╟─261c1e49-13be-4950-b211-29c35e0da5e8
# ╠═274dc84c-b416-4f9e-8ff2-6ca0f08a40cf
# ╠═953eea61-f05f-4233-86aa-d5af3b47b41e
# ╠═77a2a293-e48f-46b5-a104-003772d8a922
# ╠═9d1a8b9a-2b0c-4b8d-af31-1717e7a5ecd7
# ╠═9842ce96-98f9-4a87-9208-d32d16418c15
# ╠═3a256571-459c-4346-a511-377a273cbb66
# ╠═8abccff4-2015-467e-92d6-067bd8db4e10
# ╠═a872c820-57b6-45d5-a7e9-2ab7349c81e7
# ╠═99259579-97fa-46f5-93b4-710b3180ded2
# ╠═f3863e01-deae-4e9d-b044-5515c5a19ab4
# ╠═5efb6ee3-8f20-42e3-a8af-cbfbb9acd075
# ╠═750a66c1-47bc-466c-a7f1-567640e2e2bb
# ╟─95cdfe9f-a06f-49f3-888f-34e47025c810
# ╟─10b925db-5f9c-4603-b49a-bd9b9a2e64d0
# ╠═14cbb5c2-db18-4bc1-a9b9-06ef2ab2ccec
# ╠═f1041467-bd19-4ef5-9359-98e38d272142
# ╠═42bfca0d-cf71-4064-bbd6-1466c1267d9a
# ╟─a8278cde-4b35-4807-bc06-f522b1f8c49d
# ╠═f544db54-86e2-4694-9cac-fc42e2c00e50
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
# ╟─28640925-0d67-4f07-8ac3-eb4e4960380d
# ╠═fef949ca-ba53-407c-81db-14aa48e0706c
# ╠═bd15d29b-552e-4f62-bb55-c57dca312b5b
# ╠═8703f610-71db-46fa-ad6b-d51ccd7b4ff2
# ╠═2d1c65ed-f3e4-42fd-bf3f-f89efc543888
# ╠═29c2e746-a79d-4bef-84d2-2f2172807185
# ╠═6ac30593-ce04-4295-af51-2c094596c61e
# ╠═d7c7f194-2a2b-4150-824c-dca609c5c692
# ╟─31b47c0f-fd45-4a40-a57c-43cfbfe6d721