
%% Example 1: mesh network
%clc;
clear;close all

%Nn = [2,4,6,8,10];

Nn=[4];
L=15; %number of agents with full information
%Nn = 4;

Num = length(Nn);
J   = zeros(Num,6);

for Index = 1:Num

    n         = Nn(Index);
    [Gp,Dist] = MeshGraph(n);  %% Plant Graph 
    %Gp        = Gc;
    [Gc,Dist] = MeshGraphLeaders(n,L)%bin(RandomInfoStructure(n));

%% Dynamics
% Dynamic matrices
    A  = cell(n^2,n^2);   % matrices for A
    B1 = cell(n^2,1);    % matrices for B

    % Dynamical part
    for i = 1:n^2
        B1{i} = [0;1];
        A{i,i} = [1 1; 1 2];
        for j = i+1:n^2
            if Gp(i,j) == 1
                A{i,j} = exp(-norm(Dist(i,:)-Dist(j,:)))*eye(2);
                A{j,i} = exp(-norm(Dist(i,:)-Dist(j,:)))*eye(2);
            end
        end
    end
    B2 = B1;

    [As, B1s, B2s] = NetStateModel(A,B1,B2,Gp);
    SP = bin(kron(Gc+eye(n^2),ones(1,2)));  %% sparsity patten +eye(n^2)

%% Performance
Q  = eye(2*n^2); R = eye(1*n^2);

% Q1 = eye(2); Q2 = eye(2); R1 = eye(1);
% Q  = kron(eye(n^2),Q1)+kron(diag(sum(Gc,2)),Q2)-kron(Gc,Q2);    
% R  = kron(eye(n^2),R1);     %% Performance Index

%% Structured Stablization P1
Ks = StruStaP1(A,B1,B2,Gp,Gc);    % controller                   
Js = sqrt(trace(lyap((As - B2s*Ks)',Q + Ks'*R*Ks)*(B1s*B1s'))); % H2 performance


%% Structured Optimal control P2: LMI
[Ko1,Jo1,Jdiag] = StrucH2LMI(A,B1,B2,Gp,Gc,Q,R,SP);
[Ko1new,Jo1new,Jdiagnew] = StrucH2LMI_new(A,B1,B2,Gp,Gc,Q,R,SP);
%[Ko1newGamma,Jo1newGamma,JdiagnewGamma] = StrucH2LMI_newGamma(A,B1,B2,Gp,Gc,Q,R,SP);

%% Structured Optimal control P2: gradient projection
[Ko2,Jo2,Iter] = StrucH2_Gradient(A,B1,B2,Gp,Gc,Q,R);

%% Augmented Lagragian Method by Lin et al
%[Jaugl,Kaugl] = SH2_AugLag(As,B1s,B2s,Q,R,SP);
%Jo3 = sqrt(Jaugl);

%% LQR
Kc = lqr(As,B2s,Q,R);
Jc = sqrt(trace(lyap((As - B2s*Kc)',Q + Kc'*R*Kc)*(B1s*B1s')));


%% decentralized control
Kd = DeceContr(A,B1,B2,Gp,1);
Jd = sqrt(trace(lyap((As - B2s*Kd)',Q + Kd'*R*Kd)*(B1s*B1s'))); % H2 performance



J(Index,:) = [Js,Jo1,Jo1new,Jo2,Jc,Jd];

end





