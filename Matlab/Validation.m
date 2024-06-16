%% load profile of heat pump with predicted flow rate
clc;close;clear;
load hpdata.mat
load flowrate.mat % pred_all(:,1)
load mdot.mat % mdot_h [kg/s]
load U.mat

% 2021-01-04 Monday --- 2021-02-07 Sunday
T_s = table2array(hpdata(181:3540,20)); % supply temp in Jan. 2021
T_r = table2array(hpdata(181:3540,21)); % return temp
P_Q = table2array(hpdata(181:3540,24)); % thermal power
P_el = table2array(hpdata(181:3540,25)); % electrical power / ground truth
T_in = table2array(hpdata(181:3540,13)); % inlet temp brine
T_out = table2array(hpdata(181:3540,12)); % outlet temp brine
COP_meas = table2array(hpdata(181:3540,22));
COP_mean = mean(COP_meas);


% Properties
C_w = 4186; % J/(kg*°C)
C_b = 3940; % J/(kg*°C)
rho_w = 0.988; % kg/L
deltat = 0.25; % 15min/0.25h

% Properties storage
Vs_l = 500;  % large storage [L]
Vs_s = 360;  % small storage [L]
T25_s = table2array(hpdata(181:3540,3)); % temp small storage 25cm
T50_s = table2array(hpdata(181:3540,4)); % temp small storage 50cm
T100_s = table2array(hpdata(181:3540,5)); % temp small storage 100cm
Tu_l = table2array(hpdata(181:3540,6)); % temp large storage bottom
T25_l = table2array(hpdata(181:3540,7)); % 25cm
T50_l = table2array(hpdata(181:3540,8)); % 50cm
To_l = table2array(hpdata(181:3540,9)); % temp large storage top
T_means = (T25_s+T50_s+T100_s)./3;
T_meanl = (Tu_l+T25_l+T50_l+To_l)./4;

% average in hour
j = 1;
T_s_h = nan(840,1);T_r_h = nan(840,1);
P_Q_h = nan(840,1);P_el_h = nan(840,1);
T_means_h = nan(840,1);T_meanl_h = nan(840,1);
T_in_h = nan(840,1);T_out_h = nan(840,1);COP_meas_h = nan(840,1);
for i = 1:840
    P_Q_h(i) = sum(P_Q(j:j+3,1));P_el_h(i) = sum(P_el(j:j+3,1));
    T_means_h(i) = sum(T_means(j:j+3,1));T_meanl_h(i) = sum(T_meanl(j:j+3,1));
    T_in_h(i) = sum(T_in(j:j+3,1));T_out_h(i) = sum(T_out(j:j+3,1));
    T_s_h(i) = sum(T_s(j:j+3,1));T_r_h(i) = sum(T_r(j:j+3,1));
    COP_meas_h(i) = sum(COP_meas(j:j+3,1));
    j = j+4;
end
P_Q_h = P_Q_h ./ 4; P_el_h = P_el_h ./ 4;
T_means_h = T_means_h ./ 4;T_meanl_h = T_meanl_h ./ 4;
T_in_h = T_in_h./4;T_out_h = T_out_h./4;
T_s_h = T_s_h./4; T_r_h = T_r_h./4;
COP_meas_h = COP_meas_h./4;

% model classification
N = 168; % forecast horizon
P_forecast_a = zeros(N,1); % Model A
P_forecast_b = zeros(N,1); % Model B
P_forecast_c = zeros(N,1); % Model C
P_forecast_d = zeros(N,1); % Model D
P_forecast_e = zeros(N,1); % Model E

% Load profile of heat pump
for i = 1:N

    P_forecast_a(i) = (C_w*rho_w*pred_all(i,1)*(T_s_h(i+672)-T_r_h(i+672))-...
                      Vs_l*rho_w*C_w*(T_meanl_h(i+672)-T_meanl_h(i+672-1))/3600-...
                      Vs_s*rho_w*C_w*(T_means_h(i+672)-T_means_h(i+672-1))/3600-...
                      C_b*mdot_h(i)*(T_out_h(i+672)-T_in_h(i+672)));
        
    P_forecast_b(i) = (C_w*rho_w*pred_all(i,1)*(T_s_h(i+672)-T_r_h(i+672))-...
                      Vs_s*rho_w*C_w*(T_meanl_h(i+672)-T_meanl_h(i+672-1))/3600-...
                      C_b*mdot_h(i)*(T_out_h(i+672)-T_in_h(i+672)));

    P_forecast_c(i) = (C_w*rho_w*pred_all(i,1)*(T_s_h(i+672)-T_r_h(i+672))-...
                      Vs_s*rho_w*C_w*(T_means_h(i+672)-T_means_h(i+672-1))/3600-...
                      C_b*mdot_h(i)*(T_out_h(i+672)-T_in_h(i+672)));

    P_forecast_d(i) = (C_w*rho_w*pred_all(i,1)*(T_s_h(i+672)-T_r_h(i+672))-...
                      C_b*mdot_h(i)*(T_out_h(i+672)-T_in_h(i+672)));
  
    P_forecast_e(i) = (C_w*rho_w*pred_all(i,1)*(T_s_h(i+672)-T_r_h(i+672)))/COP_mean;

end
P_forecast_a = max(P_forecast_a,0);
P_forecast_b = max(P_forecast_b,0);
P_forecast_c = max(P_forecast_c,0);
P_forecast_d = max(P_forecast_d,0);
P_forecast_e = max(P_forecast_e,0);

% Visualization
t = tiledlayout(3,2);
t.Units = 'centimeters';
t.OuterPosition = [0.5 0.5 14 8];
xtime = 1:168;
nexttile;
hold on
plot(xtime,P_el_h(673:840,1),'Color','g',LineWidth=0.5);
plot(xtime,P_forecast_a(1:168),'Color','r','LineStyle','-.',LineWidth=0.5);
hold off
xlim([1 168])
xlabel('time [h]','FontName',"Times",'FontSize',10);
ylabel('P [W]','FontName',"Times",'FontSize',10);
title('168h Load Profile/Model A','FontName',"Times",'FontSize',10)
nexttile;
hold on
plot(xtime,P_el_h(673:840,1),'Color','g',LineWidth=0.5);
plot(xtime,P_forecast_b(1:168),'Color','r','LineStyle','-.',LineWidth=0.5);
hold off
xlim([1 168])
xlabel('time [h]','FontName',"Times",'FontSize',10);
ylabel('P [W]','FontName',"Times",'FontSize',10);
title('168h Load Profile/Model B','FontName',"Times",'FontSize',10)
nexttile;
hold on
plot(xtime,P_el_h(673:840,1),'Color','g',LineWidth=0.5);
plot(xtime,P_forecast_c(1:168),'Color','r','LineStyle','-.',LineWidth=0.5);
hold off
xlim([1 168])
xlabel('time [h]','FontName',"Times",'FontSize',10);
ylabel('P [W]','FontName',"Times",'FontSize',10);
title('168h Load Profile/Model C','FontName',"Times",'FontSize',10)
nexttile;
hold on
plot(xtime,P_el_h(673:840,1),'Color','g',LineWidth=0.5);
plot(xtime,P_forecast_d(1:168),'Color','r','LineStyle','-.',LineWidth=0.5);
hold off
xlim([1 168])
xlabel('time [h]','FontName',"Times",'FontSize',10);
ylabel('P [W]','FontName',"Times",'FontSize',10);
title('168h Load Profile/Model D','FontName',"Times",'FontSize',10)
nexttile;
hold on
plot(xtime,P_el_h(673:840,1),'Color','g',LineWidth=0.5);
plot(xtime,P_forecast_e(1:168),'Color','r','LineStyle','-.',LineWidth=0.5);
hold off
xlim([1 168])
xlabel('time [h]','FontName',"Times",'FontSize',10);
ylabel('P [W]','FontName',"Times",'FontSize',10);
title('168h Load Profile/Model E','FontName',"Times",'FontSize',10)

lgd = legend('Ground Truth','Model A/B/C/D/E');
lgd.Layout.Tile = 6;


exportgraphics(t,'load Simu.png','Resolution','400');
exportgraphics(t,'load Simu.eps');

% Evaluation
mess = [P_el_h(673:840,1) P_el_h(673:840,1) P_el_h(673:840,1) P_el_h(673:840,1) P_el_h(673:840,1)];
sim =  [P_forecast_a(1:168) P_forecast_b(1:168) P_forecast_c(1:168) P_forecast_d(1:168) P_forecast_e(1:168)];
mae_all = nan(1,5);
for i = 1:5
    mae_all(i) = mae(sim(:,i),mess(:,i));
end
nmae_all = (mae_all./(max(mess)-min(mess)))*100

% Utility curve
Num_P = [7;9;13;14;16];
Num_P_optimal = [7;13;16];
U_optimal = [73;90;94];
p = polyfit(Num_P_optimal,U_optimal,2);
Num_P_poly = linspace(7,16,100);
U_poly = polyval(p,Num_P_poly);
Ur = U(end:-1:1);
t2 = tiledlayout(1,1);
t2.Units = 'centimeters';
t2.OuterPosition = [0.5 0.5 14 6];
nexttile;
plot(Num_P,Ur,'-o','LineWidth',2);
hold on
plot(Num_P_poly,U_poly,'--','LineWidth',2);
hold off
ylim([70,100])
text(7, 75, 'Model E') 
text(8.5, 77, 'Model D') 
text(12.5, 80, 'Model C') 
text(13.5, 87, 'Model B') 
text(15.5, 95, 'Model A') 
title('Diminishing marginal utility curve: HP modeling with partial generated data','FontName',"Times",'FontSize',10)
xlabel('Complexity of models i.e. number of model parameters','FontName',"Times",'FontSize',10)
ylabel('Utiliy of models','FontName',"Times",'FontSize',10)
lgd = legend('relationship between utility and complexity', ...
    'approximated curve', ...
    'FontName',"Times",'FontSize',8);
lgd.Position = [0.17, 0.42, 0.45, 0.08];
exportgraphics(t2,'Utility.png','Resolution','400');
exportgraphics(t2,'Utility.eps');






















