### A Pluto.jl notebook ###
# v0.19.5

using Markdown
using InteractiveUtils

# ╔═╡ a20974be-c658-11ec-3a53-a185aa9085cb
using Pkg

# ╔═╡ 3626cf55-ee2b-4363-95ee-75f2444a1542
begin
    # Specific to ROSStanPluto
    using StanSample
	
	# Graphics related
    using GLMakie
	using Makie
    using AlgebraOfGraphics
		
	# Include basic packages
	using RegressionAndOtherStories
end

# ╔═╡ 364446a2-2ff2-4477-aa71-37d44a93dc44
md" ### This notebook is based on chapter 9 in [Statistical Rethinking](https://github.com/StatisticalRethinkingJulia)."

# ╔═╡ 4a6f12f9-3b83-42b5-9fed-0296a5a603c6
md" #### Care and feeding of Markov chains"

# ╔═╡ 2409c72b-cbcc-467f-9e81-23d83d2b703a
html"""
<style>
    main {
        margin: 0 auto;
        max-width: 2000px;
        padding-left: max(160px, 10%);
        padding-right: max(100px, 10%);
    }
</style>
"""

# ╔═╡ d84f1487-7eec-4a09-94d5-811449380cf5
stan9_2 = "
data {
    int n;
    vector[n] y;
}
parameters {
    real alpha;
    real<lower=0> sigma;
}
model {
    real mu;
    alpha ~ normal(0, 1000);
    sigma ~ exponential(0.0001);
    mu = alpha;
    y ~ normal(mu, sigma);
}";

# ╔═╡ eece4795-f36f-4f16-8132-e1fc672ebb8e
begin
    Random.seed!(123)
    data = (n=2, y=[-1, 1])
    m9_2s = SampleModel("m9.2s", stan9_2)
    rc = stan_sample(m9_2s; data)
    if success(rc)
        sdf = read_summary(m9_2s)
        post9_2s_df = read_samples(m9_2s, :dataframe)
    end
end

# ╔═╡ f67cbc42-1132-4626-93b0-82fe381a579e
model_summary(m9_2s, [:alpha, :sigma])

# ╔═╡ 1853b58c-5fc6-4b9c-9500-efb8ea5cff0f
plot_chains(post9_2s_df, [:alpha])

# ╔═╡ 90ae205a-a73b-4725-b4fd-b490c5cb01b9
trankplot(post9_2s_df, "alpha"; n_eff=sdf[sdf.parameters .== :alpha, :ess][1])

# ╔═╡ db7bede1-41d7-4e62-baf2-6449b3cbd45e
stan9_3 = "
data {
    int n;
    vector[n] y;
}
parameters {
    real alpha;
    real<lower=0> sigma;
}
model {
    real mu;
    alpha ~ normal(0, 1);
    sigma ~ exponential(1);
    mu = alpha;
    y ~ normal(mu, sigma);
}";

# ╔═╡ ba6d8640-b472-4ab3-8700-c80fdd59d82b
begin
    Random.seed!(123)
    m9_3s = SampleModel("m9.3s", stan9_3)
    rc9_3s = stan_sample(m9_3s; data)
    if success(rc9_3s)
        sdf9_3s = read_summary(m9_3s)
        post9_3s_df = read_samples(m9_3s, :dataframe)
    end
end

# ╔═╡ 3a51c780-9cdd-4f81-96fa-85fa81bb37f5
model_summary(m9_3s, sdf9_3s[:, :parameters])

# ╔═╡ a5959743-1dae-43c4-989b-cf1b2142d445
model_summary(m9_3s, [:alpha, :sigma])

# ╔═╡ 739831b7-27d4-4450-a3ed-8db96870e105
plot_chains(post9_3s_df, [:alpha, :sigma])

# ╔═╡ 2e06ce86-9431-4d94-94f5-eedca0d7b4b5
trankplot(post9_3s_df, "alpha"; n_eff=sdf9_3s[sdf9_3s.parameters .== :alpha, :ess][1])

# ╔═╡ 9eab4cb7-a30a-440c-a86a-7938df599285
stan9_4 = "
data {
    int n;
    vector[n] y;
}
parameters {
    real alpha;
    real beta;
    real<lower=0> sigma;
}
model {
    real mu;
    alpha ~ normal(0, 100);
    beta ~ normal(0, 1000);
    sigma ~ exponential(1);
    mu = alpha + beta;
    y ~ normal(mu, sigma);
}";

# ╔═╡ d75515b0-de24-4874-8edf-df2a86f24536
begin
	Random.seed!(1)
    data9_4s = (n = 100, y = rand(Normal(0, 1), 100))
    m9_4s = SampleModel("m9.4s", stan9_4)
    rc9_4s = stan_sample(m9_4s; data=data9_4s)
    if success(rc9_4s)
        sdf9_4s = read_summary(m9_4s)
        post9_4s_df = read_samples(m9_4s, :dataframe)
    end
end

# ╔═╡ dfd5f45c-a913-4f43-b8f9-1f03643a97ca
sdf9_4s

# ╔═╡ 0162ead7-e9d7-4ddf-a453-9a9f1285fc31
model_summary(m9_4s, [:alpha, :beta, :sigma])

# ╔═╡ cc947268-ef10-46f6-8bdf-6d2b42a70e10
plot_chains(post9_4s_df, [:alpha, :beta, :sigma])

# ╔═╡ 2dda23d9-d1b5-428e-b2e6-30692624d537
trankplot(post9_4s_df, "alpha"; n_eff=sdf9_4s[sdf9_4s.parameters .== :alpha, :ess][1])

# ╔═╡ 3206f276-877c-4f87-961b-3e7f22f351c9
trankplot(post9_4s_df, "beta"; n_eff=sdf9_4s[sdf9_4s.parameters .== :alpha, :ess][1])

# ╔═╡ 46ab44f5-26ae-4b2c-865e-0f0860e52a17
stan9_5 = "
data {
    int n;
    vector[n] y;
}
parameters {
    real alpha;
    real beta;
    real<lower=0> sigma;
}
model {
    real mu;
    alpha ~ normal(0, 10);
    beta ~ normal(0, 10);
    sigma ~ exponential(1);
    mu = alpha + beta;
    y ~ normal(mu, sigma);
}";

# ╔═╡ b9abe548-82fd-4e6e-aede-a91d19ce04d3
begin
    # Re-use data from m9_4s
    m9_5s = SampleModel("m9.5s", stan9_5)
    rc9_5s = stan_sample(m9_5s; data=data9_4s)
    if success(rc9_5s)
        sdf9_5s = read_summary(m9_5s)
        post9_5s_df = read_samples(m9_5s, :dataframe)
    end
end

# ╔═╡ 14b8e07c-a427-4ed5-93a2-22ea6b9a6d47
sdf9_5s

# ╔═╡ 213010f0-aaa7-423a-bcff-4dfe6bbc34cd
plot_chains(post9_5s_df, [:alpha, :beta, :sigma])

# ╔═╡ e4b85093-d7ca-4323-959a-0a4e12769a65
trankplot(post9_5s_df, "alpha"; n_eff=sdf9_5s[sdf9_5s.parameters .== :alpha, :ess][1])

# ╔═╡ 419bd2a1-141f-4106-9bf9-00f07e37359d
begin
	df = CSV.read(ros_datadir("SR2", "rugged.csv"), DataFrame)
	dropmissing!(df, :rgdppc_2000)
	dropmissing!(df, :rugged)
	df.log_gdp = log.(df[:, :rgdppc_2000])
	df.log_gdp_s = df.log_gdp / mean(df.log_gdp)
	df.rugged_s = df.rugged / maximum(df.rugged)
	df.cid = [df.cont_africa[i] == 1 ? 1 : 2 for i in 1:size(df, 1)]
	r̄ = mean(df.rugged_s)
	model_summary(df[:, [:rgdppc_2000, :log_gdp, :log_gdp_s, :rugged, :rugged_s, :cid]])
end

# ╔═╡ 7bae7603-2785-447c-922f-f1dd856208c0
data8_3s = (N = size(df, 1), K = length(unique(df.cid)), G = df.log_gdp_s, R = df.rugged_s, cid=df.cid);

# ╔═╡ 25f73c43-ed90-43b4-98fd-860c9bdb35b3
stan8_3 = "
data {
	int N;
	int K;
	vector[N] G;
	vector[N] R;
	int cid[N];
}

parameters {
	vector[K] a;
	vector[K] b;
	real<lower=0> sigma;
}

transformed parameters {
	vector[N] mu;
	for (i in 1:N)
		mu[i] = a[cid[i]] + b[cid[i]] * (R[i] - $(r̄));
}

model {
	a ~ normal(1, 0.1);
	b ~ normal(0, 0.3);
	sigma ~ exponential(1);
	G ~ normal(mu, sigma);
}
";

# ╔═╡ 86d9fc80-3b3a-46f0-849e-674071f6d880
begin
	m8_3s = SampleModel("m8.3s", stan8_3)
	rc8_3s = stan_sample(m8_3s; data=data8_3s)
	if success(rc8_3s)
		post8_3s_df = read_samples(m8_3s, :dataframe)
	end
end;

# ╔═╡ 7b58fd0d-b6a5-44e2-b628-9c898f40e24b
sdf8_3s = read_summary(m8_3s)[8:12, :]

# ╔═╡ 1952c376-b5ef-4164-8aaa-d016371de227
plot_chains(post8_3s_df, [Symbol("a.1"), Symbol("a.2")])

# ╔═╡ a67ca73d-015c-415f-b57a-0239bd289369
trankplot(post8_3s_df, "a.1"; n_eff=sdf8_3s[sdf8_3s.parameters .== Symbol("a[1]"), :ess][1])

# ╔═╡ 1646dd2f-8087-4aa3-ac0e-6701e913a3b7
plot_chains(post8_3s_df, [Symbol("b.1"), Symbol("b.2")])

# ╔═╡ c0e5bfda-7cd7-4bd3-808f-79f8a5c623be
plot_chains(post8_3s_df, [:sigma])

# ╔═╡ Cell order:
# ╟─364446a2-2ff2-4477-aa71-37d44a93dc44
# ╟─4a6f12f9-3b83-42b5-9fed-0296a5a603c6
# ╠═2409c72b-cbcc-467f-9e81-23d83d2b703a
# ╠═a20974be-c658-11ec-3a53-a185aa9085cb
# ╠═3626cf55-ee2b-4363-95ee-75f2444a1542
# ╠═d84f1487-7eec-4a09-94d5-811449380cf5
# ╠═eece4795-f36f-4f16-8132-e1fc672ebb8e
# ╠═f67cbc42-1132-4626-93b0-82fe381a579e
# ╠═1853b58c-5fc6-4b9c-9500-efb8ea5cff0f
# ╠═90ae205a-a73b-4725-b4fd-b490c5cb01b9
# ╠═db7bede1-41d7-4e62-baf2-6449b3cbd45e
# ╠═ba6d8640-b472-4ab3-8700-c80fdd59d82b
# ╠═3a51c780-9cdd-4f81-96fa-85fa81bb37f5
# ╠═a5959743-1dae-43c4-989b-cf1b2142d445
# ╠═739831b7-27d4-4450-a3ed-8db96870e105
# ╠═2e06ce86-9431-4d94-94f5-eedca0d7b4b5
# ╠═9eab4cb7-a30a-440c-a86a-7938df599285
# ╠═d75515b0-de24-4874-8edf-df2a86f24536
# ╠═dfd5f45c-a913-4f43-b8f9-1f03643a97ca
# ╠═0162ead7-e9d7-4ddf-a453-9a9f1285fc31
# ╠═cc947268-ef10-46f6-8bdf-6d2b42a70e10
# ╠═2dda23d9-d1b5-428e-b2e6-30692624d537
# ╠═3206f276-877c-4f87-961b-3e7f22f351c9
# ╠═46ab44f5-26ae-4b2c-865e-0f0860e52a17
# ╠═b9abe548-82fd-4e6e-aede-a91d19ce04d3
# ╠═14b8e07c-a427-4ed5-93a2-22ea6b9a6d47
# ╠═213010f0-aaa7-423a-bcff-4dfe6bbc34cd
# ╠═e4b85093-d7ca-4323-959a-0a4e12769a65
# ╠═419bd2a1-141f-4106-9bf9-00f07e37359d
# ╠═7bae7603-2785-447c-922f-f1dd856208c0
# ╠═25f73c43-ed90-43b4-98fd-860c9bdb35b3
# ╠═86d9fc80-3b3a-46f0-849e-674071f6d880
# ╠═7b58fd0d-b6a5-44e2-b628-9c898f40e24b
# ╠═1952c376-b5ef-4164-8aaa-d016371de227
# ╠═a67ca73d-015c-415f-b57a-0239bd289369
# ╠═1646dd2f-8087-4aa3-ac0e-6701e913a3b7
# ╠═c0e5bfda-7cd7-4bd3-808f-79f8a5c623be
