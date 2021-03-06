% Created 2010-May-05
% conjugate gradient method to solve for the newton direction for the
% augmented Lagrangian method
% inputs: problem data A,B2,C2,P,L, complementary structure identity ISc, 
% gradient and initial condition;
% output: newton direction ntF and the residue of CG method and the number
% of CG steps
% details about CG method can be found in Nocedal and Wright '99 page 111
% and also in the TAC paper

function [ntF,res,CGstep] = SH2_AugLag_newton_CG(A,B2,C2,F,P,L,R,gradF,ISc,Ft0,c)

% the closed-loop system

    Acl = A-B2*F*C2;
    
    Z = R*F*C2-B2'*P;

% size of the problem

    [m,p] = size(F);   
    n = m*p;
    
% norm of the gradient

    ngradF = norm(gradF,'fro');  

% first step     
% compute the Ltilda and Ptilda for computing the gradient (or residue)
% G = H + \nabla J

    Ft = Ft0;
    
    G = gradF;    
    Delta = -G;    
    
    Ltil = lyap(Acl,B2*Delta*C2*L+(B2*Delta*C2*L)');
    Ptil = lyap(Acl',Z'*Delta*C2+(Z'*Delta*C2)');
    Hcal = 2*( (R*Delta*C2 - B2'*Ptil)*L - Z*Ltil )*C2' + c*(Delta.*ISc);
    
% residue of the solution

    nG = norm(G,'fro');  
    best_nG = nG;
    best_Ft = Ft; 

% standard trick about matrix trace
% trace(A'*B) = sum(sum(A.*B)) for real A B 
% trace(A'*B) = sum(sum(conj(A).*B)) for complex A B 

% compute the inner product of Delta and caligraphic H at step k
% <Hcalk,Deltak>

den = sum(sum(Delta.*Hcal));

% the negative curvature test for the first step

if den <= 0
    
% if it is negative curvature, return negative gradient of J as the
% approximate Newton direction;

    disp('negative curvature')    
    ntF = -gradF;
    res = nG;
    CGstep=0;
    return
    
else
    
    for k = 1:n
        
        % compute alpha 
        
        alpha = - sum(sum(G.*Delta))/den;
        
        % update the approximate Newton direction Ftilde
        % and the gradient G of J
        
        Ftnew = Ft + alpha * Delta;
        
        Gnew = G + alpha * Hcal; 
        
        % norm of the gradient
        
        nGnew = norm(Gnew,'fro');       
        
        % Nocedal and Wright '99 p140
        % Nocedal and Wright '06 p168
        % the stopping criterion for the conjugate gradient method
        
        if nGnew <= min(0.5,sqrt(ngradF))*ngradF*0.1    
            ntF = Ftnew;
            res = nGnew;
            break
        end
        
        % choose the beta such that the direction Delta k are orthogonal
        % and the gradient G is orthogonal to Delta's
        
        beta = sum(sum(Hcal.*Gnew))/den;
        Deltanew = - Gnew + beta * Delta;

        % compute the caligraphic H
        
        Ltilnew = lyap(Acl,B2*Deltanew*C2*L+(B2*Deltanew*C2*L)');
        Ptilnew = lyap(Acl',Z'*Deltanew*C2+(Z'*Deltanew*C2)');
        Hcalnew = (2*((R*Deltanew*C2-B2'*Ptilnew)*L - Z*Ltilnew)*C2') + c*(Deltanew.*ISc);
        
        % compute the new inner product of caligraphic H and Delta
        
        den = sum(sum(Deltanew.*Hcalnew));
                
        if den <= 0
            disp('negative curvature')
            ntF = Ftnew;
            res = nGnew;
            break
        end
                
        % check if gradient and new gradient are orthogonal
        % also check if delta and caligraphic H are orthogonal
        
        if trace(G'*Gnew)>1.e-3 || trace(Delta'*Hcalnew)>1.e-3
            disp('check the conjugacy in CG method!')
            trace(G'*Gnew)
            trace(Delta'*Hcalnew)
        end
        
        % update the current step data
        
        Hcal = Hcalnew;
        Delta = Deltanew; 
        G = Gnew;
        Ft = Ftnew;

    end
end

if k==n
    res = best_nG;
    ntF = best_Ft;
end

CGstep = k;