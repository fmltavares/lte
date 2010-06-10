function macroscopic_pathloss_model = LTE_common_get_macroscopic_pathloss_model(varargin)
% Returns the adequate macroscopic pathloss model, according to the settings in the LTE_config.
% (c) Josep Colom Ikuno, INTHFT, 2009
% www.nt.tuwien.ac.at

global LTE_config;

if ~isempty(varargin)
    print_output = varargin{1};
else
    print_output = true;
end

switch LTE_config.macroscopic_pathloss_model
    case 'free space'
        macroscopic_pathloss_model = macroscopic_pathloss_models.freeSpacePathlossModel(LTE_config.frequency);
        if print_output
            print_log(1,['Using free space pathloss model\n']);
        end
    case 'cost231'
        macroscopic_pathloss_model = macroscopic_pathloss_models.cost231PathlossModel(LTE_config.frequency,LTE_config.macroscopic_pathloss_model_settings.environment);
        if print_output
            print_log(1,['Using COST 231 pathloss model, ' LTE_config.macroscopic_pathloss_model_settings.environment ' environment\n']);
        end
    case 'TS36942'
        macroscopic_pathloss_model = macroscopic_pathloss_models.TS36942PathlossModel(LTE_config.frequency,LTE_config.macroscopic_pathloss_model_settings.environment);
        if print_output
            print_log(1,['Using TS 36.942-recommended pathloss model, ' LTE_config.macroscopic_pathloss_model_settings.environment ' environment\n']);
        end
    case 'TS25814'
        macroscopic_pathloss_model = macroscopic_pathloss_models.TS25814PathlossModel(LTE_config.frequency);
        if print_output
            print_log(1,['Using TS 25.814-recommended pathloss model\n']);
        end
    otherwise
        error(['"' LTE_config.macroscopic_pathloss_model '" macroscopic pathloss model not supported']);
end