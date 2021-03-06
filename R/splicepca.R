#' SplicePCA: splicing graph PCA plot
#'
#' Splice graphs with PCA loadings shown along the exons and junctions to illustrate
#' expression patterns across a connected component. The function can be used to
#' illustrate, e.g. differences across groups/clusters or principal component
#' loadings. Note that PCA is performed on the log-transfored data by default.
#'
#' @param obj a \code{concomp} object with exon and junction information
#' @param npc a numeric value specifying number of PCs to plot (default = 3)
#' @param pc_sep a logical whether PCA should be performed on exon and junction
#'        coverage separately (default = TRUE)
#' @param ej_w a numeric vector of length two specifying the relative sum of squares
#'        for exon and junctions (default = c(1, 1))
#' @param log_base a numeric specifying the scale of the expression values at each exon,
#'        which 0 resulting in no log scaling being applied (default = 10)
#' @param log_shift a numeric specifying the shift to be used in the log transformation
#'        for handling 0 values (default = 1)
#' @param genomic a logical whether genomic coordinates should be used to
#'        plot the heatmap (default = TRUE)
#' @param ex_use a numeric specifying the proportion of the plot exons should occupy if
#'        non-genomic coordinate plotting is desired (default = 2/3)
#' @param flip_neg a logical whether to flip plotting of genes on negative strand
#'        to run left to right (default = TRUE)
#' @param use_blk a logical whether to use a black background (default = FALSE)
#' @param txlist a GRangesList of transcripts or genes which should be queried and
#'        added to the plot if falling within the region of the connected component
#'        (default = NULL)
#' @param txdb a transcript database which can be used to query the transcript IDs
#'        identified from txlist (default = NULL)
#' @param orgdb a database that can be queried using keys obtained from \code{txdb}
#'        to determine corresponding gene symbols (default = NULL)
#' @param scores a logical whether to produce score plot rather than loadings plot
#'        (default = FALSE)
#' @param plot a logical whether to output a plot or the actually PCA analyses
#'        performed by \code{prcomp} (default = TRUE)
#' @param ... other parameters to be passed
#'
#' @details
#' \code{npc} cannot be larger than the rank of the centered data. When \code{pc_sep = TRUE},
#' this corresponds to \code{min(p_e, p_j, n-1)}, where \code{p_e}, \code{p_j}, \code{n}
#' correspond to the number of exons, junctions, and samples. When \code{pc_sep = TRUE},
#' this corresponds to \code{min(p_e+p_j, n-1)}.
#' 
#' @return
#' a ggplot2 plot showing the specified number of loadings
#'
#' @name splicepca
#' @import ggplot2
#' @importFrom GGally ggpairs wrap
#' @author Patrick Kimes
NULL
