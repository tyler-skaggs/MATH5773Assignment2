#' Bootstraping
#'
#' @param df A data Frame
#' @param model A string indicating model1 or model2 (diameter or density)
#' @param iter Iterations of the sampling test
#' @param alpha Alpha value to create a confidence interval
#' @importFrom graphics hist layout
#' @importFrom stats qt
#'
#'
#' @return The function will make a histogram plot of each \eqn{\beta_i} from
#'    the sampling process. An invisible list will also be returned that contains
#'    the following:
#'    \itemize{
#'     \item{\code{beta_iters}}{ - A data frame of each \eqn{\beta} calculated from the iterations of sampling the `BUBBLE2` data}
#'     \item{\code{CI_beta}}{ - The confidence interval of the original point estimates of \eqn{\beta}}
#'     \item{\code{beta_pts}}{ - The point estimates of \eqn{\beta}}
#'     \item{\code{iter}}{ - The passed in value for the number of iterations}
#'     \item{\code{model}}{ - Chosen model for the function}
#'     \item{\code{alpha}}{ - Chosen alpha for the function}
#'    }
#' @export
#'
#' @examples
#' dataf <- data.frame(BUBBLE2)
#'
#' temp <- myboot(dataf, model = "model1", iter = 200, alpha = 0.05)
#' temp
#'
#' temp <- myboot(dataf, model = "model2", iter = 1000, alpha = 0.025)
#' temp
myboot <- function(df, model = "model1", iter = 1, alpha = 0.05){

  n = 18
  k = 2

  #Switch Statement to pick model
  mod_index <- switch (model,
                       model1 = 4, #column 4 is Diameter

                       model2 = 5  #column 5 is Density
  )

  ############## MAKING MATRICIES ##############
  X <- matrix(c(rep(1,n), df$MassFlux, df$HeatFlux), nrow = n, ncol = (k+1))
  Y <- as.matrix(df[mod_index])

  beta <- solve(t(X) %*% X) %*% (t(X) %*% Y)
  rownames(beta) <- c("(Intercept)", "MassFlux", "HeatFlux")

  ############## CALCULATING STATISTICAL VALUES ##############
  SSE <- ( t(Y) %*% Y ) - ( t(beta) %*% t(X) %*% Y)
  s.squared <- SSE/(n - (k+1)) #SSE / df
  C <- solve(t(X) %*% X)

  C_ii <- c() #C_ii is used to create confidence intervals
  for(i in 1:length(beta)){
    C_ii = c(C_ii, C[i,i])
  }

  ############## CREATING CI ##############
  Lower <- beta - qt(1-alpha/2, n-(k+1)) * sqrt(c(s.squared) * C_ii)
  Upper <- beta + qt(1-alpha/2, n-(k+1)) * sqrt(c(s.squared) * C_ii)

  CI <- matrix(c(Lower, Upper), nrow = k+1, ncol = 2)
  rownames(CI) <- c("(Intercept)", "MassFlux", "HeatFlux")
  colnames(CI) <- c(paste0(100*alpha/2, '%'), paste0(100*(1-alpha/2), '%'))



  ############## SAMPLING SECTION ##############
  hbetas <- matrix(NA, nrow = iter, ncol = 3)
  for(i in 1:iter){
    index <- sample(1:18, 18, replace = TRUE) #random sample of 18 data pts

    X_samp <- matrix(c(rep(1,n), df[index,]$MassFlux, df[index,]$HeatFlux),
                     nrow = n, ncol = (k+1))
    Y_samp <- as.matrix(df[index,][mod_index])

    hbetas[i,] <- solve(t(X_samp) %*% X_samp) %*% (t(X_samp) %*% Y_samp)
  }

  ############## PLOTTING AND RETURN ##############
  layout(matrix(1:3, nrow = 1,ncol = 3))
  hist(hbetas[,1],
       xlab = expression(widehat(beta)[0]),
       main = paste0("Histogram of intercept estimate\n",
                     "Point estimate: ", round(beta[1],8)))

  hist(hbetas[,2],
       xlab = expression(widehat(beta)[1]),
       main = paste0("Histogram of slope 1 estimate\n",
                     "Point estimate: ", round(beta[2],8)))

  hist(hbetas[,3],
       xlab = expression(widehat(beta)[2]),
       main = paste0("Histogram of slope 2 estimate\n",
                     "Point estimate: ", round(beta[3],8)))

  my_list <- list(beta_iters = as.data.frame(hbetas), CI_beta = CI,
                  beta_pts = beta, iter = iter, model = model, alpha = alpha)
  return(invisible(my_list))
}
