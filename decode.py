from scipy import io
import numpy as np
from sklearn.model_selection import train_test_split
import matplotlib.pyplot as plt
from sklearn import svm
from sklearn.metrics import accuracy_score
from sklearn.svm import SVC

C = io.loadmat()
clf = svm.SVC()
data =[]
for i1 in range(4):
        data.append(C['master'][0][i1])

numSum = 0;
for i1 in range(4):
    numSum = numSum + data[i1].shape[2]

X = np.full((numSum,32),0.0) 
Y = []

accuracy = np.full((100,1),0.0)
result = np.full((60,60),0.0);

# X = EEG data Y = label(1: obj. 2: face)



for tstep1 in np.arange(0,600,10):
    
    print(tstep1)
    X1 = np.full((numSum,32),0.0) 
    Y1 = []
    
    
    cnt = 0
    for i1 in range(4):
        for i2 in range(data[i1].shape[2]):
            X1[cnt,:] = data[i1][:, tstep1 , i2]  
            
            if i1 < 2:
                Y1.append(1) #object
            else:
                Y1.append(2) #face

            cnt = cnt + 1
    
    
    for tstep2 in np.arange(0,600,10):
        
        X2 = np.full((numSum,32),0.0) 
        Y2 = []
        
        cnt = 0
        for i1 in range(4):
            for i2 in range(data[i1].shape[2]):
                X2[cnt,:] = data[i1][:, tstep2 , i2]  

                if i1 < 2:
                    Y2.append(1) #object
                else:
                    Y2.append(2) #face

                cnt = cnt + 1
            
        
        
        idx1 = int(tstep1/10)
        idx2 = int(tstep2/10)
        
        if tstep1 == tstep2:
            
            tmp = np.full((100,1),0.0);
            
            for i1 in range(100):
                X_train, X_test, y_train, y_test = train_test_split(X1, Y1, test_size=0.33, random_state=0)
                clf.fit(X_train, y_train)
                tmp[i1,0] = clf.score(X_test, y_test)
                result[idx1,idx2] = np.mean(tmp,axis = 0) ##subsampling 한 부분에 대해서만 accuracy를 도출
            
        else:
            clf.fit(X1, Y1)
            predictCompleted = clf.predict(X2)
            outcome = accuracy_score(Y2, predictCompleted)

            result[idx1,idx2] = outcome
