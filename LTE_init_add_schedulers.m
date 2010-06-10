function LTE_init_add_schedulers(eNodeBs,UEs,CQI_mapper,BLER_curves)
% Adds the needed scheduler type and resource block grid to each eNodeb's
% sector
% (c) Josep Colom Ikuno, INTHFT, 2008
% input:   eNodeBs  ... array of eNodeBs
%          UEs      ... array of UEs

global LTE_config;

switch LTE_config.scheduler
    case 'round robin'
        % Correct
    case 'best cqi'
        % Correct
    case 'proportional fair'
        % Correct
    otherwise
        error([LTE_config.scheduler ' scheduler not supported']);
end

print_log(1,['Creating ' LTE_config.scheduler ' schedulers and resource block grids\n']);

% Add RB grid representation and scheduler to each sector.
% Set also homogeneous power load
for b_ = 1:length(eNodeBs)
    for s_=1:length(eNodeBs(b_).sectors)
        switch LTE_config.scheduler
            case 'round robin'
                eNodeBs(b_).sectors(s_).scheduler = network_elements.roundRobinScheduler(eNodeBs(b_).sectors(s_),length(UEs)*2); % some safe margin
            case 'best cqi'
                eNodeBs(b_).sectors(s_).scheduler = network_elements.bestCqiScheduler(eNodeBs(b_).sectors(s_));
            case 'proportional fair'
                if isfield(LTE_config,'scheduler_params') && isfield(LTE_config.scheduler_params,'alpha') && isfield(LTE_config.scheduler_params,'beta')
                    eNodeBs(b_).sectors(s_).scheduler = network_elements.proportionalFairScheduler(eNodeBs(b_).sectors(s_),LTE_config.scheduler_params.alpha,LTE_config.scheduler_params.beta);
                else
                    eNodeBs(b_).sectors(s_).scheduler = network_elements.proportionalFairScheduler(eNodeBs(b_).sectors(s_));
                end
            otherwise
                error('Scheduler %s not defined',LTE_config.scheduler);
        end
        
        % Set scheduler SINR averaging algorithm
        switch LTE_config.SINR_averaging.algorithm
            case 'MIESM'
                eNodeBs(b_).sectors(s_).scheduler.SINR_averager = utils.miesmAverager(LTE_config.SINR_averaging.BICM_capacity_tables);
            case 'EESM'
                eNodeBs(b_).sectors(s_).scheduler.SINR_averager = utils.eesmAverager(LTE_config.SINR_averaging.betas,LTE_config.SINR_averaging.MCSs);
            otherwise
                error('SINR averaging algorithm not supported');
        end

        % Other data required to perform SINR averaging at the transmitter side
        eNodeBs(b_).sectors(s_).scheduler.CQI_mapper = CQI_mapper;
        eNodeBs(b_).sectors(s_).scheduler.BLER_curves = BLER_curves;
        
        % Add genie information
        eNodeBs(b_).sectors(s_).scheduler.genie.UEs     = UEs;
        eNodeBs(b_).sectors(s_).scheduler.genie.eNodeBs = eNodeBs;
        
        % Add TTI delay information
        eNodeBs(b_).sectors(s_).scheduler.feedback_delay_TTIs = LTE_config.feedback_channel_delay;
        
        % ToDo: redo this
        % 1: Single Antenna
        % 2: Transmit Diversity
        % 3: Open Loop Spatial Multiplexing
        % 4: Closed Loop SM
        switch LTE_config.tx_mode
            case 1
                nCodewords = 1;
                nLayers = 1;
            case 2
                nCodewords = 1;
                nLayers = 2;
            case 3
                nCodewords = 2;
                nLayers = 2;
            otherwise
                error('Mode not supported');
        end
        
        eNodeBs(b_).sectors(s_).RB_grid = network_elements.resourceBlockGrid(LTE_config.N_RB,LTE_config.sym_per_RB,nCodewords,nLayers);
        eNodeBs(b_).sectors(s_).RB_grid.set_homogeneous_power_allocation(eNodeBs(b_).sectors(s_).max_power);
        eNodeBs(b_).sectors(s_).RB_grid.nCodewords = nCodewords;
        eNodeBs(b_).sectors(s_).RB_grid.nLayers    = nLayers;
        eNodeBs(b_).sectors(s_).RB_grid.tx_mode    = LTE_config.tx_mode;
    end
end

% Add each user to its corresponding scheduler (initialisation)
for u_=1:length(UEs)
    id = UEs(u_).id;
    b_ = UEs(u_).attached_eNodeB.id;
    s_ = UEs(u_).attached_sector;
    eNodeBs(b_).sectors(s_).scheduler.add_UE(id);
end
