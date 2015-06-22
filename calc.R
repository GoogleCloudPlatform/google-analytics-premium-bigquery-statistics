############################################################
# 1. Data Import and check
############################################################

# 1-1. Data Import
setwd("/home/dmp_user/dmp_sample/script") # set working directory to GCE environment
getwd()

# get data as object from BigQuery-Python environment
data1 <- df
data2 <- read.csv("variable_type.csv")

############################################################
# 2. Logistic regression analysis
############################################################
num1 <- ncol(data1)
data1 <- data.frame(data1)

num2 <- nrow(data2)
data2 <- data.frame(data2)
type_list <- c(data2$type)

# check type of variable. (continuous or categorical)
for(k in 1:num1-1){
  if(type_list[k+1]==1){
    data1[, k+1] <- as.factor(data1[, k+1])
  } else {
    data1[, k+1] <- as.numeric(data1[, k+1])
  }
}

data3 <- data1
data1 <- data1[, -1]

# logistic regression analysis
model <- glm(formula = CV_flag ~., data = data1, family = binomial("logit"))
result <- summary(model)
prob <- data.frame(predict(model, data1, type = "response"))
list <- cbind(data3$fullVisitorId, prob, data3$CV_flag)

############################################################
# 3. Result
############################################################

# give the objects "coef" and "value" to BigQuery-Python environment
# Then, score the unmatched GA users on BigQuery using exp function
coef <- names(model$coefficient)
value <- as.vector(model$coefficient)
result <- data.frame(coef, value)
result

#########################################################
# 4-1. plot histogram of variable 2. COUNT_fullVisitorId
#########################################################
flag2 <- data.frame(flag2 = sample(0:1,nrow(data1),replace=T))
data_test2 <- data.frame(data1$COUNT_fullVisitorId,as.numeric(data1$CV_flag))

# calculate the right answer ratio
par(mfrow=c(1,1))
hist2 <- hist(data_test2[,1], col = "gray", main = "title", breaks=100)
x_axis<-data.frame(g = hist2$breaks)
x_axis<-cbind(x_axis,pro=c(0))
for(i in 1:nrow(x_axis)){
  if (i>=2){
    temp <- data_test2[data_test2[,1] >= x_axis[i-1,1] & data_test2[,1] < x_axis[i,1],2]
    t_n <- length(temp)
    t_the_right_answer <- sum(temp)
    if(t_the_right_answer==0 |t_n==0){
      pro<-0
    }else{
      pro <- t_the_right_answer/t_n
    }
    x_axis[i-1,2] <- pro
  }  
}

# plot histogram
par(mar=c(5,4,5,4))
hist(data_test2[,1], col = "gray", main = "Session_times", xlim=c(1,10),breaks = 100, xlab="Session_times",ylab="Frequency")
par(new=T)                                           
matplot(x_axis$pro,pch=2,type="o",xaxt="n",yaxt="n",ylab="",col="blue",xlim=c(1,5),ylim=c(0.0,1.0))
axis(4, col.axis="blue")
mtext("conversion rate", col='blue', side = 4, line = 2)

###################################################
# 4-2. variable 3. plot histogram of AVG_hits_hour
###################################################
par(mfrow=c(1,1))
flag3 <- data.frame(flag3=sample(0:1,nrow(data1),replace=T))
data_test3 <- data.frame(data1$AVG_hits_hour,as.numeric(data1$CV_flag))

# calculate the right answer ratio
hist3 <- hist(data_test3[,1], col = "gray", main = "title", breaks=24)
print(hist3)
x_axis3 <- data.frame(g=hist3$breaks)
x_axis3 <- cbind(x_axis3,pro=c(0))
for(i in 1:nrow(x_axis3)){
  if (i>=2){
    temp3 <- data_test3[data_test3[,1] >= x_axis3[i-1,1] & data_test3[,1] < x_axis3[i,1],2]
    t_n3 <- length(temp3)
    t_the_right_answer3 <- sum(temp3)
    if(t_the_right_answer3==0 |t_n3==0){
      pro3 <- 0
    }else{
      pro3 <- t_the_right_answer3 / t_n3
    }
    x_axis3[i-1,2] <- pro3
  }
}

#plot histogram
par(mar=c(5,4,5,4))
hist(data_test3[,1], col = "gray", main = "AVG_hits_hour", xlim=c(0,23),breaks = 24, xlab="average time zone of hits")
par(new=T)                                            
matplot(x_axis3$pro,pch=2,type="o",xaxt="n",yaxt="n",ylab="",col="blue",xlim=c(1,24),ylim=c(0.0,0.12))
axis(4, col.axis="blue",ylab="conversion rate")
mtext("conversion rate", col='blue', side = 4, line = 2)

#########################################################
# 4-3.plot histogram of variable 4. SUM_totals_pageviews
#########################################################
#par(mfrow=c(1,1))
flag4 <- data.frame(flag4 = sample(0:1, nrow(data1), replace = T))
data_test4 <- data.frame(data1$SUM_totals_pageviews,as.numeric(data1$CV_flag))

# calculate the right answer ratio
hist4 <- hist(data_test4[,1], col = "gray", main = "title", breaks=100)
print(hist4)
x_axis4 <- data.frame(g=hist4$breaks)
x_axis4 <- cbind(x_axis4,pro=c(0))
for(i in 1:nrow(x_axis4)){
  if (i>=2){
    temp4 <- data_test4[data_test4[,1] >= x_axis4[i-1,1] & data_test4[,1] < x_axis4[i,1],2]
    t_n4 <- length(temp4)
    t_the_right_answer4 <- sum(temp4)
    if(t_the_right_answer4==0 |t_n4==0){
      pro4 <- 0
    }else{
      pro4 <- t_the_right_answer4 / t_n4
    }
    x_axis4[i-1,2] <- pro4
  }
}

#plot Figure
par(mar=c(5,4,5,4))
hist(data_test4[,1], col = "gray", main = "sum of total pageviews", xlim=c(0,35000),breaks = 100, xlab="sum of total pageviews")
par(new=T)                                            
matplot(x_axis4$pro,pch=2,type="o",xaxt="n",yaxt="n",ylab="",col="blue",xlim=c(1,10),ylim=c(0.0,1.0))
axis(4, col.axis="blue",ylab="conversion rate")
mtext("conversion rate", col='blue', side = 4, line = 2)

###############################################
# 4-4. plot histogram of variable 5. MAX_date
###############################################
flag5 <- data.frame(flag5 = sample(0:1, nrow(data1), replace = T))
data_test5 <- data.frame(data1$diffdays,as.numeric(data1$CV_flag))

# calculate the right answer ratio
hist5 <- hist(data_test5[,1], col = "gray", main = "MAX_date", breaks=10)
print(hist5)
x_axis5 <- data.frame( g = hist5$breaks)
x_axis5 <- cbind(x_axis5,pro5=c(0))
for(i in 1:nrow(x_axis5)){
  if (i>=2){
    temp5 <- data_test5[data_test5[,1] >= x_axis5[i-1,1] & data_test5[,1] < x_axis5[i,1],2]
    t_n5 <- length(temp5)
    t_the_right_answer5 <- sum(temp5)
    if(t_the_right_answer5==0 |t_n5==0){
      pro5 <- 0
    }else{
      pro5 <- t_the_right_answer5 / t_n5
    }
    x_axis5[i-1,2] <- pro5
  }
}

#plot Figure
par(mar=c(5,4,5,4))
hist(data_test5[,1], col = "gray", main = "the latest access day", xlim=c(0,50),breaks = 10, xlab="the latest access day")
par(new=T)                                           
matplot(x_axis5$pro,pch=2,type="o",xaxt="n",yaxt="n",ylab="",col="blue",xlim=c(0.5,10.5),ylim=c(0.0,1.0))
axis(4, col.axis="blue",ylab="conversion rate",cex.axis=0.7)
mtext("conversion rate", col='blue', side = 4, line = 2)

###############################################
# 4-5. plot barplot of variable6. OS_Windows
###############################################
data_test6 <- data.frame(as.numeric(data1$OS_Windows),as.numeric(data1$CV_flag))

hist6 <- hist(data_test6[,1], col = "gray", main = "title", breaks=2)
print(hist6)
x_axis6 <- data.frame( g = c(0,1))
x_axis6 <- cbind(x_axis6,pro6=c(0))
for(i in 1:nrow(x_axis6)){
  temp6 <- data_test6[data_test6[,1] == x_axis6[i,1],2]
  t_n6 <- length(temp6)
  t_the_right_answer6 <- sum(temp6)
  if (t_n6 == 0){
    pro6 <- 0
  }else{
    pro6 <- t_the_right_answer6 / t_n6
  }
  x_axis6[i,2] <- pro6
}
# plot barplot
par(mar=c(5,4,5,4))
barplot(table(data1$OS_Windows),main="OS_Windows",xlab="OS_Windows",ylab="number of user")
par(new=T)                                            
matplot(x_axis6$pro,pch=2,type="o",xaxt="n",yaxt="n",ylab="",col="blue",ylim=c(0.0,1.0))
axis(4, col.axis="blue",cex.axis=0.7)
mtext("conversion rate", col='blue', side = 4, line = 2)

################################################
# 4-6. plot barplot of variable7. OS_Machintosh
################################################
data_test7 <- data.frame(as.numeric(data1$OS_Macintosh),as.numeric(data1$CV_flag))
# calculate the right answer ratio
hist7 <- hist(data_test7[,1], col = "gray", main = "title", breaks=2)
print(hist7)
x_axis7 <- data.frame( g = c(0,1))
x_axis7 <- cbind(x_axis7,pro7=c(0))
for(i in 1:nrow(x_axis7)){
  temp7 <- data_test7[data_test7[,1] == x_axis7[i,1],2]
  t_n7 <- length(temp7)
  t_the_right_answer7 <- sum(temp7)
  if (t_n7 == 0){
    pro7 <- 0
  }else{
    pro7 <- t_the_right_answer7 / t_n7
  }
  x_axis7[i,2] <- pro7
}
# plot barplot
par(mar=c(5,4,5,4))
barplot(table(data1$OS_Macintosh),main="OS_Macintosh",xlab="OS_Macintosh",ylab="number of user")
par(new=T)                                            
matplot(x_axis6$pro,pch=2,type="o",xaxt="n",yaxt="n",ylab="",col="blue",ylim=c(0.0,1.0))
axis(4, col.axis="blue",cex.axis=0.7)
mtext("conversion rate", col='blue', side = 4, line = 2)

#####################################
# 5. correlation coefficient 
####################################
cor(data1[c(-1)])
symnum(abs(cor(data1[-1])),cutpoints = c(0, 0.2, 0.4, 0.6, 0.8, 1), symbols = c(" ", ".", "_", "+", "*"))


############################################################
# 6. Gainchart
############################################################
num1 <- ncol(data1)
data1 <- data.frame(data1)

num2 <- nrow(data2)
data2 <- data.frame(data2)
type_list <- c(data2$type)

# check type of variable. (continuous or categorical)
for(k in 1:num1-1){
  if(type_list[k+1]==1){
    data1[, k+1] <- as.factor(data1[, k+1])
  } else {
    data1[, k+1] <- as.numeric(data1[, k+1])
  }
}
data3 <- data1
data3 <- data3[, -1]
# logistic regression analysis
model <- glm(formula = CV_flag ~., data = data1, family = binomial("logit"))
result <- summary(model)
prob <- data.frame(predict(model, data3, type = "response"))
list <- cbind(data1$fullVisitorId, prob, data1$CV_flag)
# plot GAIN chart
gain <- cumsum(sort(prob[, 1], decreasing = TRUE)) / sum(prob)
plot(gain,main ="Gain chart",xlab="number of users", ylab="cumulative conversion rate")
options(scipen=1)
############################################################
# 6. ROC curve
############################################################
# to Plot ROC curve 
#install.packages("ROCR")
#library(ROCR)
pred <- prediction(prob, data1$CV_flag)
perf <- performance(pred, measure = "tpr", x.measure = "fpr") 
qplot(x = perf@x.values[[1]], y = perf@y.values[[1]], xlab = perf@x.name, ylab = perf@y.name,main="ROC curve")
############################################################
