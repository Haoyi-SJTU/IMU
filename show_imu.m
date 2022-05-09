% 由加速度数据绘制加速度、速度、位移图像
% 读入：csv格式的imu数据
% 输出：加速度、速度、位移图像
%特点：通过趋势项消除，减少了位移曲线上的累计误差


clc
clear all

M = readmatrix('5.csv');
delta_time = 0.016667; % delta t

% 加速度分量
acc_x = M(5:end,6)';
static_x = mean(acc_x(1:180));
acc_x = acc_x-static_x;

acc_y = M(5:end,7)';
static_y = mean(acc_y(1:180));
acc_y = acc_y-static_y;

acc_z = M(5:end,8)';
static_z = mean(acc_z(1:180));
acc_z = acc_z-static_z;

length = length(acc_x);% 时间长度
time_in_s = delta_time : delta_time : (length*delta_time); % 时间序列

% 去除加速度序列的不连续线性趋势
bp = delta_time : 2 : (length*delta_time);
acc_x = detrend(acc_x,1,bp,'SamplePoints',time_in_s, 'Continuous',false);

% 积分求速度
vel_x1 = zeros(1, length);
for i = 2:length
    vel_x1(i) = vel_x1(i-1)+acc_x(i-1)*delta_time;
end
vel_y1 = zeros(1, length);
for i = 2:length
    vel_y1(i) = vel_y1(i-1)+acc_y(i-1)*delta_time;
end
vel_z1 = zeros(1, length);
for i = 2:length
    vel_z1(i) = vel_z1(i-1)+acc_z(i-1)*delta_time;
end

mov_x1 = zeros(1, length);
for i = 2:length
    mov_x1(i) = mov_x1(i-1)+vel_x1(i-1)*delta_time;
end
mov_y1 = zeros(1, length);
for i = 2:length
    mov_y1(i) = mov_y1(i-1)+vel_y1(i-1)*delta_time;
end
mov_z1 = zeros(1, length);
for i = 2:length
    mov_z1(i) = mov_z1(i-1)+vel_z1(i-1)*delta_time;
end

xlim([0,91])
subplot(3,1,1)
plot(time_in_s , acc_x)%, time_in_s , acc_y1, time_in_s , acc_z1
title('线性加速度曲线')
% legend('x方向加速度','y方向加速度','z方向加速度')
xlabel('时间/s')
ylabel('加速度/m·s-2')

xlim([0,91])
subplot(3,1,2)
plot(time_in_s , vel_x1)% , time_in_s , vel_y1, time_in_s , vel_z1
title('线性速度曲线')
% legend('x方向速度','y方向速度','z方向速度')
xlabel('时间/s')
ylabel('速度/macc_x·s-1')

xlim([0,91])
subplot(3,1,3)
plot(time_in_s ,  mov_x1 )%, time_in_s ,  mov_y1, time_in_s , mov_z1
title('线性位移曲线')
% legend('x方向位移','y方向位移','z方向位移')
xlabel('时间/s')
ylabel('位移/m')

% 位移信号快速傅里叶变换
Y = fft(acc_x);
P2 = abs(Y/length);
P1 = P2(1:length/2+1);
P1(2:end-1) = 2*P1(2:end-1);

% FFT采样率
Fs = 200;

f = Fs*(0:(length/2))/length;
figure();
plot(f,P1) 
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')