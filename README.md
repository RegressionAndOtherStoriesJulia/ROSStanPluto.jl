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

The notebooks are by chapter with sections that follow [this](https://avehtari.github.io/ROS-Examples/examples.html#Examples_by_chapters) sequence.

## Table of contents

#### Chapters

##### Part 1: Fundamentals

1. [Introduction](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPlutoPdfs/blob/main/pdfs/🎈%2001%20-%20Introduction.jl%20—%20Pluto.pdf)
2. [Data and measurement](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPlutoPdfs/blob/main/pdfs/🎈%2002%20-%20Data%20and%20Measurement.jl%20—%20Pluto.pdf)
3. [Some basic methods in mathematics and probability](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPlutoPdfs/blob/main/pdfs/🎈%2003%20-%20Probability.jl%20—%20Pluto.pdf)
4. [Statistical inference](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPlutoPdfs/blob/main/pdfs/🎈%2004%20-%20Statistical%20inference.jl%20—%20Pluto.pdf)
5. [Simulation](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPlutoPdfs/blob/main/pdfs/🎈%2005%20-%20Simulation.jl%20—%20Pluto.pdf)

##### Part 2: Linear regression

6. [Background on regression]()
7. [Linear regression with a single predictor]()
8. [Fitting regression models]()
9. [Prediction and Bayesian inference]()
10. [Linear regression with multiple predictors]()

#### Notebook maintenance

1. [ros_functions](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPlutoPdfs/blob/main/pdfs/🎈%20ros_functions.jl%20—%20Pluto.pdf)
2. [ros_notebooks](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPlutoPdfs/blob/main/pdfs/🎈%20ros_notebooks.jl%20—%20Pluto.pdf)
3. [template](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPluto.jl/blob/main/notebooks/Notebook%20maintenance/template.jl)

#### ROS playgrounds

1. [Stan playground](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPlutoPdfs/blob/main/pdfs/🎈%200.1%20Stan%20playground.jl%20—%20Pluto.pdf)
2. [Chains playground](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPlutoPdfs/blob/main/pdfs/🎈%200.1%20Chains%20playground.jl%20—%20Pluto.pdf)
3. [DataFrame playground](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPlutoPdfs/blob/main/pdfs/🎈%200.1%20DataFrame%20playground.jl%20—%20Pluto.pdf)
4. [Nested dataframes](https://github.com/RegressionAndOtherStoriesJulia/ROSStanPlutoPdfs/blob/main/pdfs/🎈%200.1%20Nested%20playdataframe.jl%20—%20Pluto.pdf)

## Personal note

This project will take quite a while to complete, I expect at least a year.

But it has a special meaning to me: When I started to work on Julia interfaces for Stan's cmdstan binary in 2011, I did that to work through the ["ARM" book](http://www.stat.columbia.edu/~gelman/arm/). The ["ROS" book](https://www.cambridge.org/highereducation/books/regression-and-other-stories/DD20DD6C9057118581076E54E40C372C#overview) in a sense is a successor to the ARM book.

## Prerequisites

To complete below steps and run the notebooks you need:

1. A functioning [cmdstan](https://mc-stan.org/users/interfaces/cmdstan.html).
2. A functioning [Julia](https://julialang.org/downloads/).
3. A Julia base environment containing `Pkg` and `Pluto`.

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

Select a chapter in the `open a file` entry box, e.g. type `./` and select a chapter. Type '/' after selecting a chapter to see the notebooks in the chapter. Select the notebook and press `open`..
