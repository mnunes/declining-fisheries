# Description

R Code for the upcoming paper "Declining fisheries and increasing prices: the economic cost of tropical rivers impoundment" by Lima, M. A. L. L., Carvalho, A. R., Nunes, M. A., Angelini, R., and Doria, C. R. C. 

This code uses one of Bai and Perron (2003) methods to find structural breaks in times series' means. 

# Usage

Function `StructuralBreak` estimates the break points and their confidence intervals. Besides that, it plots the data histogram, the fitted model, and calculates the sample mean for each part of the time series. It also provides the BIC calculations in order to report the best fitted model.

You can find an usage example with simulated data below.

```r
library(ggplot2)
set.seed(123)
mock_data <- data.frame(x = seq.Date(from=ymd("1990-01-01"), 
                                     length.out = 300, 
                                     by = "1 month"), 
                        y = c(rnorm(100), rnorm(100, 2), rnorm(100, -2)))

ggplot(mock_data, aes(x = x, y = y)) +
  geom_line()
```

![simulated time series](images/ts.png)

```r
StructuralBreak(mock_data)
[[1]]
  BP       BIC
1  0 1266.3174
2  1 1039.4189
3  2  876.4162
4  3  884.7774
5  4  894.2635
6  5  904.5620

[[2]]
        Inf Lim      Break        Sup Lim     
Break 1 "1998-01-01" "1998-04-01" "1998-07-01"
Break 2 "2006-07-01" "2006-08-01" "2006-09-01"

[[3]]
Sub-series 1 Sub-series 2 Sub-series 3 
 -0.03622291   2.10585093  -2.04229996
```

![simulated time series](images/ts_sb.png)

![histogram](images/hist.png)

![bic](images/bic.png)

![final model](images/final_model.png)



# References

Bai, J., Perron, P., 2003. "Computation and analysis of multiple structural change models". *J. Appl. Econom*. **18**, 1–22. https://doi.org/10.1002/jae.659