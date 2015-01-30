#' SpliceGraHM2: splice graph heatmap with 2 a priori classes
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
#' @param txlist a GRangesList of transcripts or genes which should be queried and
#'        added to the plot if falling within the region of the connected component
#'        (default = NULL)
#' @param txdb a transcript database which can be used to query the transcript IDs
#'        identified from txlist (default = NULL)
#' @param orgdb a database that can be queried using keys obtained from \code{txdb}
#'        to determine corresponding gene symbols (default = NULL)
#' @param ... other parameters to be passed
#' 
#' @return
#' a ggplot2 plot showing the splice graph with heatmaps shown at each node
#' and each splice
#'
#' @details
#' sort_idx can take values of either:
#' \itemize{
#' \item{\code{1}}: sort based on first exon
#' \item{\code{2}}: sort based on PC 2
#' }
#' 
#' @name splicegrahm2
#' @export
#' @import ggplot2 GenomicRanges
#' @importFrom ggbio geom_alignment autoplot ggplot
#' @importFrom grid arrow unit
#' @importFrom reshape2 melt
#' @author Patrick Kimes
NULL

.splicegrahm2.concomp <- function(obj1, obj2,
                                  sort_sep = FALSE, sort_idx1 = 1, sort_idx2 = 1,
                                  log_base = 10, log_shift = 1, bin = TRUE,
                                  genomic = TRUE, ex_use = 2/3, flip_neg = TRUE, 
                                  j_incl = FALSE, use_blk = FALSE, txlist = NULL,
                                  txdb = NULL, orgdb = NULL, ...) {
    
    ##exonValues and juncValues must be specified
    if (is.null(exonValues(obj1)) || is.null(juncValues(obj1)) ||
        is.null(exonValues(obj2)) || is.null(juncValues(obj2)))
        stop(paste0("exonValues and juncValues cannot be NULL for splicegrahm, \n",
                    "consider using splicegralp instead."))

    ##can't include gene models if not plotting on genomic scale
    if (!is.null(txlist) && !genomic) {
        cat("since txlist provided, plotting on genomic scale. \n")
        genomic <- TRUE
    }

    obj <- obj1
    
    ##unpack concomp
    gr_e <- exons(obj)
    gr_j <- juncs(obj)
    vals_e <- exonValues(obj)
    vals_j <- juncValues(obj)
    
    ##dataset dimension
    n <- ncol(vals_e)
    p_e <- nrow(vals_e)
    p_j <- nrow(vals_j)
    dna_len <- width(range(gr_e))
    rna_len <- sum(width(gr_e))
    
    n <- ncol(vals_e)
    p_e <- nrow(vals_e)
    p_j <- nrow(vals_j)
    dna_len <- width(range(gr_e))
    rna_len <- sum(width(gr_e))

    ##change GRanges coordinates if non-genomic coordinates are desired
    if (!genomic) {
        if (rna_len/dna_len <= ex_use) {
            gr_ej <- adj_ranges(gr_e, gr_j, dna_len, rna_len, ex_use, p_e)
            gr_e <- gr_ej$gr_e
            gr_j <- gr_ej$gr_j
        } else {
            genomic <- TRUE
        }
    }

    ##determine overlapping gene models
    if (genomic && !is.null(txlist)) {
        a_out <- find_annotations(obj1, txlist, txdb, orgdb)
        tx_match <- a_out$tx_match
        annot_track <- a_out$annot_track
    }
    
    ##determine whether plots should be flipped
    if (all(strand(gr_e) == "*") && !is.null(txlist) && !is.null(tx_match)) {
        iflip <- flip_neg && all(strand(tx_match) == '-')
    } else {
        iflip <- flip_neg && all(strand(gr_e) == '-')
    }
    
    
    ##determine order of samples
    if (sort_sep) {
        vals_e <- t(apply(vals_e, 1, sort))
        vals_j <- t(apply(vals_j, 1, sort))
    } else {
        idx <- sampl_sort(sort_idx1, vals_e, vals_j)
        vals_e <- vals_e[, idx]
        vals_j <- vals_j[, idx]
    }

    ##create dataframe for plotting
    sg_df <- sg_create(gr_e, gr_j, vals_e, vals_j, j_incl,
                      log_base, log_shift, bin, n, p_j)

    
    ##plot on genomic coordinates
    sg_obj <- sg_drawbase(sg_df, use_blk, j_incl, genomic,
                          gr_e, log_base, bin, n)
    
    
    ##add arrow information if needed
    sg_obj <- sg_drawjuncs(sg_obj, sg_df, j_incl, use_blk, iflip,
                           gr_e, gr_j, vals_j, n, p_j)
    
    
    ##plot with horizontal axis oriented on negative strand
    if (iflip) { sg_obj <- sg_obj + scale_x_reverse() }


    ##add annotations if txdb was passed to function
    if (!is.null(txlist) && genomic && !is.null(tx_match)) {
        if (iflip) { annot_track <- annot_track + scale_x_reverse() }
        sg_obj <- tracks(sg_obj, annot_track, heights=c(2, 1))
    }

    sg_obj
}

#' @keywords internal
#' @title splicegrahm2 method
#' @name splicegrahm2-concomp
#' @aliases splicegrahm2,concomp-method
setMethod("splicegrahm2",
          signature(obj1 = "concomp", obj2 = "concomp"),
          function(obj1, obj2 = "concomp", ... ) .splicegrahm2.concomp(obj1, obj2, ...))


