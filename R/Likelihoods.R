# @file Likelihoods.R
#
# Copyright 2021 Observational Health Data Sciences and Informatics
#
# This file is part of EmpiricalCalibration
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

gaussianProduct <- function(mu1, mu2, sd1, sd2) {
  (2 * pi)^(-1/2) * (sd1^2 + sd2^2)^(-1/2) * exp(-(mu1 - mu2)^2/(2 * (sd1^2 + sd2^2)))
}

logLikelihoodNull <- function(theta, logRr, seLogRr) {
  if (theta[2] <= 0)
    return(99999)
  result <- 0
  sd <- 1/sqrt(theta[2])
  if (sd < 1e-6) {
    for (i in 1:length(logRr)) {
      result <- result - dnorm(theta[1], logRr[i], seLogRr[i], log = TRUE)
    }
    
  } else {
    for (i in 1:length(logRr)) {
      result <- result - log(gaussianProduct(logRr[i], theta[1], seLogRr[i], sd))
    }
  }
  if (length(result) == 0 || is.infinite(result))
    result <- 99999
  result
}

logLikelihoodNullMcmc <- function(theta, logRr, seLogRr) {
  result <- logLikelihoodNull(theta, logRr, seLogRr)
  
  # Add weak prior for when precision becomes very large:
  result <- result - dgamma(theta[2], shape = 1e-04, rate = 1e-04, log = TRUE)
  return(result)
}

minLogLikelihoodErrorModel <- function(theta, logRr, seLogRr, trueLogRr) {
  estimateLl <- function(i) {
    mean <- theta[1] + theta[2] * trueLogRr[i]
    sd <- theta[3] + theta[4] * abs(trueLogRr[i])
    if (sd < 0) {
      return(Inf)
    } else if (sd < 1e-6) {
      return(-dnorm(logRr[i], mean, seLogRr[i], log = TRUE))
      } else {
      return(-log(gaussianProduct(logRr[i], mean, seLogRr[i], sd)))
    }
  }
  result <- sum(sapply(1:length(logRr), estimateLl))
  if (is.infinite(result) || is.na(result))
    result <- 99999
  result
}

minLogLikelihoodErrorModelLegacy <- function(theta, logRr, seLogRr, trueLogRr) {
  result <- 0
  for (i in 1:length(logRr)) {
    mean <- theta[1] + theta[2] * trueLogRr[i]
    sd <- exp(theta[3] + theta[4] * trueLogRr[i])
    result <- result - log(gaussianProduct(logRr[i], mean, seLogRr[i], sd))
  }
  if (is.infinite(result) || is.na(result))
    result <- 99999
  result
}
