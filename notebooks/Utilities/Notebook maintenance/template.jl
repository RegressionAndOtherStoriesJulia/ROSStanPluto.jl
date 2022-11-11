md"#### See chapter 6 in Regression and Other Stories."


md" ##### Widen the notebook."

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

using Pkg

md"##### A typical set of Julia packages to include in notebooks."

begin
	# Specific to this notebook
    using GLM

	# Specific to ROSStanPluto
    using StanSample
	
	# Graphics related
    using GLMakie

	# Common data files and functions
	using RegressionAndOtherStories
end

md"### 6.1 "

hdi = CSV.read(ros_datadir("HDI", "hdi.csv"), DataFrame)
