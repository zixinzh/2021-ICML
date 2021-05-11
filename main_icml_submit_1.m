clear
clc
close all

warning('off')


%% 1.initialize
no_seed = 100;
seed_range = 1:no_seed;

T1_range = 2;
T0 = 3;


L_range = 32;

w_good_range = [ 0.4 0.5 0.5 ];
w_bad_range =  [ 0.2 0.2 0.3 ];
num_w_set = length(  w_good_range );

lambda_range = [0.5 0.9];

algo_name = {'1_corrup_coupling_PSS', '2_corrup_coupling_SH', '3_corrup_coupling_UP', ...
    };
algo_no_range = 1:3;


timetable = zeros(1, no_seed);
output_exp_reward_all = zeros(1,no_seed);
output_gap_all = zeros(1,no_seed);
output_item_all = zeros(1,no_seed);
remain_C_budget_all = zeros(1,no_seed);
cur_gapbd = zeros(1,no_seed);
corr_flag_all = zeros(1,no_seed);

disp('ALG T L w_good w_bad u lambda mean_re_C_budget gapbd corr_no output_gap_mean output_gap_std output_exp_reward_mean output_exp_reward_std ave_time');



for algo_no = algo_no_range
    for w_ind = 1:num_w_set
        w_good = w_good_range(w_ind);
        w_bad = w_bad_range(w_ind);
        
        for T1_ind = 1:length(T1_range)
            T1 = T1_range(T1_ind);
            
            T = T1*10^T0;
            time_name = ['T=', num2str(T1), 'e', num2str(T0)];
            folder_name = [ time_name,  ' ', algo_name{algo_no} , num2str(no_seed) ];
            if exist([folder_name], 'dir')==0
                mkdir([folder_name ]);
            end
            if exist([folder_name,  '_', num2str(no_seed) ], 'dir')==0
                mkdir([folder_name, '_', num2str(no_seed) ]);
            end
            for L_ind = 1:length(L_range)
                L = L_range(L_ind);
                
                if algo_no == 1 % PSS(2)
                    u = 2;
                elseif algo_no == 2 % SH
                    u = 2;
                elseif algo_no == 3% UP
                    u = L;
                end
                
                for lambda_ind = 1:length(lambda_range)
                    lambda = lambda_range(lambda_ind);
                    simulation_name = [ 'L=', num2str(L), ...
                        ' w_good=', num2str(w_good), ' w_bad=', num2str(w_bad),...
                        ' u=', num2str(u),...
                        ' lambda=', num2str(lambda), ...
                        ];
                    for seed_index = 1:no_seed
                        seed_val = seed_range(seed_index);
                        rng(seed_val);
                        %% 2.run algorithm
                        tstart = tic;
                        if algo_no == 1
                            [ output_item, output_exp_reward,   output_gap, w, w_index, corr_flag, C_budget, gapbd ]...
                                = corrup_coupling_PSS_icml_submit(  L, T, w_good, w_bad,   u, lambda );
                        end
                        if algo_no == 2
                            [ output_item, output_exp_reward,   output_gap, w, w_index, corr_flag, C_budget, gapbd ]...
                                = corrup_coupling_SH_icml_submit(  L, T, w_good, w_bad,   u, lambda );
                        end
                        if algo_no == 3
                            [ output_item, output_exp_reward,   output_gap, w, w_index, corr_flag, C_budget, gapbd ]...
                                = corrup_coupling_UP_icml_submit(  L, T, w_good, w_bad,   u, lambda );
                        end
                        timetable_tmp = toc(tstart);
                        timetable(seed_index) = timetable_tmp;
                        
                        %% 3.seed save
                        parsave([ folder_name, '_', num2str(no_seed), '/seed=', num2str(seed_val), ' ', simulation_name, '.mat'],...
                            output_item, output_exp_reward,   output_gap, w, w_index, corr_flag, C_budget, gapbd );
                        %% 4.save in a matrix
                        output_exp_reward_all(seed_index) = output_exp_reward;
                        output_gap_all(seed_index) = output_gap;
                        output_item_all(seed_index) = output_item;
                        corr_flag_all(seed_index) = corr_flag;
                        remain_C_budget_all(seed_index) = C_budget;
                        cur_gapbd(seed_index) = gapbd;
                    end
                    %% 5. save 20 sets of data for each setting of K, L and w_gap
                    mean_output_exp_reward = mean(output_exp_reward_all);
                    std_output_exp_reward = std(output_exp_reward_all);
                    mean_output_gap = mean(output_gap_all);
                    std_output_gap = std(output_gap_all);
                    corr_no = sum( corr_flag_all );
                    mean_re_C_budget = mean(remain_C_budget_all);
                    cur_gapbd_val = cur_gapbd(1);
                    ave_time = mean(timetable);
                    save([ folder_name, '/',simulation_name, '.mat'], ...
                        'output_exp_reward_all', 'output_gap_all', 'output_item_all', 'corr_flag_all', ...
                        'remain_C_budget_all', 'cur_gapbd', ...
                        'mean_output_exp_reward', 'std_output_exp_reward', ...
                        'mean_output_gap', 'std_output_gap', ...
                        'corr_no', ...
                        'mean_re_C_budget', ...
                        'timetable', 'ave_time');
                    %         disp('T L w_good w_bad u lambda mean_re_C_budget gapbd corr_no output_gap_mean output_gap_std output_exp_reward_mean output_exp_reward_std ave_time');
                    disp([
                        algo_name{algo_no}, ' ',...
                        num2str(T), ' ', num2str(L), ' ', ...
                        num2str(w_good), ' ', num2str(w_bad), ' ',...
                        num2str(u), ' ', num2str(lambda), ' ',...
                        num2str(mean_re_C_budget), ' ', num2str( cur_gapbd_val  ), ' ',...
                        num2str(corr_no), ' ', ...
                        num2str( mean_output_gap ),' ', num2str( std_output_gap ),' ',...
                        num2str( mean_output_exp_reward ),' ', num2str( std_output_exp_reward ),' ',...
                        num2str(ave_time) ]);
                    
                    
                end
            end
        end
    end
end 
