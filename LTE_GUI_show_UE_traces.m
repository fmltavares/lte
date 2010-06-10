function varargout = LTE_GUI_show_UE_traces(varargin)
% LTE_GUI_SHOW_UE_TRACES M-file for LTE_GUI_show_UE_traces.fig
%      LTE_GUI_SHOW_UE_TRACES, by itself, creates a new LTE_GUI_SHOW_UE_TRACES or raises the existing
%      singleton*.
%
%      H = LTE_GUI_SHOW_UE_TRACES returns the handle to a new LTE_GUI_SHOW_UE_TRACES or the handle to
%      the existing singleton*.
%
%      LTE_GUI_SHOW_UE_TRACES('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LTE_GUI_SHOW_UE_TRACES.M with the given input arguments.
%
%      LTE_GUI_SHOW_UE_TRACES('Property','Value',...) creates a new LTE_GUI_SHOW_UE_TRACES or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before LTE_GUI_show_UE_traces_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to LTE_GUI_show_UE_traces_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help LTE_GUI_show_UE_traces

% Last Modified by GUIDE v2.5 25-Jun-2009 13:44:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @LTE_GUI_show_UE_traces_OpeningFcn, ...
                   'gui_OutputFcn',  @LTE_GUI_show_UE_traces_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before LTE_GUI_show_UE_traces is made visible.
function LTE_GUI_show_UE_traces_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LTE_GUI_show_UE_traces (see VARARGIN)

% Choose default command line output for LTE_GUI_show_UE_traces
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Save user data
LTE_config = varargin{1};
simulation_traces = varargin{2};
eNodeBs = varargin{3};
UEs = varargin{4};
application_data.LTE_config = LTE_config;
application_data.simulation_traces = simulation_traces;
application_data.eNodeBs = eNodeBs;
application_data.UEs = UEs;

set(hObject,'UserData',application_data);

% Update listbox content on creation
nr_UEs = length(application_data.simulation_traces.UE_traces);

if nr_UEs>0
    for i_=1:nr_UEs
        UE_list{i_} = num2str(i_);
    end

    for nr_RBs = 1:LTE_config.N_RB
        RB_list{nr_RBs} = num2str(nr_RBs);
    end
    
    for i_=1:LTE_config.maxStreams
        number_of_streams{i_} = num2str(i_);
    end

    set(handles.listbox1,'String',UE_list);
    set(handles.listbox2,'String',RB_list);
    set(handles.listbox3,'String',number_of_streams);
    
    trace_UE_CQIs(handles,1,1,1);
    trace_UE_CQIs_hist(handles,1,1,1);
    trace_UE_throughput(handles,1,1);
    plot_eNodeBs_and_UE_pos(handles,1);
end

% UIWAIT makes LTE_GUI_show_UE_traces wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = LTE_GUI_show_UE_traces_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1
UE_idx = get(handles.listbox1,'Value');
stream_idx = get(handles.listbox3,'Value');
RB_idx = get(handles.listbox2,'Value');
trace_UE_CQIs(handles,UE_idx,RB_idx,stream_idx);
trace_UE_CQIs_hist(handles,UE_idx,RB_idx,stream_idx);
trace_UE_throughput(handles,UE_idx,stream_idx);
plot_eNodeBs_and_UE_pos(handles,UE_idx);


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function trace_UE_CQIs(handles,UE_idx,RB_idx,stream_number)

user_data = get(handles.figure1,'UserData');
LTE_config = user_data.LTE_config;
simulation_traces = user_data.simulation_traces;

trace_length = size(simulation_traces.UE_traces(1).ACK,2);
x_axis_s = (1:trace_length) * LTE_config.TTI_length;

UE_RB_CQI = squeeze(simulation_traces.UE_traces(UE_idx).CQI_sent(stream_number,RB_idx,:));
UE_mean_RB_CQI = mean(squeeze(simulation_traces.UE_traces(UE_idx).CQI_sent(stream_number,:,:)));
UE_TB_CQI = simulation_traces.UE_traces(UE_idx).TB_CQI(stream_number,:);

windowSize_cqi = floor(str2double(get(handles.edit3,'String')));
UE_RB_CQI = filter(ones(1,windowSize_cqi)/windowSize_cqi,1,double(UE_RB_CQI));
UE_mean_RB_CQI = filter(ones(1,windowSize_cqi)/windowSize_cqi,1,double(UE_mean_RB_CQI));
UE_TB_CQI = filter(ones(1,windowSize_cqi)/windowSize_cqi,1,double(UE_TB_CQI));

figure(gcf);
cla(handles.axes1);
hold(handles.axes1,'on');
plot(handles.axes1,x_axis_s,UE_RB_CQI,'blue');
plot(handles.axes1,x_axis_s,UE_mean_RB_CQI,'red');
plot(handles.axes1,x_axis_s,UE_TB_CQI,'black');
xlabel(handles.axes1,{'t [s]'});
ylabel(handles.axes1,{'CQI'});
title(handles.axes1,sprintf('CQI report, UE %d, RB %d, stream %d',UE_idx,RB_idx,stream_number));
box(handles.axes1,'on');
grid(handles.axes1,'on');
ylim(handles.axes1,[0 16]);
hold(handles.axes1,'off');
legend(handles.axes1,'Sent CQI report','Mean CQI across RBs','TB CQI','Location','Best');

% --- Executes on selection change in listbox2.
function listbox2_Callback(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listbox2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox2
UE_idx = get(handles.listbox1,'Value');
stream_idx = get(handles.listbox3,'Value');
RB_idx = get(handles.listbox2,'Value');
trace_UE_CQIs(handles,UE_idx,RB_idx,stream_idx);
trace_UE_CQIs_hist(handles,UE_idx,RB_idx,stream_idx);


% --- Executes during object creation, after setting all properties.
function listbox2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function plot_eNodeBs_and_UE_pos(handles,UE_idx)

user_data = get(handles.figure1,'UserData');
LTE_config = user_data.LTE_config;
simulation_traces = user_data.simulation_traces;
eNodeBs = user_data.eNodeBs;
UEs =  user_data.UEs;

cla(handles.axes2);
hold(handles.axes2,'on');
xlim(handles.axes2,'auto')
ylim(handles.axes2,'auto')
text_shifting = 2.5;
text_interline = 2.5;
axes(handles.axes2);

% Plot eNodeBs
for b_=1:length(eNodeBs)
    % Plot a line that tells where the antennas are pointing
    vector_length = 100;
    origin = eNodeBs(b_).pos;
    for s_=1:length(eNodeBs(b_).sectors)
        angle = wrapTo360(-eNodeBs(b_).sectors(s_).azimuth+90);
        vector = vector_length*[ cosd(angle) sind(angle) ];
        destiny = vector + origin;

        plot(handles.axes2,[origin(1) destiny(1)],[origin(2) destiny(2)]);
    end
    % Plot the eNodeBs
    scatter(handles.axes2,eNodeBs(b_).pos(1),eNodeBs(b_).pos(2),'Marker','o','MarkerFaceColor','red','MarkerEdgeColor','black');
    text(eNodeBs(b_).pos(1)+15*text_shifting,eNodeBs(b_).pos(2)+15*text_interline,[num2str(eNodeBs(b_).id)]);
end

xlim(handles.axes2,xlim(handles.axes2).*1.1);
ylim(handles.axes2,ylim(handles.axes2)*1.1);

% Plot all other UEs in a shade of gray
for u_=1:length(UEs)
    if u_~=UE_idx
        scatter(handles.axes2,UEs(u_).pos(1),UEs(u_).pos(2),'Marker','.','MarkerFaceColor',[128 128 128]/256,'MarkerEdgeColor',[128 128 128]/256,'SizeData',300);
    end
end

% Plot selected UEs path
scatter(handles.axes2,simulation_traces.UE_traces(UE_idx).position(1,:),simulation_traces.UE_traces(UE_idx).position(2,:),'Marker','.','MarkerFaceColor','red','MarkerEdgeColor','red','SizeData',10);

% Plot selected UE
scatter(handles.axes2,UEs(UE_idx).pos(1),UEs(UE_idx).pos(2),'Marker','.','MarkerFaceColor','black','MarkerEdgeColor','black','SizeData',300);
%grid(handles.axes2,'on');
box(handles.axes2,'on');
title(handles.axes2,sprintf('UE %d position',get(handles.listbox1,'Value')));
grid(handles.axes2,'on');

function trace_UE_CQIs_hist(handles,UE_idx,RB_idx,stream_number)

user_data = get(handles.figure1,'UserData');
LTE_config = user_data.LTE_config;
simulation_traces = user_data.simulation_traces;

trace_length = size(simulation_traces.UE_traces(1).ACK,2);

cla(handles.axes3);
% Sent CQI
[a b]   = hist(double(squeeze(simulation_traces.UE_traces(UE_idx).CQI_sent(stream_number,RB_idx,:)))',(0:15));
% TB SQI
[a2 b2] = hist(double(squeeze(simulation_traces.UE_traces(UE_idx).TB_CQI(stream_number,:))),(0:15));
bar(handles.axes3,b,[a' a2'],1);
set(handles.axes3,'XTick',0:15);
xlim(handles.axes3,[-0.5 15.5]);
xlabel(handles.axes3,{'CQI'});
box(handles.axes3,'on');
grid(handles.axes3,'on');
title(handles.axes3,sprintf('CQI distribution, UE %d, RB %d',UE_idx,RB_idx));

function trace_UE_throughput(handles,UE_idx,stream_number)

user_data = get(handles.figure1,'UserData');
LTE_config = user_data.LTE_config;
simulation_traces = user_data.simulation_traces;

correctly_received_TB_sizes = double(simulation_traces.UE_traces(UE_idx).ACK(stream_number,:)) .* double(simulation_traces.UE_traces(UE_idx).TB_size(stream_number,:));
windowSize_throughput = floor(str2double(get(handles.edit1,'String')));
windowSize_bler = floor(str2double(get(handles.edit2,'String')));

correctly_received_TB_sizes_moving_avg = filter(ones(1,windowSize_throughput)/windowSize_throughput,1,correctly_received_TB_sizes);
throughput = correctly_received_TB_sizes_moving_avg / LTE_config.TTI_length / 1000000;
valid_entries = simulation_traces.UE_traces(UE_idx).TB_size(stream_number,:)~=0;

% Empirical BLER
empirical_BLER = filter(ones(1,windowSize_bler)/windowSize_bler,1,~(simulation_traces.UE_traces(UE_idx).ACK(stream_number,:)) & valid_entries);

% Used BLER
used_BLER = simulation_traces.UE_traces(UE_idx).BLER(stream_number,:);
used_BLER = filter(ones(1,windowSize_bler)/windowSize_bler,1,simulation_traces.UE_traces(UE_idx).BLER(stream_number,:));

trace_length = size(simulation_traces.UE_traces(1).ACK,2);
x_axis_s = (1:trace_length) * LTE_config.TTI_length;

cla(handles.axes5);
[AX,H1,H2] = plotyy(handles.axes5,x_axis_s,throughput,x_axis_s,empirical_BLER);
set(AX(2),'YScale','linear');
grid(handles.axes5,'minor');
hold(AX(2),'on');
plot(AX(2),x_axis_s,used_BLER,'Color','black');%[159 173 112]/256
hold(AX(2),'off');

xlabel(handles.axes5,{'t [s]'});
set(get(AX(1),'Ylabel'),'String','throughput [Mbps]');
set(get(AX(2),'Ylabel'),'String','BLER');
set(AX(2),'ylim',[0 1.1]);
set(AX(2),'YTick',[0:0.1:1]);
%ylabel(handles.axes5,{'throughput [Mbps]'});
title(handles.axes5,sprintf('Throughput and BLER report, UE %d, stream %d (Average: Throughput %d TTIs, BLER %d TTIs)',UE_idx,stream_number,windowSize_throughput,windowSize_bler));
box(handles.axes5,'on');
grid(handles.axes5,'on');

% figure;
% cdfplot(throughput);



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double
user_entry = floor(str2double(get(hObject,'string')));
if isnan(user_entry)
	errordlg('You must enter a numeric value','Bad Input','modal')
	return
end
set(hObject,'string',num2str(user_entry));
UE_idx = get(handles.listbox1,'Value');
stream_idx = get(handles.listbox3,'Value');
trace_UE_throughput(handles,UE_idx,stream_idx);


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double
user_entry = floor(str2double(get(hObject,'string')));
if isnan(user_entry)
	errordlg('You must enter a numeric value','Bad Input','modal')
	return
end
set(hObject,'string',num2str(user_entry));
UE_idx = get(handles.listbox1,'Value');
stream_idx = get(handles.listbox3,'Value');
trace_UE_throughput(handles,UE_idx,stream_idx);

% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox3.
function listbox3_Callback(hObject, eventdata, handles)
% hObject    handle to listbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listbox3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox3
UE_idx = get(handles.listbox1,'Value');
stream_idx = get(handles.listbox3,'Value');
RB_idx = get(handles.listbox2,'Value');
trace_UE_CQIs(handles,UE_idx,RB_idx,stream_idx);
trace_UE_CQIs_hist(handles,UE_idx,RB_idx,stream_idx);
trace_UE_throughput(handles,UE_idx,stream_idx);

% --- Executes during object creation, after setting all properties.
function listbox3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double
user_entry = floor(str2double(get(hObject,'string')));
if isnan(user_entry)
	errordlg('You must enter a numeric value','Bad Input','modal')
	return
end
set(hObject,'string',num2str(user_entry));
UE_idx = get(handles.listbox1,'Value');
RB_idx = get(handles.listbox2,'Value');
stream_idx = get(handles.listbox3,'Value');
trace_UE_CQIs(handles,UE_idx,RB_idx,stream_idx)

% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
