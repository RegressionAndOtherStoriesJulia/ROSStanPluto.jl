# ROSStanPluto.jl

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->

## Purpose

This project will ultimately contain three sets of Pluto notebooks with Julia versions of selected examples explained in the books:

1. ["Data Analysis Using Regression and Multilevel/Hierarchical Models" (`ARM`)](http://www.stat.columbia.edu/~gelman/arm/)
2. ["Regression and Other Stories" (`ROS`)](https://www.cambridge.org/highereducation/books/regression-and-other-stories/DD20DD6C9057118581076E54E40C372C#overview).
3. ["Advanced Regression and Multilevel Models" (`ARMM`)](http://www.stat.columbia.edu/~gelman/armm/)

These notebooks are intended to be used in conjunction with above books. Each notebook contains a chapter. It is not the intention to cover each example in all books, just to get the reader going.

Both projects `ROSStanPluto` and `SR2StanPluto` are "work in progress projects", no guarantees all notebooks will always work without hickups. Please file an issue or a PR if you find a problem.

## Prerequisites

To complete below steps and run the notebooks you need:

1. A functioning [cmdstan](https://mc-stan.org/users/interfaces/cmdstan.html).
2. A functioning [Julia](https://julialang.org/downloads/).
3. A minimal Julia base environment containing `Pkg` and `Pluto`.

## Setup the Pluto based ROSStanPluto notebooks

To (locally) use this project, do the following:

Download ROSStanPluto.jl from [RegressionAndOtherStoriesJulia](https://github.com/RegressionAndOtherStoriesJulia/), e.g. to clone it to the `~/.julia/dev/ROSStanPluto` directory:

```Julia
$ cd ~/.julia/dev # This is just my preference!
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

Select the `open a file` entry box and select `chapters`. Select a chapter notebook and press `open`.
