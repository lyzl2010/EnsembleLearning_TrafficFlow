classdef SVMFlowPredictor < FlowPredictor
    
    properties
    end
    
    methods ( Access = public )
        
        function [this]=SVMFlowPredictor(dp)
            
            this = this@FlowPredictor(dp);
            
        end
        
        function [Y_predicted] = predict(this,id,day,from,to,dt)
            
            % data provider
            training_dp = this.data_provider ; 
            
            % construct training data matrix
            % X is D-by-T matrix of training data for up-to-now flows. D is the number of days
            % in training_dp with today removed. 
            X = zeros( nnz(training_dp.days(training_dp.days ~= day)) , from/900 );
            % Y is D-by-T' matrix of training data for flows during the prediction horizon. D is the number of days
            % in training_dp with today removed. 
            Y = zeros(nnz(training_dp.days(training_dp.days ~= day)) , ( to - from )/900) ;
            idx = find(training_dp.days ~= day) ; %find day index not equals today
            for i=1:length(idx)
                X(i,:) = training_dp.data(idx(i)).flw_out_vph(1: from/900);
                Y(i,:) =  training_dp.data(idx(i)).flw_out_vph(from/900+1:to/900 );
            end
            
            todayidx = find(training_dp.days == day) ; % find today index
            Y_predicted = zeros( ( to - from )/900 , 1) ;
            for interval = 1: ( to - from )/900
                % use gaussian kernel
                svmmdl = fitrsvm(X,Y(:,interval),'KernelFunction','gaussian','KernelScale','auto','Standardize',true);
                Y_predicted(interval) = predict(svmmdl,training_dp.data(todayidx).flw_out_vph(1: from/900)) ;
            end
            
            Y_predicted = Y_predicted'; 
            
        end
        
    end
    
    methods ( Static , Access = private )
        
        function [training_dp] = construct_trainingdp_includetoday(dp,day,numdays_for_training)
            
            % clone an independent copy of this; this is a handle class
            training_dp = feval(class(dp),dp.ids) ;
            if find(training_dp.days == day) <= numdays_for_training
                error('does not satisfy the minimum number of days for training')
            end
            training_day_ind = dp.days <= day & dp.days >= day - numdays_for_training;
            training_dp.days = training_dp.days(training_day_ind);
            training_dp.data = training_dp.data(training_day_ind);
            training_dp.vds_is_good =  training_dp.vds_is_good(training_day_ind);
        end
        
             
    end
    
end
