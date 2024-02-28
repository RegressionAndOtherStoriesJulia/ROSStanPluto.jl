### A Pluto.jl notebook ###
# v0.19.36

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
md"## 03-Linear regression: the basics."

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

# ╔═╡ 1556a18e-7136-4834-9665-a8567401880c
begin
	seed = 350
	Random.seed!(seed)
	n_obs = 50
	y = randn(n_obs)
end

# ╔═╡ 4a7b1f58-b2b0-459e-b27e-07c9cf2e9537
stan_data_2 = Dict("y" => y, "n_obs" => n_obs);

# ╔═╡ 4553f796-97fd-4879-a55d-4c9bdb6a5bcb
stan_data= (y=y, n_obs=n_obs);

# ╔═╡ 343169ef-869b-45cd-9f92-398e0b6f4660
model = "
data{
     // total observations
     int n_obs;
     // observations
    vector[n_obs] y;
}

parameters {
    real mu;
    real<lower=0> sigma;
}

model {
    mu ~ normal(0, 1);
    sigma ~ gamma(1, 1);
    y ~ normal(mu, sigma); 
}";

# ╔═╡ f19ec9a0-d5e8-4dbd-9a5e-59a067cdcad3
begin
	sm = SampleModel("temp", model)
	rc = stan_sample(sm; data=stan_data_2)
	df = read_samples(sm, :dataframe)
	global ms1 = model_summary(df, [:mu, :sigma])
	success(rc) && describe(sm, [:lp__, :mu, :sigma])
end

# ╔═╡ 9e7abdb8-e0e2-4a9b-84f7-cf2c72729318
let
	rc = stan_sample(sm; data=stan_data_2)
	df = read_samples(sm, :dataframe)
	global ms2 = model_summary(df, [:mu, :sigma])
	success(rc) && describe(sm, [:lp__, :mu, :sigma])
end

# ╔═╡ f90e2d4d-223f-4ca1-a207-3e2084fd45d9
ms1

# ╔═╡ f1b060af-ad15-4b51-9a83-88636a5accd1
ms2

# ╔═╡ Cell order:
# ╟─eb7ea04a-da52-4e69-ac3e-87dc7f014652
# ╟─cf39df58-3371-4535-88e4-f3f6c0404500
# ╠═0616ece8-ccf8-4281-bfed-9c1192edf88e
# ╟─4755dab0-d228-41d3-934a-56f2863a5652
# ╠═5084b8f0-65ac-4704-b1fc-2a9008132bd7
# ╠═d7753cf6-7452-421a-a3ec-76e07646f808
# ╠═550371ad-d411-4e66-9d63-7329322c6ea1
# ╠═1556a18e-7136-4834-9665-a8567401880c
# ╠═4a7b1f58-b2b0-459e-b27e-07c9cf2e9537
# ╠═4553f796-97fd-4879-a55d-4c9bdb6a5bcb
# ╠═343169ef-869b-45cd-9f92-398e0b6f4660
# ╠═f19ec9a0-d5e8-4dbd-9a5e-59a067cdcad3
# ╠═9e7abdb8-e0e2-4a9b-84f7-cf2c72729318
# ╠═f90e2d4d-223f-4ca1-a207-3e2084fd45d9
# ╠═f1b060af-ad15-4b51-9a83-88636a5accd1
