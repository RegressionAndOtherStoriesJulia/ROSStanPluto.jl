### A Pluto.jl notebook ###
# v0.19.0

using Markdown
using InteractiveUtils

# ╔═╡ 5084b8f0-65ac-4704-b1fc-2a9008132bd7
using Pkg, DrWatson

# ╔═╡ f71640c9-3918-475e-b32b-c85424bbcf5e
begin
	# Graphics related
    using GLMakie
    using Makie

	# Common data files and functions
	using RegressionAndOtherStories
end

# ╔═╡ 0391fc17-09b7-47d7-b799-6dc6de13e82b
md"### Bayesian information aggregation calculations."

# ╔═╡ 17034ac2-d8da-40a4-a899-5c4e10877945
md"##### See Chapter 9 in Regression and Other Stories."

# ╔═╡ 32d7fdff-2e2e-485d-bab5-09d2358a446e
md"##### Prior based on a previously-fitted model using economic and political condition."

# ╔═╡ 62ee06b2-6ef9-4fb7-b194-f701250465ee
begin
	theta_hat_prior = 0.524
	se_prior = 0.041
end;

# ╔═╡ e8419e76-e251-429d-8e1f-9784dffcb78a
md"##### Survey of 400 people, of whom 190 say they will vote for the Democratic candidate."

# ╔═╡ 0acb8885-4178-4679-bf06-8fb6ff60e161
begin
	n = 400
	y = 190
end;

# ╔═╡ d8b54dc0-d091-467b-8025-2981c6342dad
md"##### Data estimate."

# ╔═╡ 6c6d2896-daef-4984-b028-04100643b9f9
theta_hat_data = y/n

# ╔═╡ 0d97580b-924d-4638-b228-0a7c4b67549f
se_data = √((y/n)*(1-y/n)/n)

# ╔═╡ a6797e8d-5d39-4bf6-981b-ed070cc28586
md"##### Bayes estimate."

# ╔═╡ aa58187a-739e-4b03-8ebe-19faef7473a1
theta_hat_bayes = (theta_hat_prior/se_prior^2 +
	theta_hat_data/se_data^2) /(1/se_prior^2 + 1/se_data^2)

# ╔═╡ 0a9b23e6-4022-433b-955c-7c84bd020bf1
se_bayes = sqrt(1/(1/se_prior^2 + 1/se_data^2))

# ╔═╡ 46a4817a-1587-4b26-98d0-b1da5e9f4673
begin
	x = 0.3:0.001:0.7
	f = Figure()
	ax = Axis(f[1, 1], xlim=(0.3, 0.7), title="Prior, likelihood & posterior")
	lines!(f[1, 1], x, pdf.(Normal(theta_hat_prior, se_prior), x), color=:gray)
	lines!(x, pdf.(Normal(theta_hat_data, se_data), x),color=:darkred)
	lines!(x, pdf.(Normal(theta_hat_bayes, se_bayes), x), color=:darkblue)
	current_figure()
end

# ╔═╡ 883e8535-0b1e-491c-91ff-4cc21025de50
let
	f = Figure()
	ax = Axis(f[1, 1], title="Prior, likelihood & posterior (using `density()`)",
		xlim=(0.3, 0.7))
	density!(rand(Normal(theta_hat_prior, se_prior), Int(1e6)), lab="prior")
	density!(rand(Normal(theta_hat_data, se_data), Int(1e6)), lab="likelihood")
	density!(rand(Normal(theta_hat_bayes, se_bayes), Int(1e6)), lab="bayes")
	current_figure()
end

# ╔═╡ Cell order:
# ╟─0391fc17-09b7-47d7-b799-6dc6de13e82b
# ╟─17034ac2-d8da-40a4-a899-5c4e10877945
# ╠═5084b8f0-65ac-4704-b1fc-2a9008132bd7
# ╠═f71640c9-3918-475e-b32b-c85424bbcf5e
# ╟─32d7fdff-2e2e-485d-bab5-09d2358a446e
# ╠═62ee06b2-6ef9-4fb7-b194-f701250465ee
# ╟─e8419e76-e251-429d-8e1f-9784dffcb78a
# ╠═0acb8885-4178-4679-bf06-8fb6ff60e161
# ╟─d8b54dc0-d091-467b-8025-2981c6342dad
# ╠═6c6d2896-daef-4984-b028-04100643b9f9
# ╠═0d97580b-924d-4638-b228-0a7c4b67549f
# ╟─a6797e8d-5d39-4bf6-981b-ed070cc28586
# ╠═aa58187a-739e-4b03-8ebe-19faef7473a1
# ╠═0a9b23e6-4022-433b-955c-7c84bd020bf1
# ╠═46a4817a-1587-4b26-98d0-b1da5e9f4673
# ╠═883e8535-0b1e-491c-91ff-4cc21025de50
