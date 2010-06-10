classdef miesmAverager < utils.sinrAverager
    % Implements a MIESM averager. Needs a precalculated table containing
    % the BICM capacity for each of the constellations used, which are here
    % classified according to their modulations order
    % (c) Josep Colom Ikuno, INTHFT, 2010

   properties
       BICM_capacity_tables
       mod_orders
   end

   methods
       function obj = miesmAverager(mat_file_to_load,varargin)
           load(mat_file_to_load);
           CQI_range = LTE_common_get_CQI_params('range');
           CQI_tables = LTE_common_get_CQI_params(CQI_range(1):CQI_range(2));
           obj.mod_orders = [CQI_tables.modulation_order];
           for i_=[BICM_capacity_tables.m_j]
               struct_index = find([BICM_capacity_tables.m_j]==i_,1,'first');
               obj.BICM_capacity_tables{i_} = BICM_capacity_tables(struct_index);
               [b,m,n]=unique(obj.BICM_capacity_tables{i_}.I,'first');
               obj.BICM_capacity_tables{i_}.I_inv = b;
               obj.BICM_capacity_tables{i_}.SNR_inv = obj.BICM_capacity_tables{i_}.SNR(m);
           end
           
           if isempty(varargin)
               plot_capacity = false;
           else
               plot_capacity = varargin{1};
           end
           if plot_capacity
               for m_j_idx=1:length(BICM_capacity_tables)
                   BICM_capacity_tables_all(m_j_idx,:) = BICM_capacity_tables(m_j_idx).I;
                   displaynames{m_j_idx} = sprintf('BICM capacity, %d-QAM',2^BICM_capacity_tables(m_j_idx).m_j);
               end
               figure;
               % Assume that all BICM capacities are calcualted over the same
               % SNR range (so I can plot it like this and Matlab automatically
               % puts the colors there)
               plot(BICM_capacity_tables(m_j_idx).SNR,BICM_capacity_tables_all);
               legend(displaynames,'Location','Best');
               xlabel('SNR [dB]');
               ylabel('BICM Capacity I_{m_j}(\gamma)');
               title('BICM capacity');
               grid on;
           end
       end
       
       % Average the give SINR vector. varargin contains the following:
       %   - varargin{1} = MCS -> values in the range 0:15
       % ALL INPUT VALUES IN LINEAR!
       % Allows for calculations with multiple beta values
       function output = average(obj,SINR_vector,MCSs)
           % Ensure matrix dimensions
           SINR_vector = SINR_vector(:);
           SINR_vector_log = 10*log10(SINR_vector);
           MCSs_vector = MCSs(:);
           MCS_idx = MCSs;
           
           if min(MCS_idx)<1
               error('CQI cannot be lower than 1');
           elseif max(MCS_idx)>length(obj.mod_orders)
               error('CQI cannot be higher than %d',length(obj.mod_orders));
           end
           
           MCSs_mod_orders = obj.mod_orders(MCSs_vector);
           unique_m_js = unique(MCSs_mod_orders);
           MIESM_SINRs = zeros(length(unique_m_js),1);
           
           for i_=1:length(unique_m_js)
               m_j_idx = unique_m_js(i_);
               I     = obj.BICM_capacity_tables{m_j_idx}.I;
               I_inv = obj.BICM_capacity_tables{m_j_idx}.I_inv;
               SNR_log = obj.BICM_capacity_tables{m_j_idx}.SNR;
               SNR_log_inv = obj.BICM_capacity_tables{m_j_idx}.SNR_inv;
               I_interp = mean(interp1(SNR_log,I,SINR_vector_log));
               MIESM_SINRs(i_) = interp1(I_inv,SNR_log_inv,I_interp);
           end
           
           % Implemented like this as many MCSs use just a few modulations.
           inv_mapping(unique_m_js) = 1:length(unique_m_js);
           output = 10.^(MIESM_SINRs(inv_mapping(MCSs_mod_orders))/10);
       end
   end
end 
