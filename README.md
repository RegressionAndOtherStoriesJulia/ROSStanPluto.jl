# ROSStanPluto.jl

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->

## Purpose

This project will contain (work is in very early stages of progress!!!) a set of Pluto notebooks that contain Julia versions of the examples in the R project `ROS-Examples` based on the book ["Regression and Other Stories" by A Gelman, J Hill and A Vehtari](https://www.cambridge.org/highereducation/books/regression-and-other-stories/DD20DD6C9057118581076E54E40C372C#overview).

These notebooks are intended to be used in conjunction with above book.

Each notebook contains a chapter. A static website can be found [here](https://regressionandotherstoriesjulia.github.io/ROSStanPluto.jl/).

## Table of Contents

### Chapters

1. [Introduction](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPluto.jl/blob/main/docs/🎈%20Introduction.pdf)
2. [Data and Measurement](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPluto.jl/blob/main/docs/🎈%20Data_and_Measurement.pdf)
3. [Probability](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPluto.jl/blob/main/docs/🎈%20Probability.pdf)
4. [Statistical inference](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPluto.jl/blob/main/docs/🎈%20Statistical_inference.pdf)
5. [Simulation](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPluto.jl/blob/main/docs/🎈%20Simulation.pdf)
6. [Background on regression](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPluto.jl/blob/main/docs/🎈%20Background_on_regression.pdf)
7. [Linear regression with single predictor](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPluto.jl/blob/main/docs/🎈%20Linear_regression_with_single_predictor.pdf)
8. [Fitting regression models](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPluto.jl/blob/main/docs/🎈%20Fitting_regression_models.pdf)
9. [Prediction and Bayesian inference](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPluto.jl/blob/main/docs/🎈%20Predictions_and_Bayesian_inference.pdf)
10. [Linear regression with multiple predictors](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPluto.jl/blob/main/docs/🎈%20Linear_regression_with_multiple_predictors.pdf)

### ROS playgrounds

1. [Stan playground](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPluto.jl/blob/main/docs/🎈%20Stan_playground.pdf)
2. [Chains playground](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPluto.jl/blob/main/docs/🎈%20Chains_playground.pdf)

## Personal note

This project will take quite a while to complete, I expect at least a year.

But it has a special meaning to me: When I started to work on Julia interfaces for Stan's cmdstan binary in 2011, I did that to work through the ["ARM" book](http://www.stat.columbia.edu/~gelman/arm/). The ["ROS" book](https://www.cambridge.org/highereducation/books/regression-and-other-stories/DD20DD6C9057118581076E54E40C372C#overview) in a sense is a successor to the ARM book.

## Prerequisites

To complete below steps and run the notebooks you need:

1. A functioning [cmdstan](https://mc-stan.org/users/interfaces/cmdstan.html).
2. A functioning [Julia](https://julialang.org/downloads/).
3. A minimal Julia base environment containing `Pkg` and `Pluto`.

## Setup the Pluto based ROSStanPluto notebooks

To (locally) use this project, do the following:

Download ROSStanPluto.jl from [RegressionAndOtherStoriesJulia](https://github.com/RegressionAndOtherStoriesJulia/), e.g. to clone it to the `~/.julia/dev/ROSStanPluto` directory:

```Julia
$ cd ~/.julia/dev
$ git clone https://github.com/RegressionAndOtherStoriesJulia/ROSStanPluto.jl ROSStanPluto
$ cd ROSStanPluto/notebooks # Move to the downloaded notebooks directory
$ julia # Start the Julia REPL
```

Still in the Julia REPL, start a Pluto notebook server.
```Julia
julia> using Pluto
julia> Pluto.run()
```

A Pluto page should open in a browser. See [this page](https://www.juliafordatascience.com/first-steps-5-pluto/) for a quick Pluto introduction.

## Usage

Select the `open a file` entry box and select `chapters`. Select a chapter notebook and press `open`.
