### A Pluto.jl notebook ###
# v0.19.22

using Markdown
using InteractiveUtils

# ╔═╡ 28f7bd2f-3208-4c61-ad19-63b11dd56d30
using Pkg

# ╔═╡ 2846bc48-7972-49bc-8233-80c7ea3326e6
begin
	using DataFrames
    using RegressionAndOtherStories: reset_selected_notebooks_in_notebooks_df!
end

# ╔═╡ 970efecf-9ae7-4771-bff0-089202b1ff1e
html"""
<style>
	main {
		margin: 0 auto;
		max-width: 2000px;
    	padding-left: max(160px, 0%);
    	padding-right: max(160px, 30%);
	}
</style>
"""

# ╔═╡ d98a3a0a-947e-11ed-13a2-61b5b69b4df5
notebook_files = [
    "~/.julia/dev/ROSStanPluto/notebooks/ARM/01-Introduction.jl",

    "~/.julia/dev/ROSStanPluto/notebooks/ROS/01-Introduction.jl",
    "~/.julia/dev/ROSStanPluto/notebooks/ROS/02-Data and Measurement.jl",
    "~/.julia/dev/ROSStanPluto/notebooks/ROS/03-Probability.jl",
    "~/.julia/dev/ROSStanPluto/notebooks/ROS/04-Statistical inference.jl",
    "~/.julia/dev/ROSStanPluto/notebooks/ROS/05-Simulation.jl",
    "~/.julia/dev/ROSStanPluto/notebooks/ROS/06-Background on regression.jl",
    "~/.julia/dev/ROSStanPluto/notebooks/ROS/07-Linear regression with single predictor.jl",
    "~/.julia/dev/ROSStanPluto/notebooks/ROS/08-Fitting regression models.jl",
    "~/.julia/dev/ROSStanPluto/notebooks/ROS/09-Predictions and Bayesian inference.jl",
    "~/.julia/dev/ROSStanPluto/notebooks/ROS/10-Linear regression with multiple predictors.jl",
    "~/.julia/dev/ROSStanPluto/notebooks/ROS/10-NES.jl",
    "~/.julia/dev/ROSStanPluto/notebooks/ROS/11-Assumptions, diagnostics and model evaluation.jl",
    "~/.julia/dev/ROSStanPluto/notebooks/ROS/12-Transformations and regression.jl",
    "~/.julia/dev/ROSStanPluto/notebooks/ROS/Appendix A.jl",
    "~/.julia/dev/ROSStanPluto/notebooks/Maintenance/Notebook-to-reset-ROSStanPluto-jl-notebooks.jl"

    "~/.julia/dev/ROSStanPluto/notebooks/ARMM/01-Introduction.jl",
];

# ╔═╡ 0f10a758-e442-4cd8-88bc-d82d8de97ede
begin
    files = AbstractString[]
    for i in 1:length(notebook_files)
        append!(files, [split(notebook_files[i], "/")[end]])
    end
    notebooks_df = DataFrame(
        name = files,
        reset = repeat([false], length(notebook_files)),
        done = repeat([false], length(notebook_files)),
        file = notebook_files,
    )
end

# ╔═╡ a4207232-61eb-4da7-8629-1bcc670ab524
notebooks_df.reset .= true;

# ╔═╡ 722d4847-2458-4b23-b6a0-d1c321710a2a
notebooks_df


# ╔═╡ 9d94bebb-fc41-482f-8759-cdf224ec71fb
reset_selected_notebooks_in_notebooks_df!(notebooks_df)

# ╔═╡ 88720478-7f64-4852-8683-6be50793666a
notebooks_df

# ╔═╡ Cell order:
# ╠═28f7bd2f-3208-4c61-ad19-63b11dd56d30
# ╠═2846bc48-7972-49bc-8233-80c7ea3326e6
# ╠═970efecf-9ae7-4771-bff0-089202b1ff1e
# ╠═d98a3a0a-947e-11ed-13a2-61b5b69b4df5
# ╠═0f10a758-e442-4cd8-88bc-d82d8de97ede
# ╠═a4207232-61eb-4da7-8629-1bcc670ab524
# ╠═722d4847-2458-4b23-b6a0-d1c321710a2a
# ╠═9d94bebb-fc41-482f-8759-cdf224ec71fb
# ╠═88720478-7f64-4852-8683-6be50793666a
