### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 1271ba57-93ff-4ef7-bfff-15c39a034b2c
using Pkg, DrWatson

# ╔═╡ 71cd8293-8c62-42b3-a33e-def5f7192160
begin
	# Specific to this notebook
    using GLM

	# Specific to ROSStanPluto
    using StanSample
	
	# Graphics related
    using GLMakie
    using Makie
	using AlgebraOfGraphics

	# Common data files and functions
	using RegressionAndOtherStories
end

# ╔═╡ a0fa3631-557c-4bb4-8862-cd21e24655e1
md"#### See Chapter 6 in Regression and Other Stories."

# ╔═╡ 5a68738d-8f8f-44b1-af3c-f3ceed14d82b
md" ##### Widen the notebook."

# ╔═╡ f96ef9cd-c3e2-4796-af8c-e5d94198fd6b
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

# ╔═╡ 5356fcee-dada-48dd-b422-bed4b5595470
md"##### A typical set of Julia packages to include in notebooks."

# ╔═╡ 8dba464a-3eb7-43e5-8324-85b938be6d51
md" ### 6.1 Regression models."

# ╔═╡ 326e0fc7-978b-42ae-b532-bdafb0a4948a
md"### 6.2 Fitting a simple regression to fake data."

# ╔═╡ 30832e8b-0642-447b-b281-207d7c4d73f4
let
	n = 20
	x = LinRange(1, n, 20)
	a = 0.2
	b = 0.3
	sigma = 0.5
	y = a .+ b .* x .+ rand(Normal(0, sigma), n)
	global fake = DataFrame(x=x, y=y)
end

# ╔═╡ 4c132847-fac0-4547-812a-58b4022d380d
stan6_1 = "
data {
	int N;
	vector[N] x;
	vector[N] y;
}
parameters {
	real a;
	real b;
	real<lower=0> sigma;
}
model {
	vector[N] mu;
	a ~ uniform(-2, 2);
	b ~ uniform(-2, 2);
	sigma ~ uniform(0, 10);
	mu = a + b * x;
	y ~ normal(mu, sigma);
}";

# ╔═╡ 1656a64f-324d-48c4-b8b2-d6e6a81de9c5
let
	data = (N=nrow(fake), x=fake.x, y=fake.y)
	global m6_1s = SampleModel("m6_1s", stan6_1)
	global rc6_1s = stan_sample(m6_1s; data)
	success(rc6_1s) && model_summary(m6_1s)
end

# ╔═╡ 1cd81462-2ed3-4b23-90c6-fdb4e3a6f143
if success(rc6_1s)
	post6_1s = read_samples(m6_1s, :dataframe)
	ms6_1s = model_summary(post6_1s, [:a, :b, :sigma])
end

# ╔═╡ 08be202b-f618-4a7f-a48a-5618b19495f5
let
	f = Figure()
	
	ax = Axis(f[1, 1]; title="Regression of fake data.", xlabel="fake.x", ylabel="fake.y")
	scatter!(fake.x, fake.y)
	x = 1:0.01:20
	y = ms6_1s[:a, :mean] .+  ms6_1s[:b, :mean] .* x
	lines!(x, y)
	â = round(ms6_1s[:a, :mean]; digits=2)
	b̂ = round(ms6_1s[:b, :mean]; digits=2)
	annotations!("y = $(â) + $(b̂) * x + ϵ"; position=(5, 0.8))
	
	ax = Axis(f[1, 2]; title="Regression of fake data.", subtitle="(using the link() function)",
		xlabel="fake.x", ylabel="fake.y")
	scatter!(fake.x, fake.y)
	xrange = LinRange(1, 20, 200)
	y = mean.(link(post6_1s, (r,x) -> r.a + x * r.b, xrange))
	lines!(xrange, y)
	annotations!("y = $(â) + $(b̂) * x + ϵ"; position=(5, 0.8))
	
	current_figure()
end

# ╔═╡ 9a2ec98b-6f45-4bc2-8ac0-5d6337cfb644
DataFrame(parameters = Symbol.(names(post6_1s)), simulated = [0.2, 0.3, 0.5], median = ms6_1s[:, :median], mad_sd = ms6_1s[:, :mad_sd])

# ╔═╡ bc877661-9aa0-425d-88e0-b82239c2552c
md" ### 6.3 Interpret coefficients as comparisons, not effects."

# ╔═╡ 6e6c65b3-f7ad-4a7f-91fd-f065e7bd7ffe
begin
	earnings = CSV.read(ros_datadir("Earnings", "earnings.csv"), DataFrame)
	earnings[:, [:earnk, :height, :male]]
end

# ╔═╡ 197b0a6a-7c1c-4aad-b9ba-5743c02169fc
describe(earnings[:, [:earnk, :height, :male]])

# ╔═╡ 21eb651a-8914-4217-bdef-f60badd30d9c
stan6_2 = "
data {
	int N;
	vector[N] male;
	vector[N] height;
	vector[N] earnk;
}
parameters {
	real a;
	real b;
	real c;
	real<lower=0> sigma;
}
model {
	vector[N] mu;
	sigma ~ exponential(1);
	mu = a + b * height + c * male;
	earnk ~ normal(mu, sigma);
}";

# ╔═╡ eec9a07a-09e0-400b-a0b1-df32d77e54fc
let
	data = (N=nrow(earnings), height=earnings.height, male=earnings.male, earnk=earnings.earnk)
	global m6_2s = SampleModel("m6_2s", stan6_2)
	global rc6_2s = stan_sample(m6_2s; data)
	success(rc6_2s) && model_summary(m6_2s)
end

# ╔═╡ f43ce0c2-a77f-4230-af27-85f46d3f10b7
if success(rc6_2s)
	post6_2s = read_samples(m6_2s, :dataframe)
	ms6_2s = model_summary(post6_2s, [:a, :b, :c, :sigma])
end

# ╔═╡ 9727012b-1b76-4cde-84ef-bdd7bfa4b025
let
	â = round(ms6_2s[:a, :mean]; digits=2)
	b̂ = round(ms6_2s[:b, :mean]; digits=2)
	ĉ = round(ms6_2s[:c, :mean]; digits=2)

	fig = Figure()
	
	ax = Axis(fig[1, 1]; title="Earnings for males", subtitle="earnk = $(round(ĉ + â; digits=2)) + $(b̂) * mheight + ϵ")
	m = sort(earnings[earnings.male .== 1, [:height, :earnk]])
	scatter!(m.height, m.earnk)
	mheight_range = LinRange(minimum(m.height), maximum(m.height), 200)
	earnk = mean.(link(post6_2s, (r,x) -> r.c + r.a + x * r.b, mheight_range))

	#earnk = ms6_2s[:c, "mean"] + ms6_2s[:a, "mean"] .+  ms6_2s[:b, "mean"] .* mheight
	lines!(mheight_range, earnk; color=:darkred)

	ax = Axis(fig[1, 2]; title="Earnings for females", subtitle="earnk = $(â) + $(b̂) * fheight + ϵ")
	f = sort(earnings[earnings.male .== 0, [:height, :earnk]])
	scatter!(f.height, f.earnk)
	fheight_range = LinRange(minimum(f.height), maximum(f.height), 200)
	earnk = mean.(link(post6_2s, (r,x) -> r.a + x * r.b, fheight_range))
	lines!(fheight_range, earnk; color=:darkred)

	fig
end	

# ╔═╡ ec3f566f-278c-4342-a365-db379b7d54aa
R2 = 1 - ms6_2s[:sigma, :mean]^2 / std(earnings.earnk)^2

# ╔═╡ c752672e-56de-4498-a85d-e3dffdc254d6
md" ### 6.4 Historical origins of regression."

# ╔═╡ f5563ff5-1468-4719-aca6-d84c75b9a596
stan6_3 = "
data {
	int N;
	vector[N] m_height;
	vector[N] d_height;
}
parameters {
	real a;
	real b;
	real<lower=0> sigma;
}
model {
	vector[N] mu;
	sigma ~ exponential(1);
	mu = a + b * m_height;
	d_height ~ normal(mu, sigma);
}";

# ╔═╡ db99f612-77b4-4639-892b-389a20c0ae83
heights = CSV.read(ros_datadir("PearsonLee", "heights.csv"), DataFrame)

# ╔═╡ 3288eba1-8ffa-45c2-951b-b4c9cf6fdf02
let
	data = (N=nrow(heights), m_height=heights.mother_height, d_height=heights.daughter_height)
	global m6_3s = SampleModel("m6_3s", stan6_3)
	global rc6_3s = stan_sample(m6_3s; data)
	success(rc6_3s) && model_summary(m6_3s)
end

# ╔═╡ f549f068-87e5-485d-bb9f-58d1cc2e15f4
if success(rc6_3s)
	post6_3s = read_samples(m6_3s, :dataframe)
	ms6_3s = model_summary(post6_3s, [:a, :b, :sigma])
end

# ╔═╡ 1e38322c-821f-45a5-aad9-d4c114ae37b7
let
	f = Figure()
	ax = Axis(f[1, 1]; title="Mothers' and daugthers' heights")
	xlims!(ax, 51, 74)
	scatter!(jitter.(heights.mother_height), jitter.(heights.daughter_height); markersize=3)
	x_range = LinRange(51, 74, 100)
	lines!(x_range, mean.(link(post6_3s, (r, x) -> r.a + r.b * x, x_range)); color=:darkred)
	scatter!([mean(heights.mother_height)], [mean(heights.daughter_height)]; markersize=20)
	f
end

# ╔═╡ 444766e8-86b9-496b-8b11-979b08fa842e
let
	f = Figure()
	ax = Axis(f[1, 1]; title="Mothers` and daughters' heights,\naverage of data, and fitted regression line",
		xlabel="Mother's height [in]", ylabel="Adult daugther's height [in]")
	scatter!(heights.mother_height, heights.daughter_height; markersize=5)
	xrange = LinRange(50, 72, 100)
	y = 30 .+ 0.54 .* xrange
	m̄ = mean(heights.mother_height)
	d̄ = mean(heights.daughter_height)
	scatter!([m̄], [d̄]; markersize=20, color=:gray)
	lines!(xrange, y)
	vlines!(ax, m̄; ymax=0.55, color=:grey)
	hlines!(ax, d̄; xmax=0.58, color=:grey)
	annotations!("y = 30 + 0.54 * mother's height", position=(49, 55), textsize=15)
	annotations!("or: y = 63.9 + 0.54 * (mother's height - 62.5)", position=(49, 54), textsize=15)
	f
end

# ╔═╡ ae86b798-1d42-4bf0-8bde-7d4c922a48fd
let
	f = Figure()
	ax = Axis(f[1, 1]; title="Mothers` and daughters' heights,\naverage of data, and fitted regression line",
		xlabel="Mother's height [in]", ylabel="Adult daugther's height [in]")
	scatter!(heights.mother_height, heights.daughter_height; markersize=5)
	xrange = LinRange(0, 72, 100)
	y = 30 .+ 0.54 .* xrange
	m̄ = mean(heights.mother_height)
	d̄ = mean(heights.daughter_height)
	scatter!([m̄], [d̄]; markersize=20, color=:gray)
	lines!(xrange, y)
	annotations!("y = 30 + 0.54 * mother's height", position=(20, 35), textsize=15)
	annotations!("or: y = 63.9 + 0.54 * (mother's height - 62.5)", position=(20, 33), textsize=15)
	f
end

# ╔═╡ 3ffe7a75-ebd5-4194-ab15-e7827ced581d
stan6_4 = "
data {
	int N;
	vector[N] m;
	vector[N] d;
}
parameters {
	real a;
	real b;
	real<lower=0> sigma;
}
model {
	vector[N] mu;
	a ~ normal(25, 3);
	b ~ normal(0, 0.5);
	sigma ~ exponential(1);
	mu = a + b * m;
	d ~ normal(mu, sigma);
}";

# ╔═╡ d3da4b65-dbd7-4bd9-9ab9-70b1a33b9728
let
	data = (N = nrow(heights), m = heights.mother_height, d = heights.daughter_height)
	global m6_4s = SampleModel("m6_4s", stan6_4)
	global rc6_4s = stan_sample(m6_4s; data)
	success(rc6_4s) && model_summary(m6_4s)
end

# ╔═╡ 4beb91af-f91a-490b-b701-2637c90d1d57
if success(rc6_4s)
	post6_4s = read_samples(m6_4s, :dataframe)
	ms6_4s = model_summary(post6_4s, [:a, :b, :sigma])
end

# ╔═╡ 1a132ed9-3ff5-42d2-bb63-642958abc5ce
plot_chains(post6_4s, [:a, :b, :sigma])

# ╔═╡ aa015e5a-88ca-4699-8f39-d0c54d8679e5
trankplot(post6_4s, "b")

# ╔═╡ 2bd08619-ccd4-4ade-8d40-955c5fcd3fc2
md" ###### Above trankplot and the low `ess` numbers a couple of cells earlier do not look healthy."

# ╔═╡ 4c04253e-cb54-4f46-817e-af76053eef16
md" ### 6.5 The paradox of regression to the mean."

# ╔═╡ aee6f37f-2a8a-451b-96e4-ec4eeb852b20
let
	n = 1000
	true_ability = rand(Normal(50, 10), n)
	noise_1 = rand(Normal(0, 10), n)
	noise_2 = rand(Normal(0, 10), n)
	midterm = true_ability + noise_1
	final = true_ability + noise_2
	global exams = DataFrame(midterm=midterm, final=final)
end

# ╔═╡ f8c21752-1dc5-4a41-90d6-796b83d80848
stan6_5 = "
data {
	int N;
	vector[N] midterm;
	vector[N] final;
}
parameters {
	real a;
	real b;
	real<lower=0> sigma;
}
model {
	vector[N] mu;
	sigma ~ exponential(1);
	mu = a + b * midterm;
	final ~ normal(mu, sigma);
}";

# ╔═╡ 6fd56eba-a6a6-4696-90d8-030502ab0f4a
let
	data = (N=nrow(exams), midterm=exams.midterm, final=exams.final)
	global m6_5s = SampleModel("m6_5s", stan6_5)
	global rc6_5s = stan_sample(m6_5s; data)
	success(rc6_5s) && model_summary(m6_5s)
end

# ╔═╡ 381d3341-e789-4ca4-98ab-7f980cbd6745
if success(rc6_5s)
	post6_5s = read_samples(m6_5s, :dataframe)
	ms6_5s = model_summary(post6_5s, [:a, :b, :sigma])
end

# ╔═╡ c0aeefbd-db6f-4359-80c1-9ff6ef5bb6f3
df_poll = CSV.read(ros_datadir("Death", "polls.csv"), DataFrame)

# ╔═╡ d3ae1909-f6a3-437a-9d19-5b4a6e6baab3
begin
	f = Figure()
	ax = Axis(f[1, 1]; title="Death penalty opinions", xlabel="Year", ylabel="Percentage support for the death penalty")
	scatter!(df_poll.year, df_poll.support .* 100)
	err_lims = [100(sqrt(df_poll.support[i]*(1-df_poll.support[i])/1000)) for i in 1:nrow(df_poll)]
	errorbars!(df_poll.year, df_poll.support .* 100, err_lims, color = :red)
	f
end

# ╔═╡ 2c6551c0-65c9-4c79-866c-8c67ba191b43
md" ###### Used in later notebooks."

# ╔═╡ 0f567e25-2ce1-407d-8525-185e584de86a
begin
	death_raw=CSV.read(ros_datadir("Death", "dataforandy.csv"), DataFrame; missingstring="NA")
	death = death_raw[completecases(death_raw), :]
end

# ╔═╡ 0a7444c8-29ef-43e2-be65-3a6979d8315b
let
	st_abbr = death[:, 1]
	ex_rate = death[:, 8] ./ 100
	err_rate = death[:, 7] ./ 100
	hom_rate = death[:, 5] ./ 100000
	ds_per_homicide = death[:, 3] ./ 1000
	ds = death[:, 2]
	hom = ds ./ ds_per_homicide
	ex = ex_rate .* ds
	err = err_rate .* ds
	pop = hom ./ hom_rate
	std_err_rate = sqrt.( (err .+ 1) .* (ds .+ 1 .- err) ./ ((ds .+ 2).^2 .* (ds .+ 3)) )
end;

# ╔═╡ Cell order:
# ╟─a0fa3631-557c-4bb4-8862-cd21e24655e1
# ╟─5a68738d-8f8f-44b1-af3c-f3ceed14d82b
# ╠═f96ef9cd-c3e2-4796-af8c-e5d94198fd6b
# ╠═1271ba57-93ff-4ef7-bfff-15c39a034b2c
# ╟─5356fcee-dada-48dd-b422-bed4b5595470
# ╠═71cd8293-8c62-42b3-a33e-def5f7192160
# ╟─8dba464a-3eb7-43e5-8324-85b938be6d51
# ╟─326e0fc7-978b-42ae-b532-bdafb0a4948a
# ╠═30832e8b-0642-447b-b281-207d7c4d73f4
# ╠═4c132847-fac0-4547-812a-58b4022d380d
# ╠═1656a64f-324d-48c4-b8b2-d6e6a81de9c5
# ╠═1cd81462-2ed3-4b23-90c6-fdb4e3a6f143
# ╠═08be202b-f618-4a7f-a48a-5618b19495f5
# ╠═9a2ec98b-6f45-4bc2-8ac0-5d6337cfb644
# ╟─bc877661-9aa0-425d-88e0-b82239c2552c
# ╠═6e6c65b3-f7ad-4a7f-91fd-f065e7bd7ffe
# ╠═197b0a6a-7c1c-4aad-b9ba-5743c02169fc
# ╠═21eb651a-8914-4217-bdef-f60badd30d9c
# ╠═eec9a07a-09e0-400b-a0b1-df32d77e54fc
# ╠═f43ce0c2-a77f-4230-af27-85f46d3f10b7
# ╠═9727012b-1b76-4cde-84ef-bdd7bfa4b025
# ╠═ec3f566f-278c-4342-a365-db379b7d54aa
# ╟─c752672e-56de-4498-a85d-e3dffdc254d6
# ╠═f5563ff5-1468-4719-aca6-d84c75b9a596
# ╠═db99f612-77b4-4639-892b-389a20c0ae83
# ╠═3288eba1-8ffa-45c2-951b-b4c9cf6fdf02
# ╠═f549f068-87e5-485d-bb9f-58d1cc2e15f4
# ╠═1e38322c-821f-45a5-aad9-d4c114ae37b7
# ╠═444766e8-86b9-496b-8b11-979b08fa842e
# ╠═ae86b798-1d42-4bf0-8bde-7d4c922a48fd
# ╠═3ffe7a75-ebd5-4194-ab15-e7827ced581d
# ╠═d3da4b65-dbd7-4bd9-9ab9-70b1a33b9728
# ╠═4beb91af-f91a-490b-b701-2637c90d1d57
# ╠═1a132ed9-3ff5-42d2-bb63-642958abc5ce
# ╠═aa015e5a-88ca-4699-8f39-d0c54d8679e5
# ╟─2bd08619-ccd4-4ade-8d40-955c5fcd3fc2
# ╟─4c04253e-cb54-4f46-817e-af76053eef16
# ╠═aee6f37f-2a8a-451b-96e4-ec4eeb852b20
# ╠═f8c21752-1dc5-4a41-90d6-796b83d80848
# ╠═6fd56eba-a6a6-4696-90d8-030502ab0f4a
# ╠═381d3341-e789-4ca4-98ab-7f980cbd6745
# ╠═c0aeefbd-db6f-4359-80c1-9ff6ef5bb6f3
# ╠═d3ae1909-f6a3-437a-9d19-5b4a6e6baab3
# ╟─2c6551c0-65c9-4c79-866c-8c67ba191b43
# ╠═0f567e25-2ce1-407d-8525-185e584de86a
# ╠═0a7444c8-29ef-43e2-be65-3a6979d8315b
