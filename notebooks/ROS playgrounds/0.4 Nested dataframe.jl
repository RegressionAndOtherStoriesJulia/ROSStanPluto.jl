### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 1d6c9e3b-b20d-462d-b633-a808305afdec
using Pkg, DrWatson

# ╔═╡ 5d720373-d1c8-4947-b29e-9bedb9a63a2c
begin
	# Specific to ROSStanPluto
    using StanSample
	using Distributions
	
	# Graphics related
    using GLMakie
    using Makie
    using AlgebraOfGraphics

	# Common data files and functions
	using RegressionAndOtherStories
end

# ╔═╡ 5eaece93-07bf-4550-b393-2a4891cd9b99
md" ##### Widen the notebook."

# ╔═╡ 1d5532f7-cc38-446b-a6da-458a9564afcc
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

# ╔═╡ f5ccc087-1ad0-42cd-b09a-02eb46cc441a
md"##### A typical set of Julia packages to include in notebooks."

# ╔═╡ 7c435cd5-769c-477b-bccf-398053bcbd74
function zscore_transform(data)
    μ = mean(data)
    σ = std(data)
    z(d) = (d .- μ) ./ σ
    return z
end

# ╔═╡ d8ca810d-1bb6-4087-a760-ded35b3ea5b5
begin
	N = 500
	U_sim = rand(Normal(), N )
	Q_sim = sample(1:4 , N ; replace=true )
	sim_df = DataFrame(
		E_sim = [rand(Normal( U_sim[i] + Q_sim[i]), 1)[1] for i in 1:length(U_sim)],
		W_sim = [rand(Normal( U_sim[i] + 0 * Q_sim[i]), 1)[1] for i in 1:length(U_sim)]
	)
end

# ╔═╡ fd1965c8-a05d-4076-a587-f6506e589422
data = (
    W=standardize(ZScoreTransform, sim_df.W_sim),
    E=standardize(ZScoreTransform, sim_df.E_sim),
    Q=standardize(ZScoreTransform, Float64.(Q_sim))
);

# ╔═╡ 4a762650-2f97-483c-a2d8-ca9a5e15038e
stan14_6 = "
data{
    vector[500] W;
    vector[500] E;
    vector[500] Q;
}
parameters{
    real aE;
    real aW;
    real bQE;
    real bEW;
    corr_matrix[2] Rho;
    vector<lower=0>[2] Sigma;
}
model{
    vector[500] muW;
    vector[500] muE;
    Sigma ~ exponential( 1 );
    Rho ~ lkj_corr( 2 );
    bEW ~ normal( 0 , 0.5 );
    bQE ~ normal( 0 , 0.5 );
    aW ~ normal( 0 , 0.2 );
    aE ~ normal( 0 , 0.2 );
    for ( i in 1:500 ) {
        muE[i] = aE + bQE * Q[i];
    }
    for ( i in 1:500 ) {
        muW[i] = aW + bEW * E[i];
    }
    {
        vector[2] YY[500];
        vector[2] MU[500];
        for ( j in 1:500 ) MU[j] = [ muW[j] , muE[j] ]';
        for ( j in 1:500 ) YY[j] = [ W[j] , E[j] ]';
        YY ~ multi_normal( MU , quad_form_diag(Rho , Sigma) );
    }
}";

# ╔═╡ d24ea359-a900-453f-bd15-19a073dacc1f
# ╠═╡ show_logs = false
let
	global m14_6s = SampleModel("m14_6s", stan14_6)
	global rc14_6s = stan_sample(m14_6s; data)
	df = success(rc14_6s) && model_summary(m14_6s)
	df.parameters = String.(df.parameters)
	df
end

# ╔═╡ 54753000-d19f-4fa5-9d49-18e2ab052ffd
md"
!!! note

In above cell the logs have been hidden!"

# ╔═╡ c0c926ad-715d-4126-8bdd-ce6ea5b158a6
md"
```julia
> precis( m14.6 , depth=3 )
          mean   sd  5.5% 94.5% n_eff Rhat4
aE        0.00 0.04 -0.06  0.06  1669     1
aW        0.00 0.04 -0.07  0.07  1473     1
bQE       0.59 0.03  0.53  0.64  1396     1
bEW      -0.05 0.07 -0.17  0.07   954     1
Rho[1,1]  1.00 0.00  1.00  1.00   NaN   NaN
Rho[1,2]  0.54 0.05  0.46  0.62  1010     1
Rho[2,1]  0.54 0.05  0.46  0.62  1010     1
Rho[2,2]  1.00 0.00  1.00  1.00   NaN   NaN
Sigma[1]  1.02 0.04  0.96  1.10  1011     1
Sigma[2]  0.81 0.03  0.77  0.85  1656     1
```
"

# ╔═╡ 6e60a2b8-5a3e-4e90-8c48-4e8b9a3d76ed
if success(rc14_6s)
    post14_6s = read_samples(m14_6s, :dataframe)
end

# ╔═╡ 4b53e73e-97a2-4a6c-a534-11361943c102
StanSample.find_nested_columns(post14_6s)

# ╔═╡ 175bcbdc-1749-41c2-8b99-475ca9c9b8c6
StanSample.select_nested_column(post14_6s, :Sigma)

# ╔═╡ 5a45f3b3-794b-4d67-b3b7-75a78d4f4b1f
StanSample.select_nested_column(post14_6s, :Rho)

# ╔═╡ 4f785e76-01a2-42c8-9863-3f3e1b6160c0
nd = read_samples(m14_6s, :nesteddataframe)

# ╔═╡ 9b015a56-a3e0-4a44-98ff-130aac93fdcd
m = matrix(nd, :Rho)

# ╔═╡ fb283b4f-42cf-4db7-bbf9-2fe67fcd21e0
nd[3, :Rho]

# ╔═╡ 54c3cd51-35d9-4973-8dc2-ab3e938966e5
matrix(nd, :Sigma)

# ╔═╡ Cell order:
# ╟─5eaece93-07bf-4550-b393-2a4891cd9b99
# ╠═1d5532f7-cc38-446b-a6da-458a9564afcc
# ╠═1d6c9e3b-b20d-462d-b633-a808305afdec
# ╟─f5ccc087-1ad0-42cd-b09a-02eb46cc441a
# ╠═5d720373-d1c8-4947-b29e-9bedb9a63a2c
# ╠═7c435cd5-769c-477b-bccf-398053bcbd74
# ╠═d8ca810d-1bb6-4087-a760-ded35b3ea5b5
# ╠═fd1965c8-a05d-4076-a587-f6506e589422
# ╠═4a762650-2f97-483c-a2d8-ca9a5e15038e
# ╠═d24ea359-a900-453f-bd15-19a073dacc1f
# ╟─54753000-d19f-4fa5-9d49-18e2ab052ffd
# ╟─c0c926ad-715d-4126-8bdd-ce6ea5b158a6
# ╠═6e60a2b8-5a3e-4e90-8c48-4e8b9a3d76ed
# ╠═4b53e73e-97a2-4a6c-a534-11361943c102
# ╠═175bcbdc-1749-41c2-8b99-475ca9c9b8c6
# ╠═5a45f3b3-794b-4d67-b3b7-75a78d4f4b1f
# ╠═4f785e76-01a2-42c8-9863-3f3e1b6160c0
# ╠═9b015a56-a3e0-4a44-98ff-130aac93fdcd
# ╠═fb283b4f-42cf-4db7-bbf9-2fe67fcd21e0
# ╠═54c3cd51-35d9-4973-8dc2-ab3e938966e5
