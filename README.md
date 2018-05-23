Inferring trajectories using dyno <img src="docs/dyno.gif" align="right" />
================

-   [Installation](#installation)
-   [Trajectory inference workflow](#trajectory-inference-workflow)
    -   [Building the task](#building-the-task)
    -   [Selecting the most optimal TI methods](#selecting-the-most-optimal-ti-methods)
    -   [Running the methods](#running-the-methods)
    -   [Rooting the trajectory](#rooting-the-trajectory)
    -   [Plotting the trajectory](#plotting-the-trajectory)
    -   [Plotting relevant features](#plotting-relevant-features)
-   [References](#references)

<!-- README.md is generated from README.Rmd. Please edit that file -->
The dyno package guides the user through the full path of trajectory inference on single-cell data, starting from the selection of the most optimal methods, to the running of these methods, right to the interpretation and visualisation of the trajectories.

Installation
------------

You can install dyno from github using:

``` r
# install.packages("devtools")
devtools::install_github("dynverse/dyno")
```

Trajectory inference workflow
-----------------------------

``` r
library(dyno)
library(tidyverse)

data("fibroblast_reprogramming_treutlein")

task <- wrap_expression(
  counts = fibroblast_reprogramming_treutlein$counts,
  expression = fibroblast_reprogramming_treutlein$expression
)
```

Inferring and interpreting trajectories consists of five main steps

### Building the task

The first step is to prepare the data for trajectory inference.

### Selecting the most optimal TI methods

The choice of method depends on several factors, such as prior expectations of the topology present in the data, dataset size, and personal preferences. To select the best methods given a certain task we use the results from (Saelens et al. 2018) ([doi](https://doi.org/10.1101/276907)).

``` r
guidelines <- guidelines_shiny(task)
methods <- guidelines$methods %>% filter(selected) %>% pull(method_id) %>% first()
```

![](docs/dynguidelines.gif)

### Running the methods

To make it easy to plot and interpret trajectories from different methods, we use wrappers for each method, transforming its input and output into common models. Furthermore, to avoid getting stuck in "dependency hell", methods can be run within a docker, which will be automatically activated when running `start_dynmethods_docker` (for the installation of docker, see: <https://docs.docker.com/install/>).

``` r
start_dynmethods_docker()

model %<-% infer_trajectory(task, methods[[1]])
```

### Rooting the trajectory

Most methods (although not all) have no direct way of inferring the directionality of the trajectory. In this case, the trajectory should be "rooted" using some external information, for example by using a set of marker genes.

``` r
model <- model %>% 
  add_root_using_expression(c("Msn", "Tpm4", "Anxa1", "Timp1", "Vim"), task$expression)
```

### Plotting the trajectory

Several visualisation methods provide ways to biologically interpret trajectories. As an example, the plotting of a cell clustering:

``` r
plot_dimred(model, expression_source = task$expression, grouping_assignment = task$grouping)
```

<img src="docs/figures/README-dimred-1.png" width="100%" />

### Plotting relevant features

We integrate several methods to extract relevant genes from a trajectory.

#### A global overview of the most predictive genes

``` r
plot_heatmap(model, expression_source = task$expression, grouping_assignment = task$grouping, features_oi = 20)
```

<img src="docs/figures/README-heatmap-1.png" width="100%" />

#### Lineage/branch markers

Available soon

#### Genes important at bifurcation points

Available soon

References
----------

Saelens, Wouter, Robrecht Cannoodt, Helena Todorov, and Yvan Saeys. 2018. “A Comparison of Single-Cell Trajectory Inference Methods: Towards More Accurate and Robust Tools.” *bioRxiv*, March, 276907. doi:[10.1101/276907](https://doi.org/10.1101/276907).
