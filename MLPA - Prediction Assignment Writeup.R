#Peer-graded Assignment: Prediction Assignment Writeup
#Coursera Pratical Machine Learning Course
#Gabriel Lages
#October 12, 2016

# In this project we will use the data from a experiment that used wearable 
# accelerometers on the belt, forearm, arm, and dumbell of 6 participants
# to classify the body posture and movement of them. Our goal in this project
# is to predict the manner in which they did the exercise using Machine Learning models.

# Steps of the study
# 1 - Get and clean the Data
# 2 - Explore the dataset
# 3 - Model estimation
# 4 - Model test and evaluation
# 5 - Model application

----------------------------------------------------------------------------------
# Prepairing the working directory and packages
  

setwd('C:/Gabriel/Biblioteca/Cursos/R - Assignment/ML - Peer graded Assignment')

#Uploading packages
library(downloader)
library(lubridate)
library(ggplot2)
library(corrplot)
library(caret)
library(e1071)
library(Hmisc)
library(randomForest)
library(rpart)
library(rpart.plot)
# 1 - Get and clean the Data

# 1.1 - Data Source
# This study used the DLA Dataset, a dataset with 5 classes (sitting-down, standing-up, standing, walking, and sitting) collected on 8 hours of activities of 4 healthy subjects.
# It's part of  the following puplication: 
#Wearable Computing: Accelerometers' Data Classification of Body Postures and Movements
#Ugulino, W.; Cardador, D.; Vega, K.; Velloso, E.; Milidiu, R.; Fuks, H. Wearable Computing: Accelerometers' Data Classification of Body Postures and Movements. Proceedings of 21st Brazilian Symposium on Artificial Intelligence. Advances in Artificial Intelligence - SBIA 2012. In: Lecture Notes in Computer Science. , pp. 52-61. Curitiba, PR: Springer Berlin / Heidelberg, 2012. ISBN 978-3-642-34458-9. DOI: 10.1007/978-3-642-34459-6_6.
# More information is available from the following website: 
# http://groupware.les.inf.puc-rio.br/har

#For this project we are provided with two different subset of this data, the training and the test dataset

#Downloading the data
trainingfileurl<- "https://d396qusza40orc.cloudfront.net/predmachlearn/pml-training.csv"
download(trainingfileurl, dest='./pml-training.csv', mode="wb")

testingfileurl<- "https://d396qusza40orc.cloudfront.net/predmachlearn/pml-testing.csv"
download(testingfileurl, dest='./pml-testing.csv', mode="wb")

#Reading and processing Data

# When we tried to Summarize the Data we found a lot of inconsistencies linke blank fields, nas, and incorrect values
# So we need to get the data cleaned, classifying the NA values ("#DIV/0!" and "NA")

trainingdata <- read.csv("./pml-training.csv", row.names = 1, stringsAsFactors = FALSE, na.strings=c("#DIV/0!", "" , "NA"))
head(trainingdata)
summary(trainingdata)

testingdata <- read.csv("./pml-testing.csv", row.names = 1, stringsAsFactors = FALSE, na.strings=c("#DIV/0!", "" , "NA"))
head(testingdata)
summary(testingdata)

# The next step is to check if the format of the columns are correct
sapply(trainingdata, class)
sapply(testingdata, class)


#Formatting Training dataset columns
trainingdata$user_name = as.factor(trainingdata$user_name)
trainingdata$cvtd_timestamp = mdy_hm(trainingdata$cvtd_timestamp)
trainingdata$new_window = as.factor(trainingdata$new_window)
trainingdata$classe = as.factor(trainingdata$classe)

#Formatting Testing dataset columns
testingdata$user_name = as.factor(testingdata$user_name)
testingdata$cvtd_timestamp = mdy_hm(testingdata$cvtd_timestamp)
testingdata$new_window = as.factor(testingdata$new_window)

# 2 - Explore the dataset

#In this step we will first analyze the amount of missing data

missing_values <- is.na(trainingdata)
missing_values_rates <- colMeans(missing_values)
percent_missing_90 <- names(which(missing_values_rates > 0.9))

missing_values_test <- is.na(testingdata)
missing_values_rates_test <- colMeans(missing_values_test)

#Looking to the missing rates of columns, we could see that 100 columns has more than 90% of missing values

without_missing_values  <- names(which(missing_values_rates == 0))
without_missing_values_test  <- names(which(missing_values_rates_test == 0))

#We have 59 columns that don't have any missing value, so we decided to keep just this columns on the dataset 

trainingdata_clean <- trainingdata[,without_missing_values]
testingdata_clean <- testingdata[,without_missing_values_test]

#With the final data we will try to explore the realtion between the numeric features

#First we need to filter just the numerical features
filter = grepl("belt|arm|dumbell", names(trainingdata_clean))
numeric_training = trainingdata_clean[, filter]
numeric_testing = testingdata_clean[, filter]

training_outcomes<-as.factor(trainingdata_clean$classe)

# We will use the correlation plot to understand the correlation of the features

png("corrplot.png")
corrplot.mixed(cor(numeric_training), lower="circle", upper="color", tl.pos="lt", diag="n", order="hclust", hclust.method="complete")
dev.off()


final_training_set<-numeric_training
final_training_set$classe <- training_outcomes




# The first step to estimate our model is to slice the data in two different datasets

set.seed(7897) #We will set seed to make a reproducible report

training_slice <- createDataPartition(final_training_set$classe, p=0.75, list=F)
model_training <- final_training_set[training_slice,]
model_testing <- final_training_set[-training_slice,]

#To try to predict the activity recognition, we will estimate a Random Forest model
# We decided to start with this model because, generally, it's a simple and robust method. 
# We will estimate the model using 5-fold cross validation.

#The first step is to train the model with 75% of the data 

control_Randomforest <- trainControl(method="cv", 5)
Random_Forest_model <- train(classe ~ ., data=model_training, method="rf", trControl=control_Randomforest, ntree=250)

Random_Forest_model

#The statistics of the estimated model indicates that we need 39 predictors to estimate a model with 98% of accuracy

# 4 - Model test and evaluation

#The next step is to test the estimated model, we will use the validation set with 25% of the data to do it

Randon_forest_predict <- predict(Random_Forest_model, model_testing)

#The confusion matrix, can help us understandig the accuracy of the estimated model
confusionMatrix(model_testing$classe, Randon_forest_predict)

#According to the confusion matrix results, the test shows that the model has 99,23% of accuracy
# This is a good result and indicates that we estimated a robust prediction model
#Now we will plot the Decision Tree Model to help us to visualizate the model

treeModel <- rpart(classe ~ ., data=model_training, method="class")

png("treemodel.png", units="px", width=1600, height=1000, res=300)
rpart.plot(treeModel, type=4, fallen=T, branch=.4, digits=2, round=0, leaf.round=9,
           clip.right.labs=F, under.cex=1, branch.lwd=2, extra=100,
           under=F, lt=" < ", ge=" >= ")
dev.off()

# 5 - Model application

# Now we have a tested and validated model and we need to applicate it to predict the testing_dataset outcomes

numeric_testing<-sapply(numeric_testing, as.numeric)
model_application <- predict(Random_Forest_model, numeric_testing)
model_application

# The final prediction is  = 1.B 2.A 3.B 4.A 5.A 6.E 7.D 8.B 9.A 10.A 11.B 12.C 13.B 14.A 15.E 16.E 17.A 18.B 19.B 20.B
