import numpy as np
import pandas as pd
import torch
import torch.nn as nn
import matplotlib.pyplot as plt

# load data
base_path = r'your own path'
data_o=np.loadtxt(base_path)
data=data_o[181:3540,1]
time=data_o[181:3540,0]
L_all=len(data)

y = torch.tensor(data, dtype=torch.float32)
x = torch.tensor(time, dtype=torch.float32)

test_size = 168
train_set = y[:-test_size]
test_set = y[-test_size:]

# normalizing
from sklearn.preprocessing import MinMaxScaler

# instantiate a scaler
scaler = MinMaxScaler(feature_range=(-1, 1))

# normalize the training set
train_norm = scaler.fit_transform(train_set.reshape(-1, 1))

# data preparation 
train_norm = torch.FloatTensor(train_norm).view(-1)

def input_data(seq,ws):
    out = []
    L = len(seq)
    
    for i in range(L-ws):
        window = seq[i:i+ws]
        label = seq[i+ws:i+ws+1]
        out.append((window,label))
    
    return out

window_size = 1
train_data = input_data(train_norm, window_size)
len(train_data)

# create LSTM model
class LSTMnetwork(nn.Module):
    
    def __init__(self,input_size = 1, hidden_size = 256, out_size = 1):
        super().__init__()
        self.hidden_size = hidden_size
        self.lstm = nn.LSTM(input_size, hidden_size)
        self.linear = nn.Linear(hidden_size,out_size)
        self.hidden = (torch.zeros(1,1,hidden_size),torch.zeros(1,1,hidden_size))
    
    def forward(self,seq):
        lstm_out, self.hidden = self.lstm(seq.view(len(seq),1,-1), self.hidden)
        pred = self.linear(lstm_out.view(len(seq),-1))
        return pred[-1]


torch.manual_seed(1)
model = LSTMnetwork()
criterion = nn.MSELoss()
optimizer = torch.optim.Adam(model.parameters(), lr=0.01)

# Model training
epochs = 200
future = test_size

# Convert train_data to TensorDataset
from torch.utils.data import TensorDataset, DataLoader
train_data = TensorDataset(torch.FloatTensor(train_norm[:-window_size]), torch.FloatTensor(train_norm[window_size:]))
# Create DataLoader
batch_size = 128
train_loader = DataLoader(train_data, shuffle=False, batch_size=batch_size)

for i in range(epochs):
    
    for seq, y_train in train_loader:
        optimizer.zero_grad()
        model.hidden = (torch.zeros(1,1,model.hidden_size),
                       torch.zeros(1,1,model.hidden_size))
        
        y_pred = model(seq.view(-1, window_size, 1))
        loss = criterion(y_pred, y_train.view(-1))
        loss.backward()
        optimizer.step()
        
    print(f"Epoch {i} Loss: {loss.item()}")
    
    preds = train_norm[-window_size:].tolist()
    model.eval()
for f in range(future):
    seq = torch.FloatTensor(preds[-window_size:])
    with torch.no_grad():
         model.hidden = (torch.zeros(1,1,model.hidden_size),
                         torch.zeros(1,1,model.hidden_size))

         preds.append(model(seq).item())
preds[window_size:]   
loss = criterion(torch.tensor(preds[-window_size:]), y[L_all-window_size:])
true_predictions = scaler.inverse_transform(np.array(preds[window_size:]).reshape(-1, 1))
true_predictions # predicted flow rate
print(f"Performance on test range: {loss}")

# Visualization    
plt.figure(figsize=(12,4))
plt.grid(True)
plt.plot(y.numpy(),color='#8000ff')
plt.plot(range(L_all-test_size,L_all),true_predictions,color='#ff8000')
plt.show()
