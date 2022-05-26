### A Pluto.jl notebook ###
# v0.19.5

using Markdown
using InteractiveUtils

# ╔═╡ 5084b8f0-65ac-4704-b1fc-2a9008132bd7
using Pkg, DrWatson

# ╔═╡ f71640c9-3918-475e-b32b-c85424bbcf5e
begin
	# Specific to this notebook
    using GLM

	# Specific to ROSStanPluto
    using StanSample
	
	# Graphics related
    using GLMakie
    using Makie

	# Common data files and functions
	using RegressionAndOtherStories
end

# ╔═╡ 0391fc17-09b7-47d7-b799-6dc6de13e82b
md"### HDI: hdi.csv, votes.csv"

# ╔═╡ eb7ea04a-da52-4e69-ac3e-87dc7f014652
md"##### See Chapter 2.1 in Regression and Other Stories."

# ╔═╡ d7543b63-52d3-449b-8ce3-d979c23f8b95
md" ###### Widen the notebook."

# ╔═╡ ed172871-fa4d-4111-ac0a-341898917948
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

# ╔═╡ 6c2043f4-dcbd-4535-a5ae-61c109519879
hdi = CSV.read(ros_datadir("HDI", "hdi.csv"), DataFrame)

# ╔═╡ d7b5bfec-3ca7-46fe-aed5-094ee266016b
let
	f = Figure()
	ax = Axis(f[1, 1]; title = "HDI",
		xlabel = "HDI rank of state", ylabel = "HDI index")
	limits!(ax, 0, 60, 0.7, 1)
	scatter!(hdi.rank, hdi.hdi)
	selection = 1:20:50
	scatter!(hdi.rank[selection], hdi.hdi[selection]; color=:darkred)
	for i in selection
		lines!([hdi.rank[i], hdi.rank[i] + 3], 
			[hdi.hdi[i], hdi.hdi[i] + 0.015]; color=:grey)
		annotations!(hdi.state[i], 
			position = (hdi.rank[i] + 3, hdi.hdi[i] + 0.015),
			textsize = 10)
	end
	selection = [4, 51]
	scatter!(hdi.rank[selection], hdi.hdi[selection]; color=:darkred)
	for i in selection
		lines!([hdi.rank[i], hdi.rank[i] + 3], 
			[hdi.hdi[i], hdi.hdi[i] - 0.015]; color=:grey)
		annotations!(hdi.state[i], 
			position = (hdi.rank[i] + 3, hdi.hdi[i] - 0.023),
			textsize = 10)
	end
	selection = 45:3:50
	scatter!(hdi.rank[selection], hdi.hdi[selection]; color=:darkred)
	for i in selection
		lines!([hdi.rank[i], hdi.rank[i] + 3], 
			[hdi.hdi[i], hdi.hdi[i] + 0.015]; color=:grey)
		annotations!(hdi.state[i], 
			position = (hdi.rank[i] + 3, hdi.hdi[i] + 0.015),
			textsize = 10)
	end
	f
end

# ╔═╡ 2dd08df7-a6dd-4a19-a673-a98c43e4d552
begin
	votes = CSV.read(ros_datadir("HDI", "votes.csv"), DataFrame; 
		delim=",", stringtype=String, pool=false)
	votes[votes.st_year .== 2000, [:st_state, :st_stateabb, :st_income]]
end

# ╔═╡ c4d6df3e-3cc9-4588-84e6-fe7265f01027
let
	tmp = votes[votes.st_year .== 2000, [:st_state, :st_stateabb, :st_income]]
	votes2 = DataFrame(state=tmp.st_state, abbr=tmp.st_stateabb,
		income=tmp.st_income)
	global hdivotes = innerjoin(hdi, votes2, on = :state)
end

# ╔═╡ 696eb9b0-f239-425b-8b71-802dfd9d8a42
let
	f = Figure()
	ax = Axis(f[1, 1]; title = "HDI ~ income",
		xlabel = "Average state income in 2000",
		ylabel = "Human Development Index")
	for i in 1:size(hdivotes, 1)
		if length(hdivotes.abbr[i]) > 0
			annotations!(hdivotes.abbr[i],
				position = (hdivotes.income[i], hdivotes.hdi[i]),
				textsize = 10)
		end
	end
	hdivotes.rank_hdi = sortperm(hdivotes.hdi)
	global hdivotes2 = sort(hdivotes, :income)
	ax = Axis(f[1, 2]; title = "Ranked HDI ~ ranked income",
		xlabel = "Rank of average state income in 2000",
		ylabel = "Rank of Human Development Index")
	for i in 1:size(hdivotes2, 1)
		if length(hdivotes2.abbr[i]) > 0
			annotations!(hdivotes2.abbr[i],
				position = (i, hdivotes2.rank_hdi[i]),
				textsize = 10)
		end
	end
	
	f
end

# ╔═╡ 1cebb5eb-0ae1-4ee4-bf0f-7695b653f721
hdivotes2

# ╔═╡ b0f4c1de-5b1d-4595-b891-31c3a0396c0c
stan2_1 = "
data {
	int N;
	vector[N] rank_hdi;
	vector[N] rank_income;
}
parameters {
	real a;
	real b;
	real sigma;
}
model {
	vector[N] mu;
	mu = a + b * rank_income;
	a ~ normal(0, 5);
	b ~ normal(0, 5);
	sigma ~ exponential(1);
	rank_hdi ~ normal(mu, sigma);
}";

# ╔═╡ 63641488-f75f-4380-a187-a127dc4a84fb
begin
	data = (N = size(hdivotes2, 1), rank_income = collect(1:size(hdivotes2, 1)), 
		rank_hdi = hdivotes2.rank_hdi)
	m2_1s = SampleModel("hdi", stan2_1)
	rc2_1s = stan_sample(m2_1s; data)
end;

# ╔═╡ a96a5658-33c6-4f73-8e5e-bb74b2e7fec1
if success(rc2_1s)
	post2_1s_df = read_samples(m2_1s, :dataframe)
	mod_sum = model_summary(post2_1s_df, [:a, :b, :sigma])
end

# ╔═╡ 9cf379d5-aac4-4350-8a3f-99ad0000969a
ā, b̄, σ = mod_sum[:, :median]

# ╔═╡ 1bcc7dde-85ef-48b7-b7ff-9d9560bdc16d
let
	f = Figure()
	ax = Axis(f[1, 1]; title = "HDI ~ income",
		xlabel = "Average state income in 2000",
		ylabel = "Human Development Index")
	for i in 1:size(hdivotes, 1)
		if length(hdivotes.abbr[i]) > 0
			annotations!(hdivotes.abbr[i],
				position = (hdivotes.income[i], hdivotes.hdi[i]),
				textsize = 10)
		end
	end
	ax = Axis(f[1, 2]; title = "Ranked HDI ~ ranked income",
		xlabel = "Rank of average state income in 2000",
		ylabel = "Rank of Human Development Index")
	for i in 1:size(hdivotes2, 1)
		if length(hdivotes2.abbr[i]) > 0
			annotations!(hdivotes2.abbr[i],
				position = (i, hdivotes2.rank_hdi[i]),
				textsize = 10)
		end
	end
	x = 0:52
	lines!(x, ā .+ b̄ .* x; color=:red)
	
	f
end

# ╔═╡ 50b61653-5f66-4e4c-8687-405ec2cd5c42
read_summary(m2_1s)[8:end, :]

# ╔═╡ Cell order:
# ╟─0391fc17-09b7-47d7-b799-6dc6de13e82b
# ╟─eb7ea04a-da52-4e69-ac3e-87dc7f014652
# ╟─d7543b63-52d3-449b-8ce3-d979c23f8b95
# ╠═ed172871-fa4d-4111-ac0a-341898917948
# ╠═5084b8f0-65ac-4704-b1fc-2a9008132bd7
# ╟─4755dab0-d228-41d3-934a-56f2863a5652
# ╠═f71640c9-3918-475e-b32b-c85424bbcf5e
# ╠═6c2043f4-dcbd-4535-a5ae-61c109519879
# ╠═d7b5bfec-3ca7-46fe-aed5-094ee266016b
# ╠═2dd08df7-a6dd-4a19-a673-a98c43e4d552
# ╠═c4d6df3e-3cc9-4588-84e6-fe7265f01027
# ╠═696eb9b0-f239-425b-8b71-802dfd9d8a42
# ╠═1cebb5eb-0ae1-4ee4-bf0f-7695b653f721
# ╠═b0f4c1de-5b1d-4595-b891-31c3a0396c0c
# ╠═63641488-f75f-4380-a187-a127dc4a84fb
# ╠═a96a5658-33c6-4f73-8e5e-bb74b2e7fec1
# ╠═9cf379d5-aac4-4350-8a3f-99ad0000969a
# ╠═1bcc7dde-85ef-48b7-b7ff-9d9560bdc16d
# ╠═50b61653-5f66-4e4c-8687-405ec2cd5c42
