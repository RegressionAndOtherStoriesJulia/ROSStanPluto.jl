### A Pluto.jl notebook ###
# v0.19.0

using Markdown
using InteractiveUtils

# ╔═╡ b8649ce5-9954-4856-b7b1-3595d78b2aca
begin
	# Graphics related
    using GLMakie
    using Makie

	# Common data files and functions
	using RegressionAndOtherStories
end

# ╔═╡ a1c176ba-b917-11ec-067d-6b68664e26b8
md" ### Pew - pew.csv, pid\_incprob.csv,  ideo\_incprob.csv,  party\_incprob.csv"

# ╔═╡ d14d492c-2066-4475-b213-dc133f7ec1f9
md"##### See Chapter 2.1 in Regression and Other Stories."

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
begin
	pew_pre_raw = CSV.read(ros_datadir("Pew", "pew.csv"), DataFrame; missingstring="NA", pool=false)
	pew_pre = pew_pre_raw[:, [:survey, :regicert,  :party, :state, :heat2, :heat4, :income2, :party4, :date,
		:weight, :voter_weight2, :pid, :ideology, :inc]]
end

# ╔═╡ 5098c6a1-5d00-4dff-a3d0-e7186d1036e2
pid_incprob = CSV.read(ros_datadir("Pew", "pid_incprop.csv"), DataFrame; missingstring="NA", pool=false)

# ╔═╡ 000c7a37-61fb-4288-aa81-42b3a33def6f
ideo_incprob = CSV.read(ros_datadir("Pew", "ideo_incprop.csv"), DataFrame; missingstring="NA", pool=false)

# ╔═╡ a27b1518-0ae1-40bb-a55b-96dc1aca3751
begin
	party_incprob_df = CSV.read(ros_datadir("Pew", "party_incprop.csv"), DataFrame; missingstring="NA", pool=false)
	party_incprob = reshape(Array(party_incprob_df)[:, 2:end], :, 3, 9)
	party_incprob[:, :, 9]
end

# ╔═╡ 94512c96-2ede-4dc6-9e11-e6c5a1799259
let
	x1 = 1.0:1.0:9.0
	f = Figure()
	ax = Axis(f[1, 1], title = "Self-declared political ideology by income",
		xlabel = "Income category", ylabel = "Vote fraction")
	limits!(ax, 1, 9, 0, 1)
	for i in 1:6
		sca1 = scatter!(x1, Array(ideo_incprob[i, 2:end]))
		lin = lines!(x1, Array(ideo_incprob[i, 2:end]))
		band!(x1, fill(0, length(x1)), Array(ideo_incprob[i, 2:end]);
			color = (:blue, 0.25), label = "Label")
	end
	annotations!("Very conservative", position = (3.2, 0.945), textsize=15)
	annotations!("Conservative", position = (3.9, 0.78), textsize=15)
	annotations!("Moderate", position = (4.0, 0.4), textsize=15)
	annotations!("Liberal", position = (4.2, 0.1), textsize=15)
	annotations!("Very liberal", position = (3.8, 0.0075), textsize=15)
	ax = Axis(f[1, 2], title = "Self-declared party indentification by income..",
		xlabel = "Income category", ylabel = "Vote fraction")
	limits!(ax, 1, 9, 0, 1)
	for i in 1:6
		sca1 = scatter!(x1, Array(pid_incprob[i, 2:end]))
		lin = lines!(x1, Array(pid_incprob[i, 2:end]))
		band!(x1, fill(0, length(x1)), Array(pid_incprob[i, 2:end]);
			color = (:blue, 0.25), label = "Label")
	end
	annotations!("Republican", position = (4.0, 0.87), textsize=15)
	annotations!("Lean Rep", position = (4.15, 0.675), textsize=15)
	annotations!("Independent", position = (3.95, 0.53), textsize=15)
	annotations!("Lean Dem", position = (4.2, 0.4), textsize=15)
	annotations!("Democrat", position = (4.1, 0.19), textsize=15)
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
# ╠═5098c6a1-5d00-4dff-a3d0-e7186d1036e2
# ╠═000c7a37-61fb-4288-aa81-42b3a33def6f
# ╠═a27b1518-0ae1-40bb-a55b-96dc1aca3751
# ╠═94512c96-2ede-4dc6-9e11-e6c5a1799259
