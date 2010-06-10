classdef macroscopicPathlossMap < channel_gain_wrappers.macroscopicPathlossWrapper
    % Class that represents the macroscopic pathloss in a precalculated way.
    % Also contains a cell assignment map that is used to initialize the 
    % UE eNodeB assignment (also used to re-create users when they go out 
    % of the Region Of Interest).
    % (c) Josep Colom Ikuno, INTHFT, 2008

    % Attributes of this give eNodeB
    properties
        % the pathloss data. Including the minimum coupling loss. Addresses as (x,y,sector,bts)
        pathloss
        % sector assignment (x,y,1)=sector, (x,y,2)=eNodeB
        sector_assignment
        % sector sizes (in pixels) according to the sector_assignment matrix. Used to locate the users
        sector_sizes
        % the same as before but only taking into account macroscopic pathloss (empty for data for which there is no shadow fading)
        sector_assignment_no_shadowing
        sector_sizes_no_shadowing
        % data resulution in meters/pixel
        data_res
        % the rectangle that the map encompasses, in meters (Region Of Interest)
        roi_x
        roi_y
        % A name that describes this pathloss map
        name
    end
    % Associated eNodeB methods
    methods
        function print(obj)
            fprintf('macroscopicPathlossMap\n');
            fprintf('Data resolution: %d meters/pixel\n',obj.data_res);
            fprintf('ROI: x: %d,%d y:%d,%d\n',obj.roi_x(1),obj.roi_x(2),obj.roi_y(1),obj.roi_y(2));
        end
        % Returns the pathloss of a given point in the ROI
        function pathloss = get_pathloss(obj,pos,s_,b_)
            x_ = pos(1);
            y_ = pos(2);
            point_outside_lower_bound = sum([x_ y_] < [obj.roi_x(1),obj.roi_y(1)]);
            point_outside_upper_bound = sum([x_ y_] > [obj.roi_x(2),obj.roi_y(2)]);
            if point_outside_lower_bound || point_outside_upper_bound
                pathloss = NaN;
            else
                % Some interpolation could be added here
                pixel_coord = LTE_common_pos_to_pixel([x_ y_],obj.coordinate_origin,obj.data_res);
                pathloss = obj.pathloss(pixel_coord(2),pixel_coord(1),s_,b_);
            end
        end
        % Plots the pathloss of a given eNodeB sector
        function plot_pathloss(obj,b_,s_)
            figure;
            imagesc(obj.pathloss(:,:,s_,b_));
        end
        % Range of positions in which there are valid pathloss values
        function [x_range y_range] = valid_range(obj)
            x_range = [ obj.roi_x(1) obj.roi_x(2) ];
            y_range = [ obj.roi_y(1) obj.roi_y(2) ];
        end
        % Returns the coordinate origin for this pathloss map
        function pos = coordinate_origin(obj)
            pos = [ obj.roi_x(1) obj.roi_y(1) ];
        end
        % Returns the eNodeB-sector that has the minimum pathloss for a
        % given (x,y) coordinate. Returns NaN if position is not valid
        % You can call it as:
        %   cell_assignment(pos), where pos = (x,y)
        %   cell_assignment(pos_x,pos_y)
        function [ eNodeB_id sector_num ] = cell_assignment(obj,pos,varargin)
            if length(varargin)<1
                x_ = pos(1);
                y_ = pos(2);
            else
                x_ = pos(1);
                y_ = varargin{1};
            end
            if max([x_ y_] < [obj.roi_x(1),obj.roi_y(1)]) >= 1
                eNodeB_id = NaN;
                sector_num = NaN;
            elseif max([x_ y_] > [obj.roi_x(2),obj.roi_y(2)]) >= 1
                eNodeB_id = NaN;
                sector_num = NaN;
            else
                % Some interpolation could be added here, but not so
                % useful to have so much precision, actually...
                pixel_coord = LTE_common_pos_to_pixel([x_ y_],obj.coordinate_origin,obj.data_res);
                eNodeB_id  = obj.sector_assignment(pixel_coord(2),pixel_coord(1),2);
                sector_num = obj.sector_assignment(pixel_coord(2),pixel_coord(1),1);
            end
        end
        % Returns the number of eNodeBs and sectors per eNodeB that this
        % pathloss map contains
        function [ eNodeBs sectors_per_eNodeB ] = size(obj)
            eNodeBs            = size(obj.pathloss,4);
            sectors_per_eNodeB = size(obj.pathloss,3);
        end
        % Returns a random position inside of the Region Of Interest (ROI)
        function position = random_position(obj)
            position = [ random('unif',obj.roi_x(1),obj.roi_x(2)),...
                random('unif',obj.roi_y(1),obj.roi_y(2)) ];
        end
    end
end