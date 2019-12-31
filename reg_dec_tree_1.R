### Second attempt at regression and decision trees

library(rpart)
library(car)
library(lattice)
library(Hmisc)
library(caret)
library(dplyr)
library(infotheo)
library(dplyr)
library(funModeling)
library(e1071)
library(RWeka)
library(party)

# Read in the dataset
org.data <- read.csv("TCP_dataset3.csv")

# Make the number of post fin resets the first data feature in the set 
data <- org.data[,c(ncol(org.data),1:(ncol(org.data)-1))]

### Regression Tree

# Partition the data into training and test sets using a 60:40 split
set.seed(1)
trainSet <- createDataPartition(data$post_fin_resets, p=.6)[[1]]
data.train <- data[trainSet,]
data.test <- data[-trainSet,]

# Create a regression tree for the numeric packets data
data.model.reg <- rpart(post_fin_resets ~ ., data=data.train[,1:ncol(data.train)])

# Create predictions from the regression tree model using the test set
data.predict.reg <- predict(data.model.reg, data.test)

# Display numeric results from the regression tree
# MSE
data.predict.reg.mse <- mean((data.predict.reg - data.test$post_fin_resets)^2)
print(paste("Mean Squared Error (MSE):", data.predict.reg.mse))

# RMSE
data.predict.reg.rmse <- sqrt(data.predict.reg.mse)
print(paste("Root Mean Squared Error (RMSE)", data.predict.reg.rmse))

# MAE
data.predict.reg.mae <- mean(abs(data.predict.reg - data.test$post_fin_resets))
print(paste("Mean Absolute Error (MAE):", data.predict.reg.mae))

### Prune the tree

# Print the CP table
printcp(data.model.reg)

# Create vector for the regression tree with the least error
bestcp <- data.model.reg$cptable[which.min(data.model.reg$cptable[,"xerror"]),"CP"]

# Prune tree using tree with the least error
data.model.reg.pruned <- prune(data.model.reg, cp = bestcp)

# Examine the pruned tree
plot(data.model.reg.pruned)
text(data.model.reg.pruned, cex = 0.8, use.n = TRUE, xpd = TRUE)

### Decision Tree  

## Part 1: Boolean nominal classifier
org.data <- read.csv("TCP_dataset3.csv")

# Create a nominal classifier for the presence of a post fin resets, using only two bins
org.data$has_reset="Yes"
org.data[org.data$post_fin_resets==0,]$has_reset="No"


# Carry last column to the first column
data <- org.data[,c(ncol(org.data),1:(ncol(org.data)-1))]

# Drop the nominal feature 
drops <- c("post_fin_resets")
data <- data[, !(names(data) %in% drops), drop = F]


write.csv(data, "test_dropped.csv")

# Partition the data using a 60:40 train:test split 
set.seed(1)
org.data$has_reset <- factor(org.data$has_reset)
trainSet <- createDataPartition(data$has_reset, p=.6)[[1]]
data.train <- data[trainSet,]
data.test <- data[-trainSet,]

# Create the model
data.model.nom <- rpart(has_reset ~., data=data.train[,1:ncol(data.train)])

printcp(data.model.nom) # display the results
plotcp(data.model.nom) # visualize cross-validation results
summary(data.model.nom) # detailed summary of splits

### Part 2: Four-Level nominal classifier
org.data <- read.csv("TCP_dataset3.csv")

# Descritize the numeric feature into 4 groups 
org.data$has_reset="Some"
org.data[org.data$post_fin_resets>4,]$has_reset="Many"
org.data[org.data$post_fin_resets==0,]$has_reset="None"

org.data$post_fin_resets <- factor(org.data$post_fin_resets)
# Carry last column to the first column
data <- org.data[,c(ncol(org.data),1:(ncol(org.data)-1))]

# Drop the numeric feature
drops <- c("post_fin_resets")
data <- data[, !(names(data) %in% drops), drop = F]

# Partition the data
set.seed(1)
trainSet <- createDataPartition(data$has_reset, p=.6)[[1]]
data.train <- data[trainSet,]
data.test <- data[-trainSet,]

# Create model
data.model.nom <- rpart(has_reset ~., data=data.train[,1:ncol(data.train)])

printcp(data.model.nom) # display the results
plotcp(data.model.nom) # visualize cross-validation results
summary(data.model.nom) # detailed summary of splits






