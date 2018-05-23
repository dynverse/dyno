Inferring trajectories using dyno <img src="docs/dyno.gif" align="right" />
================

-   [Installation](#installation)
-   [Trajectory inference workflow](#trajectory-inference-workflow)
    -   [Building the task](#building-the-task)
    -   [Selecting the most optimal TI methods](#selecting-the-most-optimal-ti-methods)
    -   [Running the methods](#running-the-methods)
    -   [Making the trajectory interpretable](#making-the-trajectory-interpretable)
    -   [Rooting](#rooting)
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

### Making the trajectory interpretable

In most cases, some knowledge is present of the different start, end or intermediary states present in the data, and this can be used to adapt the trajectory so that it is easier to interpret. We provide several functions

### Rooting

Most methods (although not all) have no direct way of inferring the directionality of the trajectory. In this case, the trajectory should be "rooted" using some external information, for example by using a set of marker genes.

``` r
model <- model %>% 
  add_root_using_expression(c("Vim"), task$expression)
```

-   Milestone labelling

...

``` r
model <- model %>% 
  label_milestones(list(
    MEF = c("Vim"),
    Myocyte = c("Myl1"),
    Neuron = c("Stmn3")
  ),
  task$expression)
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
plot_heatmap(
  model,
  expression_source = task$expression,
  grouping_assignment = task$grouping,
  features_oi = 50
)
```

<img src="docs/figures/README-heatmap-1.png" width="100%" />

#### Lineage/branch markers

We can also extract features specific for a branch

``` r
branch_feature_importance <- calculate_branch_feature_importance(model, expression_source=task$expression)

neuron_features <- branch_feature_importance %>% 
  filter(to == which(model$milestone_labelling =="Neuron")) %>% 
  top_n(50, importance) %>% 
  pull(feature_id)
```

``` r
plot_heatmap(
  model, 
  expression_source = task$expression, 
  features_oi = neuron_features
)
```

<img src="docs/figures/README-branch-1.png" width="100%" />

#### Genes important at bifurcation points

We can also extract features which change at the branching point

``` r
branching_milestone <- model$milestone_network %>% group_by(from) %>% filter(n() > 1) %>% pull(from) %>% first()

branch_feature_importance <- calculate_branching_point_feature_importance(model, expression_source=task$expression, milestones_oi = branching_milestone)

branching_point_features <- branch_feature_importance %>% top_n(20, importance) %>% pull(feature_id)

plot_heatmap(
  model,
  expression_source = task$expression,
  features_oi = branching_point_features
)
```

<img src="docs/figures/README-branching_point-1.png" width="100%" />

``` r
space <- dimred_mds(task$expression)
map(branching_point_features[1:12], function(feature_oi) {
  plot_dimred(model, dimred_method = space, expression_source = task$expression, feature_oi = feature_oi) +
    theme(legend.position = "none") +
    ggtitle(feature_oi)
}) %>% patchwork::wrap_plots()
```

<img src="docs/figures/README-branching_point_dimred-1.png" width="100%" />

References
----------

Saelens, Wouter, Robrecht Cannoodt, Helena Todorov, and Yvan Saeys. 2018. “A Comparison of Single-Cell Trajectory Inference Methods: Towards More Accurate and Robust Tools.” *bioRxiv*, March, 276907. doi:[10.1101/276907](https://doi.org/10.1101/276907).
