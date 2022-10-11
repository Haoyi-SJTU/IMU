% 超核IMU matlab接收程序
clear;
clc;
close all;
format short;

% global CH_HDR_SIZE;
% global MAXRAWLEN;

CH_HDR_SIZE = 6;                    % 帧头大小
MAXRAWLEN = 512;                % 最大buff size

imu_tempate.id = 0;             % user defined ID
imu_tempate.acc = [0 0 0];      % 加速度
imu_tempate.gyr = [0 0 0];      %  陀螺仪角速度
imu_tempate.mag = [0 0 0];      % magnetic field
imu_tempate.eul = [0 0 0];      % 姿态欧拉角
imu_tempate.quat = [0 0 0 0];   % 姿态四元数
imu_tempate.pressure = 0;     	% 气压
imu_tempate.timestamp = 0;      % 时间戳

global raw;
raw.nbyte = 0;                            %   /* number of bytes in message buffer */
raw.len = 0;                                % /* message length (bytes) */
raw.imu= imu_tempate;             %   /* imu data list, if (HI226/HI229/CH100/CH110, use imu[0]) */
raw.buf = [0 0];

% 默认配置
DEFALUT_BAUD = 115200;
PORT = 'COM12';

% 串口选择
if length(serialportlist) >=1 %发现多个串口
    fprintf("可用串口:%s\n", serialportlist);
    fprintf("请选择串口，更改PORT变量\n");
end
if length(serialportlist) == 1 %只有一个串口
    PORT = serialportlist;
end
if isempty(serialportlist) == true %没有串口
    fprintf("无可用串口\n");
end
% fprintf('输入 clear s  或者 CTRL+C 可以终止串口传输\n');
x = input("按回车键续...\n");

time = [];
acc_x = [];
acc_y = [];
acc_z = [];
gyr_x = [];
gyr_y = [];
gyr_z = [];
mag_x = [];
mag_y = [];
mag_z = [];

i = 1;

% 打开串口
s = serialport(PORT, DEFALUT_BAUD); %创建串口
%configureCallback(s,"byte",100,@callbackFcn)  %串口事件回调设置

while i<=300  %  采样个数
    if  s.NumBytesAvailable > 0
        data = read(s, s.NumBytesAvailable,"uint8"); %读取还串口数据      
        for ii = 1: length(data)   
            [new_data_rdy]  =  ch_serial_input(data(ii));
            if new_data_rdy == 1
%                 fprintf("加速度:%.3f %.3f %.3f\n", raw.imu.acc);
                acc_x(i) = raw.imu.acc(1);
                acc_y(i) = raw.imu.acc(2);
                acc_z(i) = raw.imu.acc(3);
                gyr_x(i) = raw.imu.gyr(1);
                gyr_y(i) = raw.imu.gyr(2);
                gyr_z(i) = raw.imu.gyr(3);
                mag_x(i) = raw.imu.mag(1);
                mag_y(i) = raw.imu.mag(2);
                mag_z(i) = raw.imu.mag(3);
                fprintf("这是第 %.3f 次采样 \t",i);
                %fprintf("加速度:%.3f %.3f %.3f\n", acc_x(i),acc_y(i),acc_z(i));
                i = i+1;
%                 fprintf("角速度:%.3f %.3f %.3f\n",  raw.imu.gyr);
%                 fprintf("欧拉角: Roll:%.2f Pitch:%.2f Yaw:%.2f\n", raw.imu.eul(1), raw.imu.eul(2), raw.imu.eul(3));
                new_data_rdy = 0;
            end
        end
        pause(0.01);
    end
end

delta_time = 0.01;

static_x = mean(acc_x(1:180));
acc_x = acc_x-static_x;

static_y = mean(acc_y(1:180));
acc_y = acc_y-static_y;

static_z = mean(acc_z(1:180));
acc_z = acc_z-static_z;

length = length(acc_x);% 时间长度
time_in_s = delta_time : delta_time : (length*delta_time); % 时间序列

% 去除加速度序列的不连续线性趋势
bp = delta_time : 2 : (length*delta_time);
acc_x = detrend(acc_x,1,bp,'SamplePoints',time_in_s, 'Continuous',false);
acc_y = detrend(acc_y,1,bp,'SamplePoints',time_in_s, 'Continuous',false);
acc_z = detrend(acc_z,1,bp,'SamplePoints',time_in_s, 'Continuous',false);

% 积分求速度
vel_x = zeros(1, length);
for i = 2:length
    vel_x(i) = vel_x(i-1)+acc_x(i-1)*delta_time;
end
vel_y = zeros(1, length);
for i = 2:length
    vel_y(i) = vel_y(i-1)+acc_y(i-1)*delta_time;
end
vel_z = zeros(1, length);
for i = 2:length
    vel_z(i) = vel_z(i-1)+acc_z(i-1)*delta_time;
end

mov_x = zeros(1, length);
for i = 2:length
    mov_x(i) = mov_x(i-1)+vel_x(i-1)*delta_time;
end
mov_y = zeros(1, length);
for i = 2:length
    mov_y(i) = mov_y(i-1)+vel_y(i-1)*delta_time;
end
mov_z = zeros(1, length);
for i = 2:length
    mov_z(i) = mov_z(i-1)+vel_z(i-1)*delta_time;
end

xlim([0,delta_time*length+2])
subplot(3,1,1)
plot(time_in_s , acc_x, time_in_s , acc_y, time_in_s , acc_z)%
title('线性加速度曲线')
legend('x方向加速度','y方向加速度','z方向加速度')
xlabel('时间/s')
ylabel('加速度/m·s-2')

xlim([0,delta_time*length+2])
subplot(3,1,2)
plot(time_in_s , vel_x, time_in_s , vel_y, time_in_s , vel_z)% 
title('线性速度曲线')
legend('x方向速度','y方向速度','z方向速度')
xlabel('时间/s')
ylabel('速度/m·s-1')

xlim([0,delta_time*length+2])
subplot(3,1,3)
plot(time_in_s ,  mov_x, time_in_s ,  mov_y, time_in_s , mov_z)%,
title('线性位移曲线')
legend('x方向位移','y方向位移','z方向位移')
xlabel('时间/s')
ylabel('位移/m')

% 同步帧头， 1:同步  0：未同步
function ret = sync_ch(data)
global raw;
raw.buf(1) = raw.buf(2);
raw.buf(2) = data;
if (raw.buf(1) == 0x5A && raw.buf(2) == 0xA5);  ret = 1; else; ret = 0; end
end


function new_data_rdy = decode_ch()
global raw;
new_data_rdy = 0;

crc1 = raw.buf(5) + raw.buf(6)*256;
crc_text = raw.buf;
crc_text(5:6) = [];

%计算CRC 校验成功后调用解析数据函数
crc2 = crc16(double(crc_text));

if crc1 == crc2
    parse_data();
    new_data_rdy = 1;
else
    fprintf("CRC err\n");
end

end

function  [new_data_rdy] = ch_serial_input(data)

global raw;
global CH_HDR_SIZE;
global MAXRAWLEN;

new_data_rdy = 0;

if (raw.nbyte == 0)
    if(sync_ch(data) == 0);  return;      end
    
    raw.nbyte = 3;
    return;
end

raw.buf(raw.nbyte) = data;
raw.nbyte = raw.nbyte + 1;

if (raw.nbyte == CH_HDR_SIZE)
    raw.len = raw.buf(3) + raw.buf(4)*256;
    if(raw.len > (MAXRAWLEN - CH_HDR_SIZE));   fprintf("ch length error: len=%d\n",raw.len); raw.nbyte = 0;  return; end
end

if raw.nbyte < (raw.len + CH_HDR_SIZE+1);    return; end;
raw.nbyte  = 0;
new_data_rdy = decode_ch();

end

% 解析帧中数据域
function parse_data()
global raw;

data = raw.buf;
data(1:6) = [];
len = length(data); %数据域长度


offset = 1;
while offset < len
    byte = data(offset);
    switch byte
        case 0x90 % ID标签
            raw.imu.id = data(offset+1);
            offset = offset + 2;
        case 0xA0 %加速度
            tmp = typecast(uint8(data(offset+1:offset+6)), 'int16');
            raw.imu.acc = double(tmp) / 1000;
            offset = offset + 7;
        case 0xB0 %角速度
            tmp = typecast(uint8(data(offset+1:offset+6)), 'int16');
            raw.imu.gyr = double(tmp) / 10;
            offset = offset + 7;
        case 0xC0 %地磁
            tmp = typecast(uint8(data(offset+1:offset+6)), 'int16');
            raw.imu.mag = double(tmp) / 10;
            offset = offset + 7;
        case 0xD0 %欧拉角
            tmp = typecast(uint8(data(offset+1:offset+6)), 'int16');
            raw.imu.eul(1) = double(tmp(1)) / 100;
            raw.imu.eul(2) = double(tmp(2)) / 100;
            raw.imu.eul(3) = double(tmp(3)) / 10;
            offset = offset + 7;
        case 0xF0 % 气压
            offset = offset + 5;
        case 0x91 % 0x91数据包
            raw.imu.id = data(offset+1);
            raw.imu.acc = double(typecast(uint8(data(offset+12:offset+23)), 'single'));
            raw.imu.gyr = double(typecast(uint8(data(offset+24:offset+35)), 'single'));
            raw.imu.mag = double(typecast(uint8(data(offset+36:offset+47)), 'single'));
            raw.imu.eul = double(typecast(uint8(data(offset+48:offset+59)), 'single'));
            raw.imu.quat = double(typecast(uint8(data(offset+60:offset+75)), 'single'));
            offset = offset + 76;
        otherwise
            offset = offset + 1;
    end
end

end




% data = "5A A5 4C 00 6C 51 91 00 A0 3B 01 A8 02 97 BD BB 04 00 9C A0 65 3E A2 26 45 3F 5C E7 30 3F E2 D4 5A C2 E5 9D A0 C1 EB 23 EE C2 78 77 99 41 AB AA D1 C1 AB 2A 0A C2 8D E1 42 42 8F 1D A8 C1 1E 0C 36 C2 E6 E5 5A 3F C1 94 9E 3E B8 C0 9E BE BE DF 8D BE";
% data = sscanf(data,'%2x');
%
%
% for ii = 1: length(data)
%
%     [new_data_rdy]  =  ch_serial_input(data(ii));
%     if new_data_rdy == 1
%         fprintf("加速度:%.3f %.3f %.3f\n", raw.imu.acc);
%           fprintf("角速度:%.3f %.3f %.3f\n",  raw.imu.gyr);
%         fprintf("欧拉角: Roll:%.2f Pitch:%.2f Yaw:%.2f\n", raw.imu.eul(1), raw.imu.eul(2), raw.imu.eul(3));
%         new_data_rdy = 0;
%
%     end
% end

