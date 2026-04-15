
"""
#******This script to apply Hybrid linear regression with KNN on arduino dataset (hardware)****
"""

import pandas as pd
import seaborn as sns
#%matplotlib inline
import numpy as np
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, r2_score, mean_absolute_error


#******Data loading****
iris = pd.read_csv('HW_dataset.csv')
print(iris.shape)
print(iris.columns)
iris.head()
iris["bias"].value_counts()
x = iris.drop(['bias'], axis=1);
y = iris['bias'];
x, y = np.array(x), np.array(y)

#*****added for feature selection****
from sklearn.feature_selection import SelectKBest,f_regression
selection = SelectKBest(f_regression, k=4).fit(x,y)
x_new = selection.transform(x)

#******Applying Linear Regression*****
from sklearn.linear_model import LinearRegression
lin_reg = LinearRegression()
lin_reg.fit(x_new, y)

#******Applying K-Nearest Neighbors Regression*****
from sklearn.neighbors import KNeighborsRegressor
knn_reg = KNeighborsRegressor(n_neighbors=7)
knn_reg.fit(x_new, y)

#******Predicting Test set results and Calculating RMSE and R2-score*****
from sklearn.metrics import mean_squared_error, r2_score
x_train, x_test, y_train, y_test = train_test_split(x_new, y, shuffle=False, test_size=0.3)
y_predict_linreg = lin_reg.predict(x_test)
y_predict_knnreg = knn_reg.predict(x_test)
y_predict = (y_predict_linreg + y_predict_knnreg) / 2
rmse = np.sqrt(mean_squared_error(y_test, y_predict))
r2 = r2_score(y_test, y_predict)
print("RMSE value = ",rmse)
print("R2 score = ",r2)
mape = np.mean(np.abs((y_test - y_predict) / y_test)) * 100
print('MAPE:', mape)

#******Visualizing the results*****
y_predict_sorted = [x for _,x in sorted(zip(y_test,y_predict))]
y_test_sorted = np.sort(y_test)
np.savetxt("y_test.txt", np.array(y_test_sorted), fmt="%s")
np.savetxt("y_predict.txt", np.array(y_predict_sorted), fmt="%s")
plt.title(' Predictions vs Actual Values for hybrid Linear with KNN'), 
plt.plot(y_test_sorted, color='red', label='actual')
plt.plot(y_predict_sorted, color='blue', label='predicted')
plt.xlabel('Sample Index')
plt.ylabel('Bias')
plt.legend()
plt.show()
