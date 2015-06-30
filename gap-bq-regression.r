# Copyright 2015 Google Inc. All rights reserved.
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

##########################################
# Optional: Install Required Packages
##########################################

# For visualization
# install.packages("ggplot2", repos="http://cran.rstudio.com/")
library(ggplot2)

# Check the VIF, to find multicollinearity.
# install.packages("car", repos="http://cran.rstudio.com/")
library(car)

# To Plot ROC curve 
# install.packages("ROCR", repos="http://cran.rstudio.com/")
library(ROCR)

# To check model 
# install.packages("rms", repos="http://cran.rstudio.com/")
library(rms)

########################################
# Process the Data
########################################

data1 <- read.csv("./sample_data/train_data_scrubbed.csv")
names(data1)

# Delete unnecessary columns
data1 <- data1[c(-1,-2,-12,-22)]

# Calculate correlation coefficient 
cor(data1)
symnum(abs(cor(data1)),cutpoints = c(0, 0.2, 0.4, 0.6, 0.9, 1), symbols = c(" ", ".", "_", "+", "*"))

# Delete "SUM_totals_hits" & "diffdays_oldest" as those correlation 
# coefficients are higher than 0.9
data1 <- data1[c(-3,-7)]
names(data1)

# If we ran the model now, we would find that the regression
# coefficient for the "midnight_flag" variable would be undefined
# so we remove this variable from the model as well.
data1 <- data1[,c(-13)]
names(data1)

# Run the logistic analysis
model <- glm(formula = b_CV_flag ~., data = data1, family = binomial("logit"))
result <- summary(model)
result

# Check the VIF, to find multicollinearity.
vif(model)

# When check the result from the VIF calculation above, there are two
# variables that are over 10, "SUM_totals_pageviews" (over 30) and 
# "SUM_hits_hitNumber" (over 27). In other words, multicollinearity occurs.
# Therefore, we have to delete one of the variables, in this case
# "SUM_totals_pageviews" and rerun the logistic analysis.

# Delete the "SUM_totals_pageviews" variable. And rerun the logistic regression analysis.
data1_2 <- data1[,c(-2)] 
model1_2 <- glm(formula = b_CV_flag ~., data = data1_2, family = binomial("logit"))
result1_2 <- summary(model1_2)
result1_2

# Check VIF again to verify that the multicollinearity is no longer occuring.
vif(model1_2)

# None of the variables have values over 10, so there is no multicollinearity
# and we can use this model.

############################
# Generate GAIN Curve
############################

prob <- data.frame(predict(model1_2, data1_2, type = "response"))
gain <- cumsum(sort(prob[, 1], decreasing = TRUE)) / sum(prob)

# Save the plot in local file
png('gain_curve_plot.png')
plot(gain,main ="Gain chart",xlab="number of users", ylab="cumulative conversion rate")
dev.off()

############################
# Generate ROC Curve
############################

pred <- prediction(prob, data1_2$b_CV_flag)
perf <- performance(pred, measure = "tpr", x.measure = "fpr")

# Plot and save as Rplots.pdf in local file
qplot(x = perf@x.values[[1]], y = perf@y.values[[1]], xlab = perf@x.name, ylab = perf@y.name, main="ROC curve")
dev.off() 

#####################################
# Model Verification
#####################################

# Check model with R package
Logistic_Regression_Model <- lrm(b_CV_flag ~., data1_2)
Logistic_Regression_Model

# Check AIC (An Information Criteria) of the two models
# to verify which is better. A smaller number is better.
AIC(model)
AIC(model1_2)

# Summarize the coefficient values for easy transfer to BigQuery
# SQL statement
coef <- names(model1_2$coefficient)
value <- as.vector(model1_2$coefficient)
result <- data.frame(coef, value)
result
