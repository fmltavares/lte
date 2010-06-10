function print_log(level,msg)
% Prints debug output.
% (c) Josep Colom Ikuno, INTHFT, 2008
% output:   msg   ... msg to print, a string
%           level ... debug level

global LTE_config;
if LTE_config.debug_level>=level
    msg = strrep(msg,'\','\\');
    msg = strrep(msg,'\\n','\n');
    msg = strrep(msg,'\network','\\network');
    fprintf(msg);
end
