#' SpliceGraHM2: two-class splice graph heatmap
#'
#' Splice graphs as disjoint heatmaps for the comparative visualization
#' of splice graphs across multiple samples in a single figure. Differs from
#' \code{splicegrahm} by allowing 2 graphs to be drawn in parallel along the
#' horizontal axis flipped along the vertical axis.
#'
#' @param obj1 a \code{concomp} object
#' @param obj2 a \code{concomp} object
#' @param sort_sep a logical whether to sort each exon, junction separately
#'        (default = FALSE)
#' @param sort_idx1 an integer value specifying the order of the obj1 samples in
#'        each exon, see details for more information on all possible
#'        input, if length is n, then this ordering is used (default = 1)
#' @param sort_idx2 an integer value specifying the order of the obj2 samples in
#'        each exon, see details for more information on all possible
#'        input, if length is n, then this ordering is used (default = 1)
#' @param log_base a numeric specifying the scale of the binning for the
#'        plotting of expression values at each exon, which 0 resulting in no long
#'        scaling being applied (default = 10)
#' @param log_shift a numeric specifying the shift to be used in the log transformation
#'        for handling 0 values (default = 1)
#' @param bin a logical whether to bin the values for easier viewing (default = TRUE)
#' @param genomic a logical whether genomic coordinates should be used to
#'        plot the heatmap (default = TRUE)
#' @param ex_use a numeric specifying the proportion of the plot exons should occupy if
#'        non-genomic coordinate plotting is desired (default = 2/3)
#' @param flip_neg a logical whether to flip plotting of genes on negative strand
#'        to run left to right (default = TRUE)
#' @param j_incl a logical whether to include heatmaps for junctions
#'        (default = FALSE)
#' @param use_blk a logical whether to use a black background (default = FALSE)
#' @param eps a numeric value specifying the number of base pairs around \code{obj} to look
#'        for overlapping gene models, if eps = NULL, then all overlapping gene models are
#'        included (default = 1e4) 
#' @param txlist a GRangesList of transcripts or genes which should be queried and
#'        added to the plot if falling within the region of the connected component
#'        (default = NULL)
#' @param txdb a transcript database which can be used to query the transcript IDs
#'        identified from txlist (default = NULL)
#' @param orgdb a database that can be queried using keys obtained from \code{txdb}
#'        to determine corresponding gene symbols (default = NULL)
#' @param title a character string title printed at the top of plot (default = "")
#' @param ... other parameters to be passed
#' 
#' @return
#' a ggplot2 plot showing the splice graph with heatmaps shown at each node
#' and each splice
#'
#' @details
#' sort_idx can take values of either:
#' \itemize{
#' \item{\code{1}}: sort on first exon
#' \item{\code{2}}: sort on PC 2
#' \item{\code{3}}: sort on mean exon coverage
#' \item{\code{4}}: sort on mean exon log-coverage
#' \item{\code{5}}: rev sort on mean exon coverage
#' \item{\code{6}}: rev sorton mean exon log-coverage
#' }
#' 
#' @name splicegrahm2
#' @export
#' @import ggplot2 GenomicRanges
#' @importFrom ggbio geom_alignment autoplot ggplot tracks
#' @importFrom grid arrow unit
#' @importFrom reshape2 melt
#' @author Patrick Kimes
NULL

.splicegrahm2.concomp <- function(obj1, obj2, sort_sep = FALSE,
                                  sort_idx1 = 1, sort_idx2 = 1,
                                  log_base = 10, log_shift = 1, bin = TRUE,
                                  genomic = TRUE, ex_use = 2/3, flip_neg = TRUE, 
                                  j_incl = FALSE, use_blk = FALSE, eps = 1e4,
                                  txlist = NULL, txdb = NULL, orgdb = NULL, title="", ...) {

    ##exonValues and juncValues must be specified
    if (is.null(exonValues(obj1)) || is.null(juncValues(obj1)) ||
        is.null(exonValues(obj2)) || is.null(juncValues(obj2)))
        stop(paste0("exonValues and juncValues cannot be NULL for splicegrahm2, \n",
                    "consider using splicegralp instead."))


    ## ########################################
    ## processing of concomps
    ## ########################################

    ##create single concomp with both ranges
    obj <- concomp(GRangesList("e"=c(exons(obj1), exons(obj2)),
                               "j"=c(juncs(obj1), juncs(obj2))))
    
    ##unpack and compute dimensions for concomp 1
    gr_e1 <- exons(obj1)
    gr_j1 <- juncs(obj1)
    vals_e1 <- exonValues(obj1)
    vals_j1 <- juncValues(obj1)
    n1 <- ncol(vals_e1)
    p_e1 <- nrow(vals_e1)
    p_j1 <- nrow(vals_j1)
    

    ##unpack and compute dimensions for concomp 2
    gr_e2 <- exons(obj2)
    gr_j2 <- juncs(obj2)
    vals_e2 <- exonValues(obj2)
    vals_j2 <- juncValues(obj2)
    n2 <- ncol(vals_e2)
    p_e2 <- nrow(vals_e2)
    p_j2 <- nrow(vals_j2)

    ##take maximum of both datasets to get dimensions of plot
    n_max <- max(n1, n2)
    
    ##determine overlapping annotations for concomps 1 and 2
    if (is.null(txlist)) {
        tx_plot <- NULL
    } else {
        tx_plot <- find_annotations(obj, txlist, txdb, orgdb, eps)
    }


    if (max(p_e1, p_e2) < 2) { genomic <- TRUE }

    ##change GRanges coordinates if non-genomic coordinates are desired
    if (genomic) {
        if (is.null(tx_plot)) {
            annot_track <- NULL
        } else { 
            annot_track <- ggplot() +
                geom_alignment(tx_plot, gap.geom="arrow", aes(group=tx)) +
                    theme_bw()
        }
    } else {
        adj_out <- adj_ranges(gr_e1, gr_j1, tx_plot, ex_use)
        gr_e1 <- adj_out$gr_e
        gr_j1 <- adj_out$gr_j

        adj_out <- adj_ranges(gr_e2, gr_j2, tx_plot, ex_use)
        gr_e2 <- adj_out$gr_e
        gr_j2 <- adj_out$gr_j
        annot_track <- adj_out$annot_track
    }
    

    ##determine whether plots should be flipped
    if (all(strand(gr_e1) == "*") && all(strand(gr_e2) == "*") &&
        !is.null(txlist) && !is.null(tx_plot)) {
        iflip <- flip_neg && all(strand(tx_plot) == '-')
    } else {
        iflip <- flip_neg && all(strand(gr_e1) == '-') && all(strand(gr_e2) == '-')
    }


    ##determine order of samples
    if (sort_sep) {
        vals_e1 <- t(apply(vals_e1, 1, sort))
        vals_j1 <- t(apply(vals_j1, 1, sort))
    } else {
        idx <- sampl_sort(sort_idx1, vals_e1, vals_j1, n1)
        vals_e1 <- vals_e1[, idx, drop=FALSE]
        vals_j1 <- vals_j1[, idx, drop=FALSE]

        idx <- sampl_sort(sort_idx2, vals_e2, vals_j2, n2)
        vals_e2 <- vals_e2[, idx, drop=FALSE]
        vals_j2 <- vals_j2[, idx, drop=FALSE]
    }


    ##create dataframe for plotting
    sg_df1 <- sg_create(gr_e1, gr_j1, vals_e1, vals_j1, j_incl,
                        log_base, log_shift, bin, n1, p_j1, FALSE)
    sg_df2 <- sg_create(gr_e2, gr_j2, vals_e2, vals_j2, j_incl,
                        log_base, log_shift, bin, n2, p_j2, TRUE)

    
    ##plot on genomic coordinates
    sg_obj1 <- sg_drawbase(sg_df1, use_blk, j_incl, genomic,
                           gr_e1, log_base, bin, n1, NULL, p_j1, iflip, FALSE)
    sg_obj2 <- sg_drawbase(sg_df2, use_blk, j_incl, genomic,
                           gr_e2, log_base, bin, n2, NULL, p_j2, iflip, TRUE)
    
    
    ##add arrow information if needed
    if (p_j1 > 0) {
        sg_obj1 <- sg_drawjuncs(sg_obj1, sg_df1, j_incl, use_blk, iflip,
                                gr_e1, gr_j1, vals_j1, n1, p_j1, NULL, FALSE)
    }
    if (p_j2 > 0) {
        sg_obj2 <- sg_drawjuncs(sg_obj2, sg_df2, j_incl, use_blk, iflip,
                                gr_e2, gr_j2, vals_j2, n2, p_j2, NULL, TRUE)
    }

    
    ##plot with horizontal axis oriented on negative strand
    if (iflip) {
        sg_obj1 <- sg_obj1 + scale_x_reverse()
        sg_obj2 <- sg_obj2 + scale_x_reverse()
    }

    
    ##add annotations if txdb was passed to function
    if (!is.null(txlist) && !is.null(tx_plot)) {
        if (iflip) { annot_track <- annot_track + scale_x_reverse() }
        sg_obj <- tracks(sg_obj1, annot_track, sg_obj2, heights=c(2, 1, 2), title=title)
    } else {
        sg_obj <- tracks(sg_obj1, sg_obj2, heights=c(2, 2), title=title)
    }

    sg_obj
}


#' @keywords internal
#' @title splicegrahm2 method
#' @name splicegrahm2-concomp
#' @aliases splicegrahm2,concomp,concomp-method
setMethod("splicegrahm2",
          signature(obj1 = "concomp", obj2 = "concomp"),
          function(obj1, obj2, ... ) .splicegrahm2.concomp(obj1, obj2, ...))



## necessary fixes:
## 1. flip bottom plot using negative values, not "scale_y_reverse"
## 2. -- consider fixing heights of both plots to be the same
## 3. -- consider scaling heights of both plots to be the same
## 4. -- also need to fix range of 'expression' colors for both plots
## 5. reduce to single legend - drop top legend by a little to be centered??
##
## -- match up splice junctions??
##
## for KLK12 example, use sigfuge labels - cleaner
##
##
