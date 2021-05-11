function [ output_item, output_exp_reward,   output_gap, w, w_index, corr_flag, C_budget, gapbd ]...
    = corrup_coupling_PSS_icml_submit(  L, T, w_good, w_bad,   u,    lambda   )
% agent: PSS
% attack strategy:
%           corrup_bern_para=2*( w(1)-w(2) )/w(1),  
%           corruption budget = (1+lambda)*2*corrup_bern_para*T/( L*log(L)/log(2) ) 
%
%   
%
% Input:
%     L --- no. of items
%     T --- no. of time steps
%     w_good --- w of the best item
%     w_bad --- w of the worst item
%
%     u --- parameter of PSS algorithm
%
%     lambda ---  corrup budget = (1+lambda)*2*corrup_bern_para*T
%
% Output:
%     output_item --- item to output
%     output_exp_reward --- expected reward of output item
%     output_gap --- Delta_{1,\iout}
%
%     w --- vector of empirical mean w(i)'s
%     w_index --- loc of items
%     corr_flag --- 1:output=opt, 0:else
%     gapbd --- bound on Delta_{1,\iout} in Theorem
    

 

%% 1. initialize: generate w(i)'s 
w_med = w_good - (w_good-w_bad)/3;
w = w_bad*ones(1,L);
w(1) = w_good;
w(2) = w_med;
    
 
corrup_bern_para = 2*( w(1)-w(2) )/w(1);   


w_index = randperm(L);              % random order for items 2, ..., L
w = w(w_index);                     % rearrange w(i)'s 
index_opt = find( w == w_good );    % find the index of optimal item

%% 2. generate W_t(i)'s 
T_sample = min( T, 10^5 );
w_repeat = repmat(w,T_sample,1); % all w repeat
w_repeat = reshape(w_repeat,1,T_sample*L);
W_sample = binornd(1,w_repeat);
W_sample = reshape(W_sample,T_sample,L);
clear w_repeat 

corrup_sample =  binornd(1,corrup_bern_para, [T_sample,1] );

%% 3. main phase
%%% (I) for corruption
C_budget =(1+lambda)*2*corrup_bern_para*T/( L*log(L)/log(2) );
gapbd = C_budget*8*floor( log(L)/log(u) ) / T;

%%% (II) for PSS(u)
M = ceil( log(L) / log(u) );       % no. of phases
N = floor( T/M );                  % length of each phase
Act_set = w_index;                     % active set
Size_act_set = L;                  % size of active set / no. of active items
item_optimal_active = ismember( index_opt,Act_set ); % label whether the optimal item is still active

%%% (III) phases
for m = 1 : M
	% (1) get the subset of r.v.'s      
    T_range = mod( (m-1)*N : m*N-1,   T_sample) + 1;    % range of samples
    W_subset = W_sample( T_range,: );                   % subset of samples
    corruption_subset = corrup_sample( T_range );                   % subset of corruption rv during this phase
    
    % (2) N*1 vector: item to pull at each time step during this phase
    % time step
    n_m = floor(N / Size_act_set);
    item_pull = randi([1, Size_act_set ],1, N);    % random loc of the items to pull  
    
    % (3) label whether the optimal item is still active
    if item_optimal_active
        item_optimal_active = ismember( index_opt,Act_set );
    end
    
    % (2) If corruption budget NOT depleted and the optimal item is still active
    if (C_budget >= 1) && ( item_optimal_active  )
        % (2-1) time steps when optimal item is pulled 
%         index_opt_in_cur_act = find(  Act_set == index_opt);
        W_subset_item_opt = W_subset(:, index_opt );
        % (2-1) get the subset of corruptions when the optimal item is pulled
        C_subset = corruption_subset;            % corruption = 0 when G_t=0 (rv of corruption)
 
        
        C_subset = C_subset.*W_subset_item_opt; % corruption = 0 when W_t(optimal item)=0
        
        C_req_seq = cumsum( C_subset );   
        % (2-2) the first time step that can NOT be corrupted
        tmp = find( C_req_seq > C_budget );
        if isempty(tmp)
            C_budget = C_budget - C_req_seq(N);
        else
            C_subset( tmp : N) = 0;
            C_budget = 0;                                % corruption budget depleted
        end
        W_subset(:, index_opt ) = abs( W_subset_item_opt - C_subset );            % shift 1 to 0 for optimal item
    end
     
    
    % (3) shrink the active set
    % (3-1) only keep r.v.'s of active items
    W_subset = W_subset(:, Act_set ); 
    % (3-2) N*|A_{m-1}| matrix: 1 in each row represent the item to pull at that
    % time step
    item_pull = ind2vec( item_pull, Size_act_set );              % to vector
    item_pull = full( item_pull );                               % vector to matrix: |A_{m-1}|*N
    item_pull = item_pull';                                      % N*|A_{m-1}| matrix 
    % (3-3) find empirical mean 
    w_emp = W_subset .* item_pull;
    n_m = N / Size_act_set;
    w_emp = sum(w_emp) / n_m;
    % (3-4) shrink the set
    [ ~, emp_ord ] = sort( w_emp, 'descend' );
    Size_act_set = ceil( L / ( u^m ) );
    emp_ord = emp_ord( 1:Size_act_set );
    Act_set = Act_set( emp_ord );
end   



   
    
%% 4. output
output_item = Act_set;
output_exp_reward = w( output_item );
output_gap = w_good - output_exp_reward; 

corr_flag = ( w_index(output_item) == 1 );

end


