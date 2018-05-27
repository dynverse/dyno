Inferring trajectories using dyno <img src="docs/dyno.gif" align="right" />
================

-   [Installation](#installation)
-   [Trajectory inference workflow](#trajectory-inference-workflow)
    -   [Building the task](#building-the-task)
    -   [Selecting the most optimal TI methods](#selecting-the-most-optimal-ti-methods)
    -   [Running the methods](#running-the-methods)
    -   [Making the trajectory interpretable](#making-the-trajectory-interpretable)
    -   [Plotting the trajectory](#plotting-the-trajectory)
    -   [Plotting relevant features](#plotting-relevant-features)
-   [References](#references)

<!-- README.md is generated from README.Rmd. Please edit that file -->
The dyno package guides the user through the full path of trajectory inference (TI) on single-cell data, starting from the selection of the most optimal methods, to the running of these methods, right to the interpretation and visualisation of the trajectories.

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
```

The whole trajectory inference workflow is divided in several steps:

![](docs/figures/toolkit.png)

### Building the task

The first step is to prepare the data for trajectory inference. We use both the counts and normalised expression as some TI methods are specifically built for one or the other

``` r
data("fibroblast_reprogramming_treutlein")

task <- wrap_expression(
  counts = fibroblast_reprogramming_treutlein$counts,
  expression = fibroblast_reprogramming_treutlein$expression
)
```

### Selecting the most optimal TI methods

The choice of method depends on several factors, such as prior expectations of the topology present in the data, dataset size, and personal preferences. To select the best methods given a certain task we use the results from (Saelens et al. 2018) ([doi](https://doi.org/10.1101/276907)).

``` r
guidelines <- guidelines_shiny(task)
methods <- guidelines$methods %>% filter(selected) %>% pull(method_id) %>% first()
```

![](docs/dynguidelines.gif)

### Running the methods

To make it easy to plot and interpret trajectories from different methods, we use wrappers for each method, transforming its input and output into common models. Furthermore, to avoid getting stuck in "dependency hell", methods can be run within a docker, which will be automatically activated when running `start_dynmethods_docker` (for the installation of docker, see: <https://docs.docker.com/install/>). We make use of the [future](https://github.com/HenrikBengtsson/future) package, which also allows easy deployment of method execution on computing clusters and/or in parallel.

``` r
start_dynmethods_docker()

model %<-% infer_trajectory(task, methods[[1]])
```

    #> Warning in if (is.na(model)) {: the condition has length > 1 and only the
    #> first element will be used

### Making the trajectory interpretable

In most cases, some knowledge is present of the different start, end or intermediary states present in the data, and this can be used to adapt the trajectory so that it is easier to interpret.

#### Rooting

Most methods have no direct way of inferring the directionality of the trajectory. In this case, the trajectory should be "rooted" using some external information, for example by using a set of marker genes.

``` r
model <- model %>% 
  add_root_using_expression(c("Vim"), task$expression)
```

#### Milestone labelling

Milestones can be labelled using marker genes. These labels can then be used for subsequent analyses and for visualisation.

``` r
model <- label_milestones(
  model,
  list(
    MEF = c("Vim"),
    Myocyte = c("Myl1"),
    Neuron = c("Stmn3")
  ),
  task$expression)
```

### Plotting the trajectory

Several visualisation methods provide ways to biologically interpret trajectories.

Examples include combining a dimensionality reduction, a trajectory model and a cell clustering:

``` r
model <- model %>% add_dimred(dimred_mds, expression_source = task$expression)
plot_dimred(
  model, 
  expression_source = task$expression, 
  grouping_assignment = fibroblast_reprogramming_treutlein$grouping
)
```

<img src="docs/figures/README-dimred-1.png" width="100%" />

Similarly, the expression of a gene:

``` r
plot_dimred(
  model, 
  expression_source = task$expression,
  feature_oi = "Fn1"
)
```

<img src="docs/figures/README-dimred_expression-1.png" width="100%" />

Groups can also be visualised using a background color

``` r
plot_dimred(
  model, 
  expression_source = task$expression, 
  color_cells = "feature",
  feature_oi = "Vim",
  color_density = "grouping",
  grouping_assignment = fibroblast_reprogramming_treutlein$grouping,
  label_milestones = FALSE
)
```

<img src="docs/figures/README-dimred_groups-1.png" width="100%" />

### Plotting relevant features

We integrate several methods to extract relevant genes/features from a trajectory.

#### A global overview of the most predictive genes

At default, the overall most important genes are calculated when plotting a heatmap.

``` r
plot_heatmap(
  model,
  expression_source = task$expression,
  grouping_assignment = task$grouping,
  features_oi = 50
)
#> Warning in filter_impl(.data, quo): hybrid evaluation forced for
#> `row_number`. Please use dplyr::row_number() or library(dplyr) to remove
#> this warning.

#> Warning in filter_impl(.data, quo): hybrid evaluation forced for
#> `row_number`. Please use dplyr::row_number() or library(dplyr) to remove
#> this warning.
```

<img src="docs/figures/README-heatmap-1.png" width="100%" />

#### Lineage/branch markers

We can also extract features specific for a branch, eg. genes which change when a cell differentiates into a Neuron

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
#> Warning in filter_impl(.data, quo): hybrid evaluation forced for
#> `row_number`. Please use dplyr::row_number() or library(dplyr) to remove
#> this warning.

#> Warning in filter_impl(.data, quo): hybrid evaluation forced for
#> `row_number`. Please use dplyr::row_number() or library(dplyr) to remove
#> this warning.
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
#> Warning in filter_impl(.data, quo): hybrid evaluation forced for
#> `row_number`. Please use dplyr::row_number() or library(dplyr) to remove
#> this warning.

#> Warning in filter_impl(.data, quo): hybrid evaluation forced for
#> `row_number`. Please use dplyr::row_number() or library(dplyr) to remove
#> this warning.
```

<img src="docs/figures/README-branching_point-1.png" width="100%" />

``` r
space <- dimred_mds(task$expression)
map(branching_point_features[1:12], function(feature_oi) {
  plot_dimred(model, dimred = space, expression_source = task$expression, feature_oi = feature_oi, label_milestones = FALSE) +
    theme(legend.position = "none") +
    ggtitle(feature_oi)
}) %>% patchwork::wrap_plots()
```

<img src="docs/figures/README-branching_point_dimred-1.png" width="100%" />

#### Locally important genes

We can also extract the importance of a gene at each position within the trajectory.

References
----------

Saelens, Wouter\*, Robrecht\* Cannoodt, Helena Todorov, and Yvan Saeys. 2018. “A Comparison of Single-Cell Trajectory Inference Methods: Towards More Accurate and Robust Tools.” *bioRxiv*, March, 276907. doi:[10.1101/276907](https://doi.org/10.1101/276907).
