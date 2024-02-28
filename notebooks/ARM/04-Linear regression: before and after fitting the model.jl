### A Pluto.jl notebook ###
# v0.19.38

using Markdown
using InteractiveUtils

# ╔═╡ 5084b8f0-65ac-4704-b1fc-2a9008132bd7
using Pkg

# ╔═╡ d7753cf6-7452-421a-a3ec-76e07646f808
Pkg.activate(expanduser("~/.julia/dev/SR2StanPluto"))

# ╔═╡ 550371ad-d411-4e66-9d63-7329322c6ea1
begin
    # Specific to this notebook
    using GLM
    using Statistics

    # Specific to ROSStanPluto
    using StanSample
    
    # Graphics related
    using CairoMakie
    using AlgebraOfGraphics
    
    # Include basic packages
    using RegressionAndOtherStories
end

# ╔═╡ eb7ea04a-da52-4e69-ac3e-87dc7f014652
md"## 04-Linear regression: before and after fitting."

# ╔═╡ cf39df58-3371-4535-88e4-f3f6c0404500
md" ###### Widen the cells."

# ╔═╡ 0616ece8-ccf8-4281-bfed-9c1192edf88e
html"""
<style>
    main {
        margin: 0 auto;
        max-width: 2000px;
        padding-left: max(160px, 10%);
        padding-right: max(160px, 15%);
    }
</style>
"""

# ╔═╡ 4755dab0-d228-41d3-934a-56f2863a5652
md"###### A typical set of Julia packages to include in notebooks."

# ╔═╡ 0391fc17-09b7-47d7-b799-6dc6de13e82b
md"### 4.1 Linear transformations."

# ╔═╡ 7c5fee1e-f422-4f02-8b5f-94e8d92e6e6d
begin
	earnings = CSV.read(arm_datadir("earnings", "heights.csv"), DataFrame)
	filter!(e -> !(e.earn == "NA"), earnings)
	earnings.earn = Meta.parse.(earnings.earn)
	earnings.height = Meta.parse.(earnings.height)
	earnings
end

# ╔═╡ b4b29300-aded-436a-9a45-c3393549a36e
let
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="...")
	scatter!(earnings.height, Array(earnings.earn))
	f
end

# ╔═╡ 8825b7c3-e88d-463a-bd99-d6d7665dad3c
earnings_stan = "
data {
	int N;
	vector[N] h;
	vector[N] e;
}
parameters {
	real a;
	real b;
	real<lower=0> sigma;
}
model {
	vector[N] mu;
	a ~ normal(-60000, 1000);
	b ~ normal(1500, 100);
	sigma ~ exponential(1);
	mu = a + b * h;
	e ~ normal(mu, sigma);

}";

# ╔═╡ c47421ca-abe8-4801-9764-80c6c369bf00
let
	data = (N=nrow(earnings), h=earnings.height, e=earnings.earn)
	global earnings_sm = SampleModel("earnings", earnings_stan)
	rc = stan_sample(earnings_sm; data)
	success(rc) && describe(earnings_sm, [:lp__, :a, :b, :sigma])
end

# ╔═╡ 6e003acc-9e4e-4358-a782-8f0948cecba3
post_earnings = read_samples(earnings_sm, :dataframe)

# ╔═╡ 3c6f88c8-5073-4547-a17f-661caf625379
ms_earnings = model_summary(post_earnings, [:a, :b, :sigma])

# ╔═╡ d044755e-b385-4a3c-8c79-1c22db71d785
let
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="...")
	scatter!(earnings.height, Array(earnings.earn))
	x = 57:0.1:78
	for i in 1:100:4000
		lines!(x, post_earnings.a[i] .+ post_earnings.b[i] .* x; color=:gray)
	end
	lines!(x, ms_earnings[:a, :mean] .+ ms_earnings[:b, :mean] .* x)
	ax = Axis(f[1, 2]; title="...")
	scatter!(earnings.height, Array(earnings.earn))
	x = 0:0.1:78
	for i in 1:100:4000
		lines!(x, post_earnings.a[i] .+ post_earnings.b[i] .* x; color=:gray)
	end
	lines!(x, ms_earnings[:a, :mean] .+ ms_earnings[:b, :mean] .* x)
	f
end

# ╔═╡ 2fc9dddd-5543-42bd-9553-e5ed4ebdd91a
scale_df_cols!(earnings, [:height, :earn])

# ╔═╡ 629839d7-afc7-4f4f-9173-c0b632a361d5
let
	data = (N=nrow(earnings), h=earnings.height_s, e=earnings.earn_s)
	global earnings_s_sm = SampleModel("earnings", earnings_stan)
	rc = stan_sample(earnings_s_sm; data)
	success(rc) && describe(earnings_s_sm, [:lp__, :a, :b, :sigma])
end

# ╔═╡ 007eaa98-dfbc-4ef5-92dd-3d32a9a76f08
begin
	post_earnings_s = read_samples(earnings_s_sm, :dataframe)
	ms_earnings_s = model_summary(post_earnings_s, [:a, :b, :sigma])
end

# ╔═╡ aa647432-2b23-4b6f-9679-c276d0f1cca5
let
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="Regression on standardized values")
	scatter!(earnings.height_s, Array(earnings.earn_s))
	x = -3:0.1:3
	for i in 1:100:4000
		lines!(x, post_earnings_s.a[i] .+ post_earnings_s.b[i] .* x; color=:gray)
	end
	lines!(x, ms_earnings_s[:a, :mean] .+ ms_earnings_s[:b, :mean] .* x)

	x_scale_factor = [mu * std(earnings.height) + mean(earnings.height) for mu in -3:3:3]
	xtick_labels = string.(round.(x_scale_factor, digits=1))
	y_scale_factor = [mu * std(earnings.earn) + mean(earnings.earn) for mu in -2:2:6]
	ytick_labels = string.(round.(y_scale_factor, digits=1))

	ax = Axis(f[1, 2]; title="Regression on standardized values\n(rescaled tick labels)",
		xticks=(-3:3:3, xtick_labels), yticks=(-2:2:6, ytick_labels))
	scatter!(earnings.height_s, Array(earnings.earn_s))
	x = -3:0.1:3
	for i in 1:100:4000
		lines!(x, post_earnings_s.a[i] .+ post_earnings_s.b[i] .* x; color=:gray)
	end
	lines!(x, ms_earnings_s[:a, :mean] .+ ms_earnings_s[:b, :mean] .* x)
	f
end

# ╔═╡ Cell order:
# ╟─eb7ea04a-da52-4e69-ac3e-87dc7f014652
# ╟─cf39df58-3371-4535-88e4-f3f6c0404500
# ╠═0616ece8-ccf8-4281-bfed-9c1192edf88e
# ╟─4755dab0-d228-41d3-934a-56f2863a5652
# ╠═5084b8f0-65ac-4704-b1fc-2a9008132bd7
# ╠═d7753cf6-7452-421a-a3ec-76e07646f808
# ╠═550371ad-d411-4e66-9d63-7329322c6ea1
# ╟─0391fc17-09b7-47d7-b799-6dc6de13e82b
# ╠═7c5fee1e-f422-4f02-8b5f-94e8d92e6e6d
# ╠═b4b29300-aded-436a-9a45-c3393549a36e
# ╠═8825b7c3-e88d-463a-bd99-d6d7665dad3c
# ╠═c47421ca-abe8-4801-9764-80c6c369bf00
# ╠═6e003acc-9e4e-4358-a782-8f0948cecba3
# ╠═3c6f88c8-5073-4547-a17f-661caf625379
# ╠═d044755e-b385-4a3c-8c79-1c22db71d785
# ╠═2fc9dddd-5543-42bd-9553-e5ed4ebdd91a
# ╠═629839d7-afc7-4f4f-9173-c0b632a361d5
# ╠═007eaa98-dfbc-4ef5-92dd-3d32a9a76f08
# ╠═aa647432-2b23-4b6f-9679-c276d0f1cca5
