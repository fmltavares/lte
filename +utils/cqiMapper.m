classdef cqiMapper < handle
% This class abstracts the mapping from SNR to CQI and viceversa. This one
% works with a linear approximation.
% (c) Josep Colom Ikuno, INTHFT, 2008

   properties
       max_CQI
       min_CQI
       p % p(1) and p(2) represent the coefficients
   end

   methods
       % Class constructor
       function obj = cqiMapper(p,min_CQI,max_CQI)
           obj.p = p;
           obj.max_CQI = max_CQI;
           obj.min_CQI = min_CQI;
       end
       % Convert from SINR to CQI
       function CQIs = SINR_to_CQI(obj,SINRs,varargin)
           if ~isempty(varargin)
               % This feature turns off clipping
               clipped_feedback = varargin{1};
           else
               clipped_feedback = true;
           end
           CQIs = obj.p(1)*SINRs + obj.p(2);
           if clipped_feedback
               CQIs(~isfinite(CQIs)) = 0;
               less_than_0  = (CQIs<obj.min_CQI); % Actually it means "less than the minimum allowable CQI"
               more_than_15 = (CQIs>obj.max_CQI); % "bigger than the biggest valid CQI"
               ok_values    = ~(less_than_0 | more_than_15);
               CQIs = ok_values.*CQIs + obj.min_CQI*less_than_0 + obj.max_CQI*more_than_15;
           end
       end
       % Convert from CQI to SINR [dB]
       % Please take into account that NO INPUT CHECKING IS DONE!! Take
       % Just take care that the input CQI values are correct, if not
       % results could be inconsistent.
       function SINRs = CQI_to_SINR(obj,CQIs)
           SINRs = (CQIs-obj.p(2)) / obj.p(1); % output in dBs
       end
   end
end 
