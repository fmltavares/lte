classdef eNodeB_sector < handle
    % Defines an eNodeB's sector
    % (c) Josep Colom Ikuno, INTHFT, 2008

    properties
        % Sector id inside the eNodeB
        id
        % eNodeB to which this sector belongs
        parent_eNodeB
        % Sector antenna's azimuth
        azimuth
        % Sector antenna
        antenna
        % Users attached to this eNodeB. Array of UEs stored as a
        % linked list. This points to the first user
        users = [];
        % number of attached UEs
        attached_UEs = 0;
        % eNodeB sector maximum transmit power, in Watts
        max_power
        % Height at which the transmitter is. normally this field will not
        % be used (the  one from the pathloss model will be used, but for
        % Odyssey data, this is fille
        tx_height
        % This sector's scheduler
        scheduler
        % This sector's currently used resource block assignment grid
        RB_grid
        % Number of antennas
        nTX
        
        % the last received feedback and a list of attached UEs
        last_received_feedback
        UEs_attached_last_TTI
        
        % trace that stores the received feedbacks
        feedback_trace
        % trace that stores the RB assignments
        sector_trace
        
        % Configuration option for zero-delay CQI feedback
        zero_delay_feedback = false;
        
        % this parameter allows you to send unquantized feedback. It can
        % serve to assert how good a certain CQI mapping approaches the
        % target BLER in comparison to directly knowing the SINR
        unquantized_CQI_feedback = false;
    end

    methods
        
        function print(obj)
            fprintf(' Sector %d: ',obj.id);
            fprintf('%s %ddB %d°\n',obj.antenna.antenna_type,obj.antenna.mean_antenna_gain,obj.azimuth);
            fprintf('  ');
            obj.scheduler.print;
            fprintf('  UEs: ');
            if ~isempty(obj.users)
                current_last_node = obj.users(1);
                while ~isempty(current_last_node.Next)
                    % Do something
                    fprintf('%d ',current_last_node.Data.id);
                    current_last_node = current_last_node.Next;
                end
                % Do something for the last node
                fprintf('%d ',current_last_node.Data.id);
            end
            fprintf('\n');
            fprintf('  '); obj.RB_grid.print;
        end
        
        % Attachs a user to this eNodeB, first checking that the node is
        % not already in the list. It will update the UE's
        % 'attached_eNodeB' variable, effectively binding the UE to this
        % eNodeB. Remember to also add the user to the scheduler, or it
        % will NOT be served!
        function attachUser(obj,user)
            % If the user list is empty
            if isempty(obj.users)
                obj.users = utils.dlnode(user);
                user.attached_eNodeB = obj.parent_eNodeB;
                user.attached_sector = obj.id;
                obj.attached_UEs = obj.attached_UEs + 1;
                % If there are already some users
            else
                % First check if this user is not already in the list
                current_last_node = obj.users;
                user_already_in = false;
                % While the last node has no Next
                while ~isempty(current_last_node.Next)
                    if current_last_node.Data.id==user.id
                        user_already_in = true;
                    end
                    current_last_node = current_last_node.Next;
                end
                % Process the last node
                if current_last_node.Data.id==user.id
                    user_already_in = true;
                end
                % Now current_last_node is the last node
                % Add the new user after it, if not already in the list
                if ~user_already_in
                    new_node = utils.dlnode(user);
                    new_node.insertAfter(current_last_node);
                    obj.attached_UEs = obj.attached_UEs + 1;
                    user.attached_eNodeB = obj.parent_eNodeB;
                    user.attached_sector = obj.id;
                end
            end
        end
        
        % Deattaches a user from this eNodeB. This function does change
        % the user's 'attached_eNodeB' variable. Remember to delete the
        % user from the scheduler also, or nonexistent users will be
        % scheduled!
        function deattachUser(obj,user)
            % If the user list is empty, do nothing
            if ~isempty(obj.users)
                % Process the node list
                current_last_node = obj.users;
                while ~isempty(current_last_node.Next)
                    % Do something
                    if current_last_node.Data.id==user.id
                        current_last_node.Data.attached_eNodeB = [];
                        % In case we are deleting the head
                        if obj.users.Data.id==user.id
                            obj.users = current_last_node.Next;
                        end
                        current_last_node.disconnect;
                        obj.attached_UEs = obj.attached_UEs - 1;
                        return
                    end
                    current_last_node = current_last_node.Next;
                end
                % Do something for the last node
                if current_last_node.Data.id==user.id
                    current_last_node.Data.attached_eNodeB = [];
                    % In case we are deleting the head
                    if obj.users.Data.id==user.id
                        obj.users = current_last_node.Next;
                    end
                    current_last_node.disconnect;
                    obj.attached_UEs = obj.attached_UEs - 1;
                    return
                end
            end
            
            % Also delete the UE from the scheduler
            obj.scheduler.remove_UE(user.id)
        end
        
        % Queries whether a user is attached
        function is_attached = userIsAttached(obj,user)
            % If the user list is empty, return false
            if ~isempty(obj.users)
                % Process the node list
                current_last_node = obj.users;
                while ~isempty(current_last_node.Next)
                    % Do something
                    if current_last_node.Data.id==user.id
                        is_attached = true;
                        return
                    end
                    current_last_node = current_last_node.Next;
                end
                % Do something for the last node
                if current_last_node.Data.id==user.id
                    is_attached = true;
                    return
                end
                is_attached = false;
            else
                is_attached = false;
            end
        end
        
        % Receives and stores the received feedbacks from the UEs
        function receive_UE_feedback(obj)
            current_node = obj.users;
            obj.last_received_feedback.UE_id             = zeros(obj.attached_UEs,1);
            obj.last_received_feedback.CQI               = zeros(obj.attached_UEs,obj.RB_grid.n_RB,obj.RB_grid.nCodewords);
            obj.last_received_feedback.feedback_received = false(obj.attached_UEs,1);
            received_CQI_idx = 1;
            
            for i_=1:obj.attached_UEs
                UE_i  = current_node.Data;
                
                % Fill in list of currently attached UEs
                if i_==1
                    obj.UEs_attached_last_TTI = UE_i;
                else
                    obj.UEs_attached_last_TTI(i_) = UE_i;
                end
                
                % Receive the feedback from each user
                UE_id = UE_i.id;
                feedback_u_ = UE_i.uplink_channel.get_feedback;
                % This means that the first TTI, even with 0 delay there is
                % no feedback, as no ACKs are available
                if ~isempty(feedback_u_)
                    
                    % For the zero delay case, substitute the delayed
                    % feedback with a zero-delay CQI feedback
                    if obj.zero_delay_feedback
                        feedback_u_.CQI = UE_i.feedback_measured_CQI;
                    end
                    
                    % Store feedback trace
                    obj.feedback_trace.store(...
                        feedback_u_.CQI,...
                        feedback_u_.ACK,...
                        feedback_u_.TB_size,...
                        feedback_u_.UE_scheduled,...
                        UE_id,...
                        obj.parent_eNodeB.id,...
                        obj.id,...
                        obj.parent_eNodeB.clock.current_TTI);
                    
                    % Store accumulated ACK trace. Done separately because
                    % this is stored in the eNodeB's trace, as it eases
                    % post-processing. It updates the number of correctly
                    % received bits in the trace
                    obj.sector_trace.store_ACK_report(...
                        feedback_u_.nCodewords,...
                        feedback_u_.UE_scheduled,...
                        feedback_u_.ACK,...
                        feedback_u_.TB_size,...
                        feedback_u_.TTI_idx);
                    
                    % Store the last received feedback for all of the attached
                    % users, as it will be needed by the scheduler.
                    % More refined schedulers may need longer "historical" information
                    obj.last_received_feedback.UE_id(received_CQI_idx)             = UE_id;
                    obj.last_received_feedback.CQI(received_CQI_idx,:,:)           = feedback_u_.CQI';
                    obj.last_received_feedback.feedback_received(received_CQI_idx) = true;
                else
                    obj.last_received_feedback.feedback_received(received_CQI_idx) = false;
                end
                
                received_CQI_idx = received_CQI_idx + 1;
                current_node = current_node.Next;
            end            
        end
        
        % Schedule users in the RB grid for this sector. Modifies the sent
        % resourceBlockGrid object with the user allocation.
        function schedule_users(obj)
            obj.scheduler.schedule_users(obj.RB_grid,obj.UEs_attached_last_TTI,obj.last_received_feedback);
            % Store traces
            obj.sector_trace.store(obj.RB_grid);
        end
    end
end
