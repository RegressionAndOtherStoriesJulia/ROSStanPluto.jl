### A Pluto.jl notebook ###
# v0.19.0

using Markdown
using InteractiveUtils

# ╔═╡ b8649ce5-9954-4856-b7b1-3595d78b2aca
begin
	# Specific to this notebook
    using GLM

	# Graphics related
    using GLMakie
    using Makie

	# Common data files and functions
	using RegressionAndOtherStories
end

# ╔═╡ a1c176ba-b917-11ec-067d-6b68664e26b8
md" ### HealthExpenditure - healthexpenditure.jl"

# ╔═╡ d14d492c-2066-4475-b213-dc133f7ec1f9
md"##### See Chapter 2.3 in Regression and Other Stories."

# ╔═╡ ad5ba104-dbde-4718-9606-85969fa6f4d2
md" ###### Widen the notebook."

# ╔═╡ 9f07b037-d926-4250-af88-a367fe2a9e39
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

# ╔═╡ 9eea4fe3-7bb2-4981-a33d-14fa54b632d3
md"###### A typical set of Julia packages to include in notebooks."

# ╔═╡ 0b023c5e-a5e0-47d1-8602-9711f661bb5c
health = CSV.read(ros_datadir("HealthExpenditure", "healthdata.csv"), DataFrame; missingstring="NA", pool=false)

# ╔═╡ 82444a23-2bda-4d40-9856-b7603832d3a1
exp = lm(@formula(lifespan ~ spending), health)

# ╔═╡ 10eea085-202f-418c-a907-2c8fccb6ca08
â, b̂ = coef(exp)

# ╔═╡ 94512c96-2ede-4dc6-9e11-e6c5a1799259
let
	x = 0:8000
	f = Figure()
	ax = Axis(f[1, 1], title = "Health expenditure of 30 `western` countries",
		xlabel = "Spending [PPP US\$]", ylabel = "Life expectancy [years]")
	limits!(ax, 0, 8100, 73, 83)
	sca = scatter!(health.spending, health.lifespan; color=:darkred)
	lin = lines!(x, â .+ b̂ * x; color=:lightblue)
	for i in 1:nrow(health)
		if health.country[i] == "UK"
			annotations!(health.country[i], position = (health.spending[i]+40, health.lifespan[i]-0.25), textsize=8)
		elseif health.country[i] == "Finland"
			annotations!(health.country[i], position = (health.spending[i]-100, health.lifespan[i]+0.1), textsize=8)
		elseif health.country[i] == "Greece"
			annotations!(health.country[i], position = (health.spending[i]-300, health.lifespan[i]-0.25), textsize=8)
		elseif health.country[i] == "Sweden"
			annotations!(health.country[i], position = (health.spending[i]-180, health.lifespan[i]-0.25), textsize=8)
		elseif health.country[i] == "Ireland"
			annotations!(health.country[i], position = (health.spending[i]-150, health.lifespan[i]-0.25), textsize=8)
		elseif health.country[i] == "Netherlands"
			annotations!(health.country[i], position = (health.spending[i]+50, health.lifespan[i]+0.01), textsize=8)
		elseif health.country[i] == "Germany"
			annotations!(health.country[i], position = (health.spending[i]-350, health.lifespan[i]+0.08), textsize=8)
		elseif health.country[i] == "Austria"
			annotations!(health.country[i], position = (health.spending[i]+30, health.lifespan[i]-0.2), textsize=8)
		else
			annotations!(health.country[i], position = (health.spending[i]+60, health.lifespan[i]-0.1), textsize=8)
		end
	end
	current_figure()
end

# ╔═╡ Cell order:
# ╟─a1c176ba-b917-11ec-067d-6b68664e26b8
# ╟─d14d492c-2066-4475-b213-dc133f7ec1f9
# ╟─ad5ba104-dbde-4718-9606-85969fa6f4d2
# ╠═9f07b037-d926-4250-af88-a367fe2a9e39
# ╟─9eea4fe3-7bb2-4981-a33d-14fa54b632d3
# ╠═b8649ce5-9954-4856-b7b1-3595d78b2aca
# ╠═0b023c5e-a5e0-47d1-8602-9711f661bb5c
# ╠═82444a23-2bda-4d40-9856-b7603832d3a1
# ╠═10eea085-202f-418c-a907-2c8fccb6ca08
# ╠═94512c96-2ede-4dc6-9e11-e6c5a1799259
