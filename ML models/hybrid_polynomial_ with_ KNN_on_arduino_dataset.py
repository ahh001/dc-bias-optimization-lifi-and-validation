"""
#******This script to apply Hybrid polynomail regression with KNN on arduino dataset (hardware)****
"""

import pandas as pd
import seaborn as sns
import numpy as np
import matplotlib.pyplot as plt

#******Data loading****
iris = pd.read_csv('HW_dataset.csv')
#print(iris.shape)
#print(iris.columns)
iris.head()
iris["bias"].value_counts()
x = iris.drop(['bias'], axis=1);
y = iris['bias'];
x, y = np.array(x), np.array(y)

#*****added for feature selection****
from sklearn.feature_selection import SelectKBest,f_regression
selection = SelectKBest(f_regression, k=4).fit(x,y)   
x_new=selection.transform(x)

#******Applying Polynomial Regression and KNN*****
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import  PolynomialFeatures
from sklearn.neighbors import KNeighborsRegressor

from sklearn.model_selection import train_test_split
x_train, x_test, y_train, y_test= train_test_split(x_new,y,shuffle=False,test_size=0.3); 

# Polynomial Regression
poly_reg = PolynomialFeatures(degree=2) 
x_poly = poly_reg.fit_transform(x_train)
LRP = LinearRegression()
LRP.fit(x_poly, y_train)

# KNN Regression
k =1 # Change the number of nearest neighbors
KNNR = KNeighborsRegressor(n_neighbors=k)
KNNR.fit(x_train, y_train)

# Hybrid Model Prediction
y_predict_poly = LRP.predict(poly_reg.fit_transform(x_test))
y_predict_knn = KNNR.predict(x_test)
y_predict = (y_predict_poly + y_predict_knn) / 2

#******Calculating RMSE and R2-square*****
from sklearn.metrics import mean_squared_error, r2_score
rmse = np.sqrt(mean_squared_error(y_test,y_predict))
r2 = r2_score(y_test,y_predict)
print("RMSE value = ",rmse)
print("R2 score = ",r2)
mape = np.mean(np.abs((y_test - y_predict) / y_test)) * 100
print('MAPE:', mape)

y_predict_poly_sorted = [x for _,x in sorted(zip(y_test,y_predict_poly))]
y_predict_sorted = [x for _,x in sorted(zip(y_test,y_predict))]
y_test.sort()

#print(y_test)
#print(y_predict_poly_sorted)
#print(y_predict_sorted)     
np.savetxt("y_test37.txt", np.array(y_test), fmt="%s")
np.savetxt("y_predict_poly37.txt", np.array(y_predict_poly_sorted), fmt="%s")   
np.savetxt("y_predict_hybrid37.txt", np.array(y_predict_sorted), fmt="%s")
plt.title(' Predictions vs Actual Values for hybrid POLY with KNN'), 
plt.plot(y_test, color='red', label='actual')
plt.plot(y_predict_sorted, color='blue', label='predicted')
plt.xlabel('Sample Index')
plt.ylabel('Bias')
plt.legend()
plt.show()
