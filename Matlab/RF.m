% RF for flow rate
clc;close;clear;
% Metadata input
load hpdata.mat % See Data Source
timeall = table2array(hpdata(181:3540,1)); % temporal features
time_day = day(timeall);
time_hour = hour(timeall);
T_s = table2array(hpdata(181:3540,20)); % supply temp in Jan. 2021
T_r = table2array(hpdata(181:3540,21)); % return temp
P_Q = table2array(hpdata(181:3540,24)); % thermal power

% Properties
C_w = 4186; % J/(kg*°C)
rho_w = 0.988; % kg/L
deltat = 0.25; % 15min/0.25h

% missing flow rate
Vdot_w_raw = nan(3360,1);
for i = 1:3360
Vdot_w_raw(i) = P_Q(i)/(C_w*rho_w*(T_s(i)-T_r(i)));
end

% average flow rate [L/s] each hour
% average P_Q [W] each hour
j = 1;
Vdot_w = nan(840,1);
P_Q_h = nan(840,1);
time_hour_h = nan(840,1);
for i = 1:840
    Vdot_w(i) = sum(Vdot_w_raw(j:j+3,1));
    P_Q_h(i) = sum(P_Q(j:j+3,1));
    time_hour_h(i) = time_hour(j);
    j = j+4;
end
Vdot_w = Vdot_w ./ 4;
P_Q_h = P_Q_h ./ 4;

% Normalization(zero mean and unit variance) preventing diverging
% mu_Vdot = mean(Vdot_w);sigma_Vdot = std(Vdot_w,0);
% Vdot_w = (Vdot_w-mu_Vdot)./sigma_Vdot;

% for reproducibility
rng(1);
t = templateTree('NumVariablesToSample','all',...
    'PredictorSelection','interaction-curvature','Surrogate','on',...
    'Reproducible',true);

% reconstruct time series data into supervised learning with different
% Input size = 5
ratio = 0.8;
trainsz = floor(840*ratio);
pred_horizon = 840-trainsz;
Features(:,1) = Vdot_w(1:trainsz-5,1);
Features(:,2) = Vdot_w(2:trainsz-4,1);
Features(:,3) = Vdot_w(3:trainsz-3,1);
Features(:,4) = Vdot_w(4:trainsz-2,1);
Features(:,5) = Vdot_w(5:trainsz-1,1);

% Features2(:,1) = P_Q_h(4:trainsz,1); % known Feature
Features2(:,1) = time_hour_h(6:trainsz,1);

X = [Features(:,1) Features(:,2) Features(:,3) Features(:,4) Features(:,5) Features2(:,1)];

Features(:,6) = Vdot_w(6:trainsz,1);

Mdl = fitrensemble(X,Features(:,6),'Method','Bag', ...
    'NumLearningCycles',500,'Learners',t);

pred_all = nan(pred_horizon,1);

% Open loop prediction as generation
for i = 1:pred_horizon 
    X_new = [Features(:,i+1) Features(:,i+2) Features(:,i+3) Features(:,i+4) Features(:,i+5) Features2(:,i)];
    predict_feature = predict(Mdl,X_new);
    Features(:,i+6) = Vdot_w(6+i:trainsz+i,1);
    Features2(:,i+1) = time_hour_h(6+i:trainsz+i,1);
    pred_all(i) = predict_feature(end,1);
end

% pred_all(:,1) = pred_all(:,1).*sigma_Vdot+mu_Vdot;
% Vdot_w(:,1) = Vdot_w(:,1).*sigma_Vdot+mu_Vdot;

t = tiledlayout(1,1,'Padding','tight');
t.Units = 'centimeters';
t.OuterPosition = [0.5 0.5 11.11 5.07];
nexttile;
xtimetrain = (1:trainsz)';
xtimetest = (trainsz+1:840)';
plot(xtimetrain,Vdot_w(1:trainsz),LineWidth=1);
hold on
plot(xtimetest,Vdot_w(trainsz+1:840),'Color','g',LineWidth=1);
plot(xtimetest,pred_all,'Color','r',LineWidth=1);
legend('Train data','Test data','Predicted','Location','southwest');
hold off
xlim([1 840])
xlabel('time [h]','FontName',"Times",'FontSize',10);
ylabel('Average flow rate [L/s]','FontName',"Times",'FontSize',10);
title('Generated with RF','FontName',"Times",'FontSize',10);
legend('Train data','Ground Truth','Generated','Location','southwest');

exportgraphics(t,'RF.png','Resolution','400');
exportgraphics(t,'RF.eps');

% evaluation
mess = Vdot_w(trainsz+1:840,1);
rmse_all = rmse(pred_all,mess);
nrmse_all = (rmse_all/(max(mess)-min(mess)))*100
mae_all = mae(pred_all,mess);
nmae_all = (mae_all/(max(mess)-min(mess)))*100



