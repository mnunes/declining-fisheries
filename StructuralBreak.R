#######################################
### search for the structural break ###
#######################################

# Author: Marcus Nunes
# Site:   https://marcusnunes.me
# Year:   2019 

# function to find the structual breaks(s)

StructuralBreak <- function(series, histogram=FALSE, title=NULL, backgroundColor="white", seriesColour=0.7, x_axis="5 years", y_axis="Values", font=12){
  
  require(ggplot2) # plots
  require(strucchange) # structural breaks
	
	# series: data frame with two columns: date and value, in this order
	# histogram: plot data histogram? yes or no? (TRUE ou FALSE) (default: FALSE)
  # title: plot title (default: NULL)
  # backgroundColour: plot colour background (default: "white")
  # seriesColour: colour for the original time series. its value varies from 0 to 1, where 0 is black and 1 is white. intermediate values are greyscale. (default: 0.6)
  # x_axis: distance between two ticks on x axis. it is written like "5 years", "2 weeks" and so on. (default: "5 years")
  # y_axis: y axis title (default: "Values")
  # font: plot font size (default: 12)
	
	# rename columns
	names(series) <- c("date", "values")
	
	# series length
	n <- length(series$values)
	
	# transform values in a time series
	series.ST <- ts(series$values)
	
	# plot theme
	theme <- theme(plot.title=element_text(hjust=0.5), 
	               axis.line=element_line(colour="black"), 
	               panel.grid.major=element_blank(), 
	               panel.grid.minor=element_blank(), 
	               panel.border=element_blank(), 
	               panel.background=element_rect(fill=backgroundColor, colour=backgroundColor), 
	               plot.background=element_rect(fill=backgroundColor, colour=backgroundColor), 
	               legend.position="none", 
	               text = element_text(size=font))
	
	# values' histogram
	histogram.series <- ggplot(series, aes(x=values)) + 
	  geom_histogram(bins=20) + 
	  ylab("Frequency") + 
	  labs(title=title, x=y_axis) + 
	  scale_x_continuous(labels=comma) + 
	  theme
	suppressWarnings(print(histogram.series))
	
	# series' plot
	grafico.series <- ggplot(series, aes(x=date, y=values)) + 
	  geom_line(colour=paste0("grey", seriesColour*100)) + 
	  geom_point(colour=paste0("grey", seriesColour*100)) + 
	  labs(title=title, x="Year", y=y_axis) + 
	  scale_x_date(breaks=seq(min(series$date), max(series$date), by=x_axis), date_labels="%Y") + 
	  scale_y_continuous(labels=comma) + 
	  theme
	suppressWarnings(print(grafico.series))
	
	# structural breaks
	series.ST.bp <- breakpoints(series.ST ~ 1)
	
	# BIC calculation
	bic <- t(as.data.frame(summary(series.ST.bp)[3]))
	bic <- cbind(0:(nrow(bic)-1), bic)
	bic <- as.data.frame(bic)
	bic <- bic[, c(1, 3)]
	colnames(bic) <- c("BP", "BIC")
	rownames(bic) <- NULL
	
	# BIC plot
	grafico.bic <- ggplot(bic, aes(x=BP, y=BIC)) + 
	  geom_line() + 
	  scale_x_continuous(breaks=bic$BP) + 
	  xlab("Number of Structural Breaks") + 
	  ylab("BIC") + 
	  labs(title=title) + theme
	suppressWarnings(print(grafico.bic))
	
	# test to check if the number of structural breaks will be calculated
	
	if ((which.min(bic$BIC)-1) == 0){ 
		
	  return("There are no structural breaks. Look at the BIC.")
		
	} else {
		
		segments.old  <- breakfactor(series.ST.bp, breaks=length(series.ST.bp$breakpoints))
		segments      <- rep(NA, n)
		series.NA       <- is.na(series$values)
		
		i <- 1
		for (j in 1:n){
			if(series.NA[j]==TRUE){
				segments[j] <- segments.old[i]
			} else {
				segments[j] <- segments.old[i]
				i <- i+1
			}
		}
		
		segments <- as.factor(segments)
		
		# fit null and structural breaks models
		
		fm0 <- lm(values ~ 1, data=series)
		fm1 <- lm(values ~ segments, data=series)
		
		# data preparation
		
		modelo.nulo   <- rep(unique(round(fitted(fm0), 4)), n)
		modelo.quebra <- rep(unique(round(fitted(fm1), 4)), table(segments))
		
		# add NA in the series end if needed
		
		n.nulo   <- length(modelo.nulo)
		n.quebra <- length(modelo.quebra)
		if(n.nulo!=n.quebra){
			modelo.quebra[n.nulo] <- modelo.quebra[n.quebra]
		}
		
		series <- cbind(series, modelo.nulo, modelo.quebra, segments)
		
		# graficos
		
		# fitted models plot
		
		fitted.models.plot <- ggplot(series, aes(x=date)) + 
		  geom_line(aes(y=values, colour="Original series")) + 
		  geom_point(aes(y=values, colour="Original series")) + 
		  geom_line(aes(y=modelo.quebra, colour="Structural Breaks Model"), size=1.25) + labs(title=title, x="Year", y=y_axis) + 
		  scale_colour_grey(start = seriesColour, end = 0, name="") + 
		  scale_x_date(breaks=seq(min(series$date), max(series$date), by=x_axis), date_labels="%Y") +
		  scale_y_continuous(labels=comma) + 
		  theme
		  
		suppressWarnings(print(fitted.models.plot))
		
		# confidence interval
		
		series.ST.bp.CI <- confint(series.ST.bp)
		series.CI       <- series.ST.bp.CI$confint
		
		# CI correction if NA is present
		
		n.bp <- dim(series.CI)[1]
		
		series.CI.fixed      <- matrix(NA, nrow=n.bp, ncol=3)
		series.CI.fixed.data <- data.frame(matrix(NA, nrow=n.bp, ncol=3))
		
		for (j in 1:n.bp){

			bp.fixed <- tail(which(segments==j), n=1)
			LimInf       <- series.CI[j, 2]-series.CI[j, 1]
			LimSup       <- series.CI[j, 3]-series.CI[j, 2]
			
			series.CI.fixed[j, 1] <- bp.fixed - LimInf
			series.CI.fixed[j, 2] <- bp.fixed
			series.CI.fixed[j, 3] <- bp.fixed + LimSup
			
			if (j == 1){
				series.CI.fixed.data <- data.frame(series[series.CI.fixed[j, ], "date"])
			} else {
				series.CI.fixed.data <- data.frame(series.CI.fixed.data, series[series.CI.fixed[j, ], "date"])
			}
			
		}
		
		# resuts presentantion fixed
		series.CI.fixed.data           <- t(series.CI.fixed.data)
		colnames(series.CI.fixed.data) <- c("Inf Lim", "Break", "Sup Lim")
		rownames(series.CI.fixed.data) <- paste("Break", 1:n.bp)
		
		# structural breaks average
		breaks.avg <- c(coefficients(fm1)[1], tail(coefficients(fm1)[1]+coefficients(fm1), n=n.bp))
		names(breaks.avg) <- paste("Sub-series", 1:(n.bp+1))
		
		# organize the results
		results <- list()
		
		# BIC
		results[[1]] <- bic
		
		# dates for the breaks
		
		datas.corretas <- data.frame(matrix(NA, nrow=n.bp, ncol=3))
		for (i in 1:n.bp){
			for (j in 1:3){
				datas.corretas[i, j] <- as.Date(series.CI.fixed.data[i, j])
			}
		}
		
		results[[2]] <- series.CI.fixed.data
		
		# averages for each sub-series
		
		results[[3]] <- breaks.avg
		
		# results
		
		return(results)
	}
	
}

