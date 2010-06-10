classdef shadowFadingMapClaussen < handle
    % Class that represents a space-correlated shadow fading map for each
    % one of the eNodeBs. Implementation of Claussen's paper "Efficient
    % modeling of channel maps with correlated shadow fading in mobile
    % radio systems". Extended to correlate the shadow fading maps from
    % each of the eNodeBs. 1 map per eNodeB is generated, NOT 1 map per
    % sector.
    % (c) Josep Colom Ikuno, INTHFT, 2008

    % Attributes of this give eNodeB
    properties
        % number of neighbors taken into account when generating the map
        n_neighbors
        % the pathloss data. Addresses as (x,y,bts)
        pathloss
        % data resulution in meters/pixel
        data_res
        % the rectangle that the map encompasses, in meters (Region Of
        % Interest)
        roi_x
        roi_y
        % Cross-correlation between the gaussian maps that served as base
        % for the space-correlated shadow fading maps
        an_ccorr
        % Cross-correlation between the different shadow fading maps
        sn_ccorr
    end
    % Associated eNodeB methods
    methods
        % Class constructor
        function obj = shadowFadingMapClaussen(resolution,roi_x,roi_y,n_neighbors,eNodeBs,mean,std,eNodeBs_ccorr,varargin)
            % Generates a 2-D space-correlated shadow fading map. Implementation of
            % Claussen's paper "Efficient modeling of channel maps with correlated
            % shadow fading in mobile radio systems".
            % As suggested by TS 25.942 (still nothing specified for LTE), correlation
            % between eNodeB's shadow fading is fixed to 0.5.
            % Shadow fading is lognormal-ly distributed with mean=0dB and sd=10dB
            % (c) Josep Colom Ikuno, INTHFT, 2008
            % input:   resolution   ... desired resolution of the map in meters/pixel
            %          roi_x        ... x range of the ROI
            %          roi_y        ... y range of the ROI
            %          n_neighbours ... 4 or 8. The number of neighboring pixels to be
            %                           taken into account when generating the space
            %                           correlation.
            %          eNodeBs      ... array containing the eNodeBs.
            %                           Needed if, at some point the
            %                           cross-correlation between the maps
            %                           is changed to something that
            %                           depends on the distance between
            %                           them.
            %          mean         ... shadow fading mean
            %          std          ... shadow fading standard deviation
            %          eNodeBs_ccorr... cross correlation between the
            %                           different eNodeB's shadow fading
            %                           maps
            %          a_n (opt)    ... cross-correlated gaussian base to do the shadow
            %                           fading
            % output:  s            ... shadow fading map
            %          a_n_matrix   ... correlated white noise matrixes based on which
            %                           the shadow fading was generated.
            %          r_eNodeBs    ... target desired cross-correlation between the
            %                           several shadow fading maps.
            %          an_ccorr     ... calculated cross correlation between the
            %                           generated gaussian noises that serve as a basis
            %                           for the shadow fading map.
            %          sn_ccorr     ... calculated cross correlation between the
            %                           generated shadow fading maps.

            %% Initialization
            roi_maximum_pixels = LTE_common_pos_to_pixel( [roi_x(2) roi_y(2)], [roi_x(1) roi_y(1)], resolution);

            % Pixel correlation parameters
            alpha = 1/20;
            r = @(d) exp(-alpha*d);
            d = resolution; % How many meters a hop is

            % Map size in pixels
            N_x = roi_maximum_pixels(1);
            N_y = roi_maximum_pixels(2);

            %% Calculate cross-correlation between eNodeBs
            num_eNodeBs = length(eNodeBs);
            % Fixed shadow fading correlation between maps
            r_eNodeBs = eNodeBs_ccorr;

            %% Generate cross correlated gaussian maps
            % The last one will be the original random one
            if length(varargin)==0
                a_n_random_matrix = mean + std*randn(N_y,N_x,num_eNodeBs);
                a_n_original_map = mean + std*randn(N_y,N_x);

                a_n_matrix = zeros(N_y,N_x,num_eNodeBs);
                for i_=1:num_eNodeBs
                    % Generate i gaussian maps based on an 'original' one
                    a_n_matrix(:,:,i_) = sqrt(r_eNodeBs)*a_n_original_map + sqrt(1-r_eNodeBs)*a_n_random_matrix(:,:,i_);
                end
            else
                a_n_matrix = varargin{1};
            end

            an_ccorr = zeros(num_eNodeBs,num_eNodeBs);
            for i_=1:num_eNodeBs
                for j_=1:num_eNodeBs
                    correlation = corr2(a_n_matrix(:,:,i_),a_n_matrix(:,:,j_));
                    an_ccorr(i_,j_) = correlation;
                    an_ccorr(j_,i_) = correlation;
                end
            end

            %% R matrices for the map calculation
            switch n_neighbors
                case 4
                    R = [
                        1              r(d)           r(2*d)         r(d)           r(sqrt(2)*d)
                        r(d)           1              r(d)           r(sqrt(2)*d)   r(d)
                        r(2*d)         r(d)           1              r(sqrt(5)*d)   r(sqrt(2)*d)
                        r(d)           r(sqrt(2)*d)   r(sqrt(5)*d)   1              r(d)
                        r(sqrt(2)*d)   r(d)           r(sqrt(2)*d)   r(d)           1
                        ];
                case 8
                    R = [
                        1              r(d)           r(2*d)         r(d)           r(d)          r(sqrt(5)*d)   r(d)           r(3*d)         r(sqrt(2)*d)
                        r(d)           1              r(d)           r(sqrt(2)*d)   r(sqrt(2)*d)  r(sqrt(2)*d)   r(2*d)         r(2*d)         r(d)
                        r(2*d)         r(d)           1              r(sqrt(5)*d)   r(sqrt(5)*d)  r(d)           r(3*d)         r(d)           r(sqrt(2)*d)
                        r(d)           r(sqrt(2)*d)   r(sqrt(5)*d)   1              r(2*d)        r(sqrt(8)*d)   r(sqrt(2)*d)   r(sqrt(10)*d)  r(d)
                        r(d)           r(sqrt(2)*d)   r(sqrt(5)*d)   r(2*d)         1             r(2*d)         r(sqrt(2)*d)   r(sqrt(10)*d)  r(sqrt(5)*d)
                        r(sqrt(5)*d)   r(sqrt(2)*d)   r(d)           r(sqrt(8)*d)   r(2*d)        1              r(sqrt(10)*d)  r(sqrt(2)*d)   r(sqrt(5)*d)
                        r(d)           r(2*d)         r(3*d)         r(sqrt(2)*d)   r(sqrt(2)*d)  r(sqrt(10)*d)  1              r(4*d)         r(sqrt(5)*d)
                        r(3*d)         r(2*d)         r(d)           r(sqrt(10)*d)  r(sqrt(10)*d) r(sqrt(2)*d)   r(4*d)         1              r(sqrt(5)*d)
                        r(sqrt(2)*d)   r(d)           r(sqrt(2)*d)   r(d)           r(sqrt(5)*d)  r(sqrt(5)*d)   r(sqrt(5)*d)   r(sqrt(5)*d)   1
                        ];
                otherwise
                    error('Only 4 and 8 values supported');
            end

            L           = chol(R,'lower');
            lambda_n_T  = L(end,:);
            R_tilde     = R(1:end-1,1:end-1);
            L_tilde     = chol(R_tilde,'lower');
            inv_L_tilde = inv(L_tilde);

            N_x = size(a_n_matrix,2);
            N_y = size(a_n_matrix,1);
            s = zeros(N_y,N_x,num_eNodeBs);

            %% Calculate space-correlated maps
            for y_=1:N_y
                for x_=1:N_x
				    % Ideally this should be a static method, but since I had problems calling a static method from the class constructor, I
					% implemented this function outside of the class. Probably Matlab still has some bugs/problems when working with objects.
                    s_tilde = LTE_aux_shadowFadingMapClaussen_get_neighbors(s,[x_ y_],n_neighbors);
                    for b_=1:num_eNodeBs
                        a_n = a_n_matrix(y_,x_,b_);
                        s_n = lambda_n_T*[ inv_L_tilde*s_tilde(:,b_); a_n ];
                        s(y_,x_,b_) = s_n;
                    end
                end
            end

            %% Calculate cross-correlation between maps
            sn_ccorr = zeros(num_eNodeBs,num_eNodeBs);
            for i_=1:num_eNodeBs
                for j_=1:num_eNodeBs
                    correlation = corr2(s(:,:,i_),s(:,:,j_));
                    sn_ccorr(i_,j_) = correlation;
                    sn_ccorr(j_,i_) = correlation;
                end
            end
            
            %% Fill in the object
            obj.roi_x       = roi_x;
            obj.roi_y       = roi_y;
            obj.n_neighbors = n_neighbors;
            obj.data_res    = resolution;
            obj.pathloss    = s;
            obj.an_ccorr    = an_ccorr;
            obj.sn_ccorr    = sn_ccorr;
        end

        function print(obj)
            fprintf('claussenShadowFadingMap, using %d neighbors\n',obj.n_neighbors);
            fprintf('Data resolution: %d meters/pixel\n',obj.data_res);
            fprintf('ROI: x: %d,%d y:%d,%d\n',obj.roi_x(1),obj.roi_x(2),obj.roi_y(1),obj.roi_y(2));
        end
        % Returns the pathloss of a given point in the ROI
        function pathloss = get_pathloss(obj,pos,b_)
            x_ = pos(1);
            y_ = pos(2);
            point_outside_lower_bound = sum([x_ y_] < [obj.roi_x(1),obj.roi_y(1)]);
            point_outside_upper_bound = sum([x_ y_] > [obj.roi_x(2),obj.roi_y(2)]);
            if point_outside_lower_bound || point_outside_upper_bound
                pathloss = NaN;
            else
                % Some interpolation could be added here
                pixel_coord = LTE_common_pos_to_pixel([x_ y_],obj.coordinate_origin,obj.data_res);
                pathloss = obj.pathloss(pixel_coord(2),pixel_coord(1),b_);
            end
        end
        % Plots the pathloss of a given eNodeB
        function plot_pathloss(obj,b_)
            figure;
            imagesc(obj.pathloss(:,:,b_));
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
        % Returns the number of eNodeBs that this pathloss map contains
        function [ eNodeBs ] = size(obj)
            eNodeBs            = size(obj.pathloss,3);
        end
        % Returns a random position inside of the Region Of Interest (ROI)
        function position = random_position(obj)
            position = [ random('unif',obj.roi_x(1),obj.roi_x(2)),...
                random('unif',obj.roi_y(1),obj.roi_y(2)) ];
        end
    end
end