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

# ╔═╡ Cell order:
# ╟─0391fc17-09b7-47d7-b799-6dc6de13e82b
# ╟─eb7ea04a-da52-4e69-ac3e-87dc7f014652
# ╟─d7543b63-52d3-449b-8ce3-d979c23f8b95
# ╠═ed172871-fa4d-4111-ac0a-341898917948
# ╠═5084b8f0-65ac-4704-b1fc-2a9008132bd7
# ╟─4755dab0-d228-41d3-934a-56f2863a5652
# ╠═f71640c9-3918-475e-b32b-c85424bbcf5e
# ╠═6c2043f4-dcbd-4535-a5ae-61c109519879
