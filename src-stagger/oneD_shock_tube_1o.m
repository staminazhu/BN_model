clear;
clc;
%1D shock_tube by HLLC Schemes for BN model
%state constant
global gama_s gama_g p0;
gama_s=1.4;
gama_g=1.4;
p0=0;
global ep;
ep=1e-9;
x_min=0;
x_max=1;
N=300*1;
d_x=(x_max-x_min)/N;
x0=0.5;
CFL=0.4;
%state value
Time=0;
Tend=0.1;
%Tend=0.15;
Alpha=zeros(1,N+1);
U=zeros(6,N);
F=zeros(6,N+1);
%initial condition
% lo_gL_0  =1;
% u_gL_0   =2;
% p_gL_0   =1;
% lo_sL_0  =2;
% u_sL_0   =0.3;
% p_sL_0   =5;
% phi_sL_0 =0.8;
% lo_gR_0  =0.1941934235006083;
% u_gR_0   =2.801188129642115;
% p_gR_0   =0.1008157360849781;
% lo_sR_0  =2;
% u_sR_0   =0.3;
% p_sR_0   =12.85675006887399;
% phi_sR_0 =0.3;
load ../test/test_new1_pi.mat;
phi_gL_0=1.0-phi_sL_0;
phi_gR_0=1.0-phi_gR_0;
E_gL_0=p_gL_0/(gama_g-1)+0.5*lo_gL_0*u_gL_0^2;
E_sL_0=(p_sL_0+gama_s*p0)/(gama_s-1)+0.5*lo_sL_0*u_sL_0^2;
U_L_0=[phi_gL_0*lo_gL_0;phi_gL_0*lo_gL_0*u_gL_0;phi_gL_0*E_gL_0;phi_sL_0*lo_sL_0;phi_sL_0*lo_sL_0*u_sL_0;phi_sL_0*E_sL_0];
E_gR_0=p_gR_0/(gama_g-1)+0.5*lo_gR_0*u_gR_0^2;
E_sR_0=(p_sR_0+gama_s*p0)/(gama_s-1)+0.5*lo_sR_0*u_sR_0^2;
U_R_0=[phi_gR_0*lo_gR_0;phi_gR_0*lo_gR_0*u_gR_0;phi_gR_0*E_gR_0;phi_sR_0*lo_sR_0;phi_sR_0*lo_sR_0*u_sR_0;phi_sR_0*E_sR_0];
%test begin
for i=1:N
    x(i)=x_min+(i-0.5)*d_x;
    if i<round(N*x0/(x_max-x_min))
        U(:,i) =U_L_0;
        Alpha(i) =phi_sL_0;
    elseif i>round(N*x0/(x_max-x_min))
        U(:,i) =U_R_0;
        Alpha(i+1) =phi_sR_0;
    else
        U(:,i) =0.5*(U_L_0+U_R_0);
        Alpha(i)   =phi_sL_0;
        Alpha(i+1) =phi_sR_0;
    end
end
%Godunov's Method
while Time<Tend && isreal(Time)
    %CFL condition
    for i=1:N
        [lo_gL(i),u_gL(i),p_gL(i),lo_sL(i),u_sL(i),p_sL(i),lo_gR(i),u_gR(i),p_gR(i),lo_sR(i),u_sR(i),p_sR(i)]=primitive_comp(U(:,i),Alpha(i),Alpha(i+1));
        a_gL(i)=sqrt(gama_g*p_gL(i)/lo_gL(i));
        a_sL(i)=sqrt(gama_s*(p_sL(i)+p0)/lo_sL(i));
        a_gR(i)=sqrt(gama_g*p_gR(i)/lo_gR(i));
        a_sR(i)=sqrt(gama_s*(p_sR(i)+p0)/lo_sR(i));
        V_S(i)=0.5*(u_sL(i)+u_sR(i));
    end
    Smax=max([max(abs(u_gL)+a_gL),max(abs(u_sL)+a_sL),max(abs(u_gR)+a_gR),max(abs(u_sR)+a_sR)]);
    d_t=CFL*d_x/Smax;
    if Time+d_t >= Tend
        d_t = Tend-Time+1e-10;
    end
    %Riemann problem:compute flux
    for i=1:N+1
        %flux on the boundary of i-1 and i
        if i==1
            F(1:3,1)=Riemann_solver_Exact(lo_gL(1),lo_gL(1),p_gL(1),p_gL(1),u_gL(1),u_gL(1),1-Alpha(1),V_S(1));
            F(4:6,1)=Riemann_solver_Exact(lo_sL(1),lo_sL(1),p_sL(1),p_sL(1),u_sL(1),u_sL(1),Alpha(1),V_S(1));
        elseif i==N+1
            F(1:3,N+1)=Riemann_solver_Exact(lo_gL(N),lo_gL(N),p_gL(N),p_gL(N),u_gL(N),u_gL(N),1-Alpha(N+1),V_S(N));
            F(4:6,N+1)=Riemann_solver_Exact(lo_sL(N),lo_sL(N),p_sL(N),p_sL(N),u_sL(N),u_sL(N),Alpha(N+1),V_S(N));
        else
            F(1:3,i)=Riemann_solver_Exact(lo_gL(i-1),lo_gL(i),p_gL(i-1),p_gL(i),u_gL(i-1),u_gL(i),1-Alpha(i),0.5*(V_S(i-1)+V_S(i)));
            F(4:6,i)=Riemann_solver_Exact(lo_sL(i-1),lo_sL(i),p_sL(i-1),p_sL(i),u_sL(i-1),u_sL(i),Alpha(i),0.5*(V_S(i-1)+V_S(i)));
        end
    end
    %compute U in next step
    for i=1:N
      if abs(Alpha(i+1)-Alpha(i))<ep
          S=0.5*(p_gL(i)+p_gR(i))*(Alpha(i+1)-Alpha(i));
      else
          S_tmp=Alpha(i+1)*p_sR(i)-Alpha(i)*p_sL(i);
          if (S_tmp/(Alpha(i+1)-Alpha(i))>max(p_gL(i),p_gR(i)))
              S=max(p_gL(i),p_gR(i))*(Alpha(i+1)-Alpha(i));
          elseif (S_tmp/(Alpha(i+1)-Alpha(i))<min(p_gL(i),p_gR(i)))
              S=min(p_gL(i),p_gR(i))*(Alpha(i+1)-Alpha(i));
          else
              S=S_tmp;
          end
      end
        U(1:6,i)=U(1:6,i)+d_t/d_x*(FR(1:6,i)-FL(1:6,i+1))+d_t/d_x*[0;S;S*V_S(i);0;-S;-S*V_S(i)];
    end
    Time=Time+d_t
% if Time > d_t
%    break;
% end
end
lo_g = 0.5*(lo_gL+lo_gR);
p_g  = 0.5*(p_gL +p_gR);
u_g  = 0.5*(u_gL +u_gR);
lo_s = 0.5*(lo_sL+lo_sR);
p_s  = 0.5*(p_sL +p_sR);
u_s  = 0.5*(u_sL +u_sR);
phi_s= Alpha(1,1:N);
W_exact = zeros(N,8);
W_exact(:,2)=phi_s';
W_exact(:,3)=lo_s';
W_exact(:,4)=u_s';
W_exact(:,5)=p_s';
W_exact(:,6)=lo_g';
W_exact(:,7)=u_g';
W_exact(:,8)=p_g';
load ../test/test_new1_pi.exact;
for i=1:N
     W_exact(i,:) = test_new1_pi(ceil(i/(N/300)),:);
end
%plot
col = ':.m';
figure(1);
subplot(2,2,1);
hold on
plot(x_min:d_x:x_max-d_x,W_exact(:,3),'k','LineWidth',1.0);
plot(x_min:d_x:x_max-d_x,lo_s,col,'LineWidth',1.0);
xlabel('Position','FontWeight','bold');
ylabel('Density-solid','FontWeight','bold');
ylim([min(lo_s)-0.00001 max(lo_s)+0.00001])
subplot(2,2,2);
hold on
plot(x_min:d_x:x_max-d_x,W_exact(:,4),'k','LineWidth',1.0);
plot(x_min:d_x:x_max-d_x,u_s,col,'LineWidth',1.0);
xlabel('Position','FontWeight','bold');
ylabel('Velocity-solid','FontWeight','bold');
ylim([min(u_s)-0.00001 max(u_s)+0.00001])
subplot(2,2,3);
hold on
plot(x_min:d_x:x_max-d_x,W_exact(:,5),'k','LineWidth',1.0);
plot(x_min:d_x:x_max-d_x,p_s,col,'LineWidth',1.0);
xlabel('Position','FontWeight','bold');
ylabel('Pressure-solid','FontWeight','bold');
subplot(2,2,4);
hold on
plot(x_min:d_x:x_max-d_x,W_exact(:,2),'k','LineWidth',1.0);
plot(x_min:d_x:x_max-d_x,phi_s,col,'LineWidth',1.0);
xlabel('Position','FontWeight','bold');
ylabel('Porosity-solid','FontWeight','bold');
figure(2);
subplot(2,2,1);
hold on
plot(x_min:d_x:x_max-d_x,W_exact(:,6),'k','LineWidth',1.0);
plot(x_min:d_x:x_max-d_x,lo_g,col,'LineWidth',1.0);
xlabel('Position','FontWeight','bold');
ylabel('Density-gas','FontWeight','bold');
subplot(2,2,2);
hold on
plot(x_min:d_x:x_max-d_x,W_exact(:,7),'k','LineWidth',1.0);
plot(x_min:d_x:x_max-d_x,u_g,col,'LineWidth',1.0);
xlabel('Position','FontWeight','bold');
ylabel('Velocity-gas','FontWeight','bold');
subplot(2,2,3);
hold on
plot(x_min:d_x:x_max-d_x,W_exact(:,8),'k','LineWidth',1.0);
plot(x_min:d_x:x_max-d_x,p_g,col,'LineWidth',1.0);
xlabel('Position','FontWeight','bold');
ylabel('Pressure-gas','FontWeight','bold');
subplot(2,2,4);
hold on
plot(x_min:d_x:x_max-d_x,W_exact(:,8)./W_exact(:,6).^gama_g,'k','LineWidth',1.0);
plot(x_min:d_x:x_max-d_x,p_g./lo_g.^gama_g,col,'LineWidth',1.0);
xlabel('Position','FontWeight','bold');
ylabel('Entropy-gas','FontWeight','bold');
figure(3)
subplot(3,1,1);
hold on
plot(x_min:d_x:x_max-d_x,(1-W_exact(:,2)).*W_exact(:,6).*(W_exact(:,7)-W_exact(:,4)),'k','LineWidth',1.0);
plot(x_min:d_x:x_max-d_x,phi_g.*lo_g.*(u_g-u_s),col,'LineWidth',1.0);
xlabel('Position','FontWeight','bold');
ylabel('Riemann_inv-Q','FontWeight','bold');
ylim([min(phi_g.*lo_g.*(u_g-u_s))-0.00001 max(phi_g.*lo_g.*(u_g-u_s))+0.00001])
subplot(3,1,2);
hold on
plot(x_min:d_x:x_max-d_x,(1-W_exact(:,2)).*W_exact(:,6).*(W_exact(:,7)-W_exact(:,4)).^2+(1-W_exact(:,2)).*W_exact(:,8)+W_exact(:,2).*W_exact(:,5),'k','LineWidth',1.0);
plot(x_min:d_x:x_max-d_x,phi_g.*lo_g.*(u_g-u_s).^2+phi_g.*p_g+phi_s.*p_s,col,'LineWidth',1.0);
xlabel('Position','FontWeight','bold');
ylabel('Riemann_inv-P','FontWeight','bold');
ylim([min(phi_g.*lo_g.*(u_g-u_s).^2+phi_g.*p_g+phi_s.*p_s)-0.00001 max(phi_g.*lo_g.*(u_g-u_s).^2+phi_g.*p_g+phi_s.*p_s)+0.00001])
subplot(3,1,3);
hold on
plot(x_min:d_x:x_max-d_x,0.5*(W_exact(:,7)-W_exact(:,4)).^2+gama_g/(gama_g-1)*W_exact(:,8)./W_exact(:,6),'k','LineWidth',1.0);
plot(x_min:d_x:x_max-d_x,0.5*(u_g-u_s).^2+gama_g/(gama_g-1)*p_g./lo_g,col,'LineWidth',1.0);
xlabel('Position','FontWeight','bold');
ylabel('Riemann_inv-H','FontWeight','bold');