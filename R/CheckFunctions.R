#' Check Input Parameters
#'
#' Check input parameters for invalid entries.
#' @param Convert String Direction for conversion.
#' @param Output String Type of output.
#' @param System String Genetic system (HLA or KIR) of the data being converted
#' @param HZY.Red Logical Reduction of homozygote genotypes to single allele.
#' @param DRB345.Check Logical Check DR haplotypes for consistency and flag unusual haplotypes.
#' @param Cores.Lim Integer How many cores can be used.
#' @note This function is for internal use only.
Check.Params <- function (Convert,Output,System,HZY.Red,DRB345.Check,Cores.Lim) {

  if( is.na(match(Convert,c("GL2Tab","Tab2GL"))) ) { Err.Log.GLS("P.Error","Convert") ; stop("Conversion Stopped.",call.=FALSE) }
  if( is.na(match(Output,c("R","txt","csv","pypop"))) ) { Err.Log.GLS("P.Error","Output") ; stop("Conversion Stopped.",call.=FALSE) }
  if( is.na(match(System,c("HLA","KIR"))) ) { Err.Log.GLS("P.Error","System") ; stop("Conversion Stopped.",call.=FALSE) }
  if( !is.logical(HZY.Red) ) { Err.Log.GLS("P.Error","HZY.Red") ; stop("Conversion Stopped.",call.=FALSE) }
  if( !is.logical(DRB345.Check) ) { Err.Log.GLS("P.Error","DRB345.Check") ; stop("Conversion Stopped.",call.=FALSE) }
  if( !is.numeric(Cores.Lim) || !is.integer(Cores.Lim) ) { Err.Log.GLS("P.Error","Cores.Lim") ; stop("Conversion Stopped.",call.=FALSE) }

}

#' Check Cores Parameters
#'
#' Check cores limitation for OS compatibility
#' @param Cores.Lim Integer How many cores can be used.
Check.Cores <- function(Cores.Lim) {
  if ( Cores.Lim!=1L ) {
    Cores.Max <- as.integer( floor( parallel::detectCores() * 0.9) )
    if(Sys.info()['sysname']=="Windows" && as.numeric(Cores.Lim)>1) {
      Err.Log.GLS("Windows.Cores") ; stop("Conversion stopped.",call. = F)
    } else if( Cores.Lim > Cores.Max ) { Cores <- Cores.Max
    } else { Cores <- Cores.Lim }
  } else { Cores <- Cores.Lim }
  return(Cores)
}

#' Check Data Structure
#'
#' Check data structure for successfuly conversion.
#' @param Data String Type of output.
#' @param Convert String Direction for conversion.
#' @note This function is for internal use only.
Check.Data <- function (Data,Convert) {

  if(Convert=="Tab2GL") {

    # Check for column formatting consistency
    if( ncol(Data) < 3 ) { Err.Log.GLS("Table.Col") ; stop("Conversion stopped.",call.=F) }

    # Check for GL string field delimiters Presence
    if ( sum(grepl("\\+",Data[,ncol(Data)])) > 0 || sum(grepl("\\^",Data[,ncol(Data)])) > 0 || sum(grepl("\\|",Data[,ncol(Data)])) > 0 ) {
      Err.Log.GLS("Tab.Format") ; stop("Conversion stopped.",call.=F)
    }

    # Check for repeating column names
    colnames(Data) <- sapply(colnames(Data),FUN=gsub,pattern="\\.1|\\.2|\\_1|\\_2",replacement="")
    DataCol <- as.numeric(sapply(names(which(table(colnames(Data))==2)), FUN=function(x) grep(x,colnames(Data))))
    if( length(DataCol) ==0 ) { Err.Log.GLS("Table.Pairs") ; stop("Conversion stopped.",call.=F) }

  }

  if(Convert=="GL2Tab") {

    LastCol <- ncol(Data)

    # Check for GL string field delimiters Absence
    if ( sum(grepl("\\+",Data[,LastCol])) == 0 && sum(grepl("\\^",Data[,LastCol])) == 0 && sum(grepl("\\|",Data[,LastCol])) == 0 ) {
      Err.Log.GLS("GL.Format") ; stop("Conversion stopped.",call.=F)
    }

    # Check for ambiguous data at genotype "|"
    if( sum(grepl("\\|",Data[,LastCol]))>0 ) {
      Check.Rows <- paste(grep("\\|",Data[,LastCol]),collapse=",")
      Err.Log.GLS("GTYPE.Amb",Check.Rows) ; stop("Conversion stopped.",call.=F) }
  }

}

#' GL String Locus Check
#'
#' Check GL string for locus appear in multiple gene fields.
#' @param x GL String to check against
#' @param Loci Loci to check
#' @note This function is for internal use only.
CheckString.Locus <- function(x,Loci) {

  test <- sapply(Loci,FUN = function(z) regexpr(z,x) )
  test[test==-1] <- NA
  test.CS <- colSums(test, na.rm=TRUE)
  if( max(test.CS)>1 ) {

    Loci.Err <- paste(Loci[which(test.CS>1)],collapse=",")
    GLS <- paste(x,collapse="^")
    Err.Log.GLS("Locus.MultiField",GLS,Loci.Err)
    stop("Conversion Stopped.",call.=FALSE)

  }

  return("ok")

}

#' GL String Allele Check
#'
#' GL String check for allele ambiguity formatting
#' @param x  GL String to check against
#' @note This function is for internal use only.
CheckString.Allele <- function(x) {

  x <- as.character(x)

  if(grepl("/",x)) {
      tmp <- strsplit(unlist(strsplit(x,"/")),"\\*")
      tmp.len <- length(unique(lapply(tmp,length)))
      if( tmp.len > 1 ) {
        Err.Log.GLS("Allele.Amb.Format",x)
        stop("Conversion Stopped.",call.=FALSE)
      }
    }

  return("ok")

}
