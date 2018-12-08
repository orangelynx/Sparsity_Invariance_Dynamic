% Solve an optimal decentralized control problem using the sparsity invariance approch [0]
%
%         min <K> ||P11 + P12 * K(I - GK)^(-1) * P21||
%         s.t.      K \in S  
%
% where P11, P12, G, P21 are transfer functions (plant dynamics), and S is
% a given sparsity constraint. In [0], we propose to restrict the problem into
%
%         min <X,Y> ||P11 - P12*Y*P21||
%         s.t.      Y,X \in RH_infty
%                   X  = I - GY
%                   Y \in T, X \in R
%
% where RH_infty denotes real-rational proper stable transfer functions,
% T, R are sparsity constraints, coming from the sparsity invariance approach
%
% Authors: L. Furieri, Automatic Control Laboratory, ETH.
%          Y. Zheng, Department of Engineering Science, University of Oxford
%
% References
% [0] "Convex Restrictions in Distributed Control"
% [1] "A Characterization of Convex Problems in Decentralized Control",
% [2] "Q-Parametrization and an SDP for H ?-optimal Decentralized Control"
% [3] "An efficient solution to multi-objective control problems with LMI objectives"

clear all;

order =7;           % order of the controller
a = 2;     
ax=2;     
% defines the basis for RH_infinity as {1/(s+a)^i} for both Y(s) and X(s)

%% generate plant data
generate_plant_data;         % plant definition and relevant data
%load('plant_data.mat');

%% QI Sparsity Constraints defined in [1]
Sbin1 = [0 0 0 0 0;0 1 0 0 0;0 1 0 0 0;0 1 0 0 0;0 1 0 0 1];
Sbin2 = [0 0 0 0 0;0 1 0 0 0;0 1 0 0 0;0 1 0 0 0;1 1 0 0 1];
Sbin3 = [0 0 0 0 0;0 1 0 0 0;0 1 0 0 0;1 1 0 0 0;1 1 0 0 1];
Sbin4 = [0 0 0 0 0;0 1 0 0 0;0 1 0 0 0;1 1 0 0 0;1 1 1 0 1];
Sbin5 = [0 0 0 0 0;0 1 0 0 0;0 1 0 0 0;1 1 1 0 0;1 1 1 0 1];
Sbin6 = [1 0 0 0 0;1 1 0 0 0;1 1 1 0 0;1 1 1 1 0;1 1 1 1 1];
centralized = ones(m,n);

%% non-QI Sparsity Constraint we study
Sbin7 = [1 0 0 0 0;
    1 1 0 0 0;
    0 1 0 0 0;
    0 1 0 0 0;
    0 1 0 0 1];
Sbin = Sbin7;
QI   = test_QI(Sbin,Delta);        % variable QI used to avoid adding useless constraints later if QI=1 and reduce execution time

Tbin = Sbin;                       % Matrix "T"
Rbin = generate_SXlessS(Tbin);     % Matrix "R_MSI"
%Rbin=eye(n);

fprintf('==================================================\n')
fprintf('              Sparsity Invariance Approch         \n')
fprintf('==================================================\n')

%% Encode sparsity Y(s) \in Sparse(T) and G(s)Y(s) in Sparse(R)

sparsity_constraints;

%% H2 norm minimization, SDP formulation
fprintf('Step 4: Encoding the other LMI constraint ...')
Qstatic = [CQv DQv];
P       = sdpvar(size(A1_hat,1),size(A1_hat,1));
S       = sdpvar(size(A1_hat,2),size(B2_hat,1));
R       = sdpvar(size(A2_hat,1),size(A2_hat,1));
L       = sdpvar(size(C2_hat,1),size(C2_hat,1));
gamma   = sdpvar(1,1);

Constraints = [Constraints,trace(L)<=gamma, P>=0,R>=0];                                                                   % (27)-(28) in our paper, Section V
Constraints = [Constraints,
    [A1_hat*P+P*A1_hat' A1_hat*S-S*A2_hat+A_hat+B_hat*Qstatic*C_hat B1_hat+B_hat*Qstatic*F_hat-S*B2_hat;
    (A1_hat*S-S*A2_hat+A_hat+B_hat*Qstatic*C_hat)' R*A2_hat+A2_hat'*R R*B2_hat;
    (B1_hat+B_hat*Qstatic*F_hat-S*B2_hat)' B2_hat'*R -eye(size(B2_hat,2))] <= 0];                                         % (29)

Constraints = [Constraints,
    [P zeros(size(P,1),size(R,2)) P*C1_hat';zeros(size(R,1),size(P,2)) R (C2_hat+E_hat*Qstatic*C_hat+C1_hat*S)';
    C1_hat*P C2_hat+E_hat*Qstatic*C_hat+C1_hat*S L] >= 0,DQv == 0];                                                       % (30), DQ=0 to guarantee that \mathcal{D}=0.
fprintf('Done \n')

% options = sdpsettings('allownonconvex',0,'solver','mosek','verbose',1);
fprintf('Step 5: call SDP solver to obtain a solution ... \n')
fprintf('==================================================\n')

options = sdpsettings('allownonconvex',0,'solver','sedumi','verbose',1);
sol     = optimize(Constraints,gamma,options);

CQ   = value(CQv);  %rounding to avoid false non-zeros
DQ   = value(DQv);
CQ2   = value(CQv2);  %rounding to avoid false non-zeros
DQ2   = value(DQv2);

Vgamma = sqrt(value(gamma));  % value of the H2 norm!
fprintf('\n ***** H2 norm of the closed loop system is %6.4f ***** \n', Vgamma);

%% RECOVER Q(s) and K(s) to check sparsities
disp('We check the sparsity of the resulting controller by substituting a random value for "s" in K(s)')
Gi = (s*eye(size(AiQ,1))-AiQ)\BiQ;
Gix= (s*eye(size(AiQx,1))-AiQx)\BiQ;
for i = 1:m
    for j = 1:n
        Yreal(i,j) = CQ(i,(j-1)*order+1:j*order)*Gi + DQ(i,j);
    end
end
for i = 1:n
    for j = 1:n
        Xreal(i,j) = CQ2(i,(j-1)*order+1:j*order)*Gix + DQ2(i,j);
    end
end
K = -Yreal*inv(I-Gs*Yreal);


%stability checks

unstable=0;
disp('We check the stability of  Y*(s):')
for(i=1:m)
    for(j=1:n)
        fprintf('   Percentage %6.4f \n', 100*(n*(i-1)+j)/n/n )
        if(isstable(syms2tf(Yreal(i,j)))==0)
            unstable=1
        end
    end
end
if(unstable==1)
    disp('!!!The parameter Y is UNSTABLE!!!')
else
    disp('The parameter Y is stable. Success.')
end

unstable=0;
disp('We check the stability of  X*(s):')
for(i=1:n)
    for(j=1:n)
        fprintf('   Percentage %6.4f \n', 100*(n*(i-1)+j)/n/n )
        if(isstable(syms2tf(Xreal(i,j)))==0)
            unstable=1
        end
    end
end
if(unstable==1)
    disp('!!!The parameter X is UNSTABLE!!!')
else
    disp('The parameter X is stable. Success.')
end



unstable=0;
disp('We check the stability of the closed-loop system K(I-GK)^-1:')
Closed_Loop=K*inv(eye(n)-Gs*K);
for(i=1:m)
    for(j=1:n)
        fprintf('   Percentage %6.4f \n', 100*(n*(i-1)+j)/n/n )
        if(isstable(syms2tf(Closed_Loop(i,j)))==0)
            unstable=1
        end
    end
end
if(unstable==1)
    disp('!!!The closed-loop is UNSTABLE!!!')
else
    disp('The closed-loop is stable. Success.')
end


%Sparsity check
test_T_subs  = double(subs(Yreal,s,rand));
test_R_subs  = double(subs(Xreal,s,rand));
 test=double(subs(Xreal-I+Gs*Yreal,s,rand));
Ksubs   = double(subs(K,s,rand));            %just get rid of s to get the sparsity
disp('We desired the sparsity:')
Sbin
disp('We obtained the sparsity:')
Kbin    = bin(Ksubs)





