% Modified PM for flow rate 
clc;close;clear;
% Metadata input
load hpdata.mat % See Data Source
% 2021-01-04 Monday --- 2021-02-07 Sunday
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
for i = 1:840
    Vdot_w(i) = sum(Vdot_w_raw(j:j+3,1));
    j = j+4;
end
Vdot_w = Vdot_w ./ 4;

t = tiledlayout(1,1,'Padding','tight');
t.Units = 'centimeters';
t.OuterPosition = [0.5 0.5 11.11 5.07];
nexttile;
xtimetrain = (1:672)';
xtimetest = (673:840)';
plot(xtimetrain,Vdot_w(1:672),LineWidth=1);
hold on
plot(xtimetest,Vdot_w(673:840),'Color','g',LineWidth=1);
% modified persistence model
plot(xtimetest,Vdot_w(505:672),'Color','r',LineWidth=1);
hold off
xlim([1 840])
xlabel('time [h]','FontName',"Times",'FontSize',10);
ylabel('Average flow rate [L/s]','FontName',"Times",'FontSize',10);
title('Generated with modified persistence model','FontName',"Times",'FontSize',10);
legend('Train data','Ground Truth','Generated','Location','southwest');

% exportgraphics(t,'Modified PM.png','Resolution','400');
% exportgraphics(t,'Modified PM.eps');

% evaluation
mess = Vdot_w(673:840,1);
pred_all = Vdot_w(505:672,1);
rmse_all = rmse(pred_all,mess);
nrmse_all = (rmse_all/(max(mess)-min(mess)))*100
mae_all = mae(pred_all,mess);
nmae_all = (mae_all/(max(mess)-min(mess)))*100
