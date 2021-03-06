%% Here, we encode our constarints in the optimization problem, namel

Gnom  = G*inv(eye(n)-Knom*G);

Gi    = (s*eye(N)-AiQ)\BiQ;


I     = eye(n);

% Defines CQ and DQ both as symbolic variables and sdpvar variables
CQs   = sym('CQ',[m n*N]); %symbolic
DQs   = sym('DQ',[m n]);
CQv   = sdpvar(m,n*N);     %variable      
DQv   = sdpvar(m,n);

%Write the finite-dimensional approximation of the Youla parameter as per
%(16) of [0]
for i = 1:n
        for j = 1:m
                Qs(i,j) = CQs(i,(j-1)*N+1:j*N)*Gi + DQs(i,j);
        end
end

Constraints = [];

%% Constraint Type 1: YQ(s) \in Sparse(T) in terms of CQv and DQv 


fprintf('Step 1: Encoding the constraint YQ(s) in Sparse(T)...\n')

YQs=(Knom+inv(eye(5)-Knom*G)*Qs)*inv(eye(5)-G*Knom); %%See proof of Theorem 17 of [1] for the expression for YQ in terms of Q
for i = 1:n
        for j = 1:n
                fprintf('   Percentage %6.4f \n', (n*(i-1)+j)/n/n );
                if Tbin(i,j) == 0     
                        [num,~] = numden(YQs(i,j));
                        cc      = coeffs(num,s);                                  % All elements of this vector must be 0....
                        [A_eq,b_eq]    = equationsToMatrix(cc,[vec(CQs);vec(DQs)]);      % Express system of equations in matrix form in terms of the vectorized versions of CQs and DQs
                        
                        A_eqs   = double(A_eq);    %A_eqs is the same as A_eq, for computation with sdpvars
                        b_eqs=double(b_eq);
                        
                        Constraints = [Constraints, A_eqs*[vec(CQv);vec(DQv)] == b_eqs]; % Add the constraints in terms of the sdpvars CQv and DQv, by using A_eqs computed with symbolics
                end
        end
end


%% Constraint Type 2: XQ \in Sparse(R) in terms of CQv and DQv
fprintf('Step 2: Encoding the constraint I+GY(s) in R ...\n')
XQs=eye(5)+G*YQs;    %exploits (8) of [10]
if QI == 0        %This cycle is useless if QI (redundant constraints). Hence, we skip it in this case.
        for i = 1:m
                for j = 1:n
                        fprintf('   Percentage %6.4f \n', (n*(i-1)+j)/n/n );
                        if Rbin(i,j) == 0     
                                [num,~] = numden(XQs(i,j));
                                cc      = coeffs(num,s);                                  % All elements of this vector must be 0....
                                [A_eq,b_eq]    = equationsToMatrix(cc,[vec(CQs);vec(DQs)]);      % Express system of equations in matrix form in terms of the vectorized versions of CQs and DQs
                                
                                A_eqs   = double(A_eq);    %A_eqs is the same as A_eq, for computation with sdpvars
                                b_eqs=double(b_eq);
                                
                                Constraints = [Constraints, A_eqs*[vec(CQv);vec(DQv)] == b_eqs];
                        end
                end
        end
end
fprintf('Encoding the constraint GY(s) in R ...Done\n')