function varargout = LTE_GUI_show_cell_traces(varargin)
% LTE_GUI_SHOW_CELL_TRACES M-file for LTE_GUI_show_cell_traces.fig
%      LTE_GUI_SHOW_CELL_TRACES, by itself, creates a new LTE_GUI_SHOW_CELL_TRACES or raises the existing
%      singleton*.
%
%      H = LTE_GUI_SHOW_CELL_TRACES returns the handle to a new LTE_GUI_SHOW_CELL_TRACES or the handle to
%      the existing singleton*.
%
%      LTE_GUI_SHOW_CELL_TRACES('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LTE_GUI_SHOW_CELL_TRACES.M with the given input arguments.
%
%      LTE_GUI_SHOW_CELL_TRACES('Property','Value',...) creates a new LTE_GUI_SHOW_CELL_TRACES or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before LTE_GUI_show_cell_traces_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to LTE_GUI_show_cell_traces_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help LTE_GUI_show_cell_traces

% Last Modified by GUIDE v2.5 08-Jul-2009 15:36:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @LTE_GUI_show_cell_traces_OpeningFcn, ...
                   'gui_OutputFcn',  @LTE_GUI_show_cell_traces_OutputFcn, ...
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


% --- Executes just before LTE_GUI_show_cell_traces is made visible.
function LTE_GUI_show_cell_traces_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LTE_GUI_show_cell_traces (see VARARGIN)

% Choose default command line output for LTE_GUI_show_cell_traces
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
nr_eNodeBs = length(application_data.simulation_traces.eNodeB_tx_traces);

if nr_eNodeBs>0
    for i_=1:nr_eNodeBs
        eNodeB_list{i_} = num2str(i_);
    end
    nr_sectors = length(eNodeBs(1).sectors);
    for i_=1:nr_sectors
        sector_list{i_} = num2str(i_);
    end
    for i_=1:LTE_config.maxStreams
        number_of_streams{i_} = num2str(i_);
    end

    set(handles.listbox1,'String',eNodeB_list);
    set(handles.listbox2,'String',sector_list);
    set(handles.listbox3,'String',number_of_streams);
    set(handles.slider1,'Min',1);
    set(handles.slider1,'Value',1);
    set(handles.slider1,'Max',LTE_config.simulation_time_tti);
    plot_RB_grid(handles,1,1,1,1);
    plot_assigned_RBs(handles,1,1,1,50,1);
    plot_eNodeB_throughput(handles,1,1,1);
    plot_eNodeBs_and_UE_pos(handles,1,1);
end

% UIWAIT makes LTE_GUI_show_cell_traces wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = LTE_GUI_show_cell_traces_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
time_tti = floor(get(hObject,'Value'));
%set(hObject,'Value',time_tti);
time_tti_str = num2str(time_tti,'%d');
set(handles.edit1,'String',time_tti_str);

eNodeB_idx = get(handles.listbox1,'Value');
sector_idx = get(handles.listbox2,'Value');
stream_idx = get(handles.listbox3,'Value');
TTI_num = floor(get(handles.slider1,'Value'));
plot_RB_grid(handles,eNodeB_idx,sector_idx,TTI_num,stream_idx);


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double
time_tti = str2double(get(hObject,'String'));
if isnan(time_tti)
	errordlg('You must enter a numeric value','Bad Input','modal')
	return
end
time_tti = floor(time_tti);
if time_tti < get(handles.slider1,'Min')
    time_tti = get(handles.slider1,'Min');
elseif time_tti > get(handles.slider1,'Max')
    time_tti = get(handles.slider1,'Max');
end
set(hObject,'String',num2str(time_tti));
set(handles.slider1,'Value',time_tti);

eNodeB_idx = get(handles.listbox1,'Value');
sector_idx = get(handles.listbox2,'Value');
stream_idx = get(handles.listbox3,'Value');
TTI_num = floor(get(handles.slider1,'Value'));
plot_RB_grid(handles,eNodeB_idx,sector_idx,TTI_num,stream_idx);

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


% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1
user_data = get(handles.figure1,'UserData');
eNodeBs = user_data.eNodeBs;
eNodeB_idx = str2double(get(hObject,'String'));
sectors = eNodeBs(eNodeB_idx).sectors;
nr_sectors = length(sectors);
for i_=1:nr_sectors
    sector_list{i_} = num2str(i_);
end
set(handles.listbox2,'String',sector_list);

eNodeB_idx = get(handles.listbox1,'Value');
sector_idx = get(handles.listbox2,'Value');
stream_idx = get(handles.listbox3,'Value');
TTI_num = floor(get(handles.slider1,'Value'));

start_TTI = str2double(get(handles.edit2,'String'));
end_TTI   = str2double(get(handles.edit3,'String'));
if isnan(start_TTI) || isnan(end_TTI)
	errordlg('You must enter a numeric value','Bad Input','modal')
	return
end

plot_RB_grid(handles,eNodeB_idx,sector_idx,TTI_num,stream_idx);
plot_assigned_RBs(handles,eNodeB_idx,sector_idx,start_TTI,end_TTI,stream_idx);
plot_eNodeB_throughput(handles,eNodeB_idx,sector_idx,stream_idx);
plot_eNodeBs_and_UE_pos(handles,eNodeB_idx,sector_idx);


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

function plot_RB_grid(handles,eNodeB_idx,sector_idx,TTI_num,stream_number)
user_data = get(handles.figure1,'UserData');
LTE_config = user_data.LTE_config;
simulation_traces = user_data.simulation_traces;
UEs = user_data.UEs;
eNodeBs = user_data.eNodeBs;
%the_colormap = hsv(length(UEs));
%the_colormap = [the_colormap;0 0 0];

the_RB_grid = simulation_traces.eNodeB_tx_traces(eNodeB_idx).sector_traces(sector_idx).user_allocation(:,TTI_num);
% Show empty spaces as black spaces
% the_RB_grid(the_RB_grid==0) = max(max(the_RB_grid))+1;

axes(handles.axes1);
imagesc(double(the_RB_grid));
set(handles.axes1,'XTick',[]);
the_colormap = colormap('jet');
colorbar();
ylabel('RB number');
title(handles.axes1,sprintf('RB grid, eNodeB %d, sector %d, stream %d TTI %d',eNodeB_idx,sector_idx,stream_number,TTI_num));

% --- Executes on selection change in listbox2.
function listbox2_Callback(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listbox2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox2
eNodeB_idx = get(handles.listbox1,'Value');
sector_idx = get(handles.listbox2,'Value');
stream_idx = get(handles.listbox3,'Value');
TTI_num = floor(get(handles.slider1,'Value'));

start_TTI = str2double(get(handles.edit2,'String'));
end_TTI   = str2double(get(handles.edit3,'String'));
if isnan(start_TTI) || isnan(end_TTI)
	errordlg('You must enter a numeric value','Bad Input','modal')
	return
end

plot_RB_grid(handles,eNodeB_idx,sector_idx,TTI_num,stream_idx);
plot_assigned_RBs(handles,eNodeB_idx,sector_idx,start_TTI,end_TTI,stream_idx);
plot_eNodeB_throughput(handles,eNodeB_idx,sector_idx,stream_idx);
plot_eNodeBs_and_UE_pos(handles,eNodeB_idx,sector_idx);


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

function plot_assigned_RBs(handles,eNodeB_idx,sector_idx,start_TTI,end_TTI,stream_num)
user_data = get(handles.figure1,'UserData');
LTE_config = user_data.LTE_config;
simulation_traces = user_data.simulation_traces;
UEs = user_data.UEs;
eNodeBs = user_data.eNodeBs;

TTIs_to_plot = start_TTI:end_TTI;
allocation_grid_to_plot = squeeze(simulation_traces.eNodeB_tx_traces(eNodeB_idx).sector_traces(sector_idx).user_allocation(:,TTIs_to_plot));
user_list = unique(allocation_grid_to_plot);

allocated_RBs = zeros(length(user_list),length(TTIs_to_plot));

for u_=1:length(user_list)
    allocated_RBs(u_,:) = squeeze(sum(allocation_grid_to_plot==user_list(u_),1));
end
cla(handles.axes2);
plot(handles.axes2,TTIs_to_plot,allocated_RBs);
grid(handles.axes2,'on');
box(handles.axes2,'on');
ylim(handles.axes2,'auto');
actual_y_limits = ylim(handles.axes2);
axis_resize = 0.3;
ylim(handles.axes2,actual_y_limits.*[1-axis_resize/5 1+axis_resize/5]);
for u_=1:length(user_list)
    legend_text{u_} = sprintf('UE %d',user_list(u_));
end
if length(user_list)>0
    legend(handles.axes2,'Location','NorthEastOutside',legend_text);
end
title(handles.axes2,sprintf('Assigned RBs, eNodeB %d, sector %d, stream %d',eNodeB_idx,sector_idx,stream_num));
xlabel(handles.axes2,'TTI number');
ylabel(handles.axes2,'Assigned RBs');

function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double
start_TTI = str2double(get(handles.edit2,'String'));
end_TTI   = str2double(get(handles.edit3,'String'));
if isnan(start_TTI) || isnan(end_TTI)
	errordlg('You must enter a numeric value','Bad Input','modal')
	return
end
if start_TTI < get(handles.slider1,'Min')
    start_TTI = get(handles.slider1,'Min');
    set(handles.edit2,'String',num2str(start_TTI));
elseif start_TTI > get(handles.slider1,'Max')
    start_TTI = get(handles.slider1,'Max');
    set(handles.edit2,'String',num2str(start_TTI));
end

eNodeB_idx = get(handles.listbox1,'Value');
sector_idx = get(handles.listbox2,'Value');
stream_idx = get(handles.listbox3,'Value');
plot_assigned_RBs(handles,eNodeB_idx,sector_idx,start_TTI,end_TTI,stream_idx);


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



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double
start_TTI = str2double(get(handles.edit2,'String'));
end_TTI   = str2double(get(handles.edit3,'String'));
if isnan(start_TTI) || isnan(end_TTI)
	errordlg('You must enter a numeric value','Bad Input','modal')
	return
end
if end_TTI < get(handles.slider1,'Min')
    end_TTI = get(handles.slider1,'Min');
    set(handles.edit3,'String',num2str(end_TTI));
elseif end_TTI > get(handles.slider1,'Max')
    end_TTI = get(handles.slider1,'Max');
    set(handles.edit3,'String',num2str(end_TTI));
end

eNodeB_idx = get(handles.listbox1,'Value');
sector_idx = get(handles.listbox2,'Value');
stream_idx = get(handles.listbox3,'Value');
plot_assigned_RBs(handles,eNodeB_idx,sector_idx,start_TTI,end_TTI,stream_idx);


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

function plot_eNodeB_throughput(handles,eNodeB_idx,sector_idx,stream_num)
user_data = get(handles.figure1,'UserData');
LTE_config = user_data.LTE_config;
simulation_traces = user_data.simulation_traces;
windowSize_throughput = floor(str2double(get(handles.edit4,'String')));
windowSize_bler = floor(str2double(get(handles.edit5,'String')));

sent_data = double(simulation_traces.eNodeB_tx_traces(eNodeB_idx).sector_traces(sector_idx).sent_data(stream_num,:));
acknowledged_data = double(simulation_traces.eNodeB_tx_traces(eNodeB_idx).sector_traces(sector_idx).acknowledged_data(stream_num,:));
received_ACKs = double(simulation_traces.eNodeB_tx_traces(eNodeB_idx).sector_traces(sector_idx).received_ACKs(stream_num,:));
expected_ACKs = double(simulation_traces.eNodeB_tx_traces(eNodeB_idx).sector_traces(sector_idx).expected_ACKs(stream_num,:));
missing_ACKs  = expected_ACKs - received_ACKs;
BLER = missing_ACKs ./ expected_ACKs;

correctly_received_TB_sizes_moving_avg = filter(ones(1,windowSize_throughput)/windowSize_throughput,1,acknowledged_data);
throughput = correctly_received_TB_sizes_moving_avg / LTE_config.TTI_length / 1000000;
BLER = filter(ones(1,windowSize_bler)/windowSize_bler,1,BLER);

x_axis_s = (1:LTE_config.simulation_time_tti) * LTE_config.TTI_length;

cla(handles.axes3);
[AX,H1,H2] = plotyy(handles.axes3,x_axis_s,throughput,x_axis_s,BLER);

grid(handles.axes3,'minor');
xlabel(handles.axes3,{'t [s]'});
set(get(AX(1),'Ylabel'),'String','throughput [Mbps]');
set(get(AX(2),'Ylabel'),'String','BLER');
set(AX(2),'ylim',[0 1.1]);
set(AX(2),'YTick',[0:0.1:1]);
%ylabel(handles.axes5,{'throughput [Mbps]'});
title(handles.axes3,sprintf('Throughput and BLER report, eNodeB %d, sector %d, stream %d\n(Average: Throughput %d TTIs, BLER %d TTIs)',eNodeB_idx,sector_idx,stream_num,windowSize_throughput,windowSize_bler));
box(handles.axes3,'on');
grid(handles.axes3,'on');

% figure;
% cdfplot(throughput);

function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double
user_entry = floor(str2double(get(hObject,'string')));
if isnan(user_entry)
	errordlg('You must enter a numeric value','Bad Input','modal')
	return
end
set(hObject,'string',num2str(user_entry));
eNodeB_idx = get(handles.listbox1,'Value');
sector_idx = get(handles.listbox2,'Value');
stream_idx = get(handles.listbox3,'Value');
plot_eNodeB_throughput(handles,eNodeB_idx,sector_idx,stream_idx);


% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double
user_entry = floor(str2double(get(hObject,'string')));
if isnan(user_entry)
	errordlg('You must enter a numeric value','Bad Input','modal')
	return
end
set(hObject,'string',num2str(user_entry));
eNodeB_idx = get(handles.listbox1,'Value');
sector_idx = get(handles.listbox2,'Value');
stream_idx = get(handles.listbox3,'Value');
plot_eNodeB_throughput(handles,eNodeB_idx,sector_idx,stream_idx);


% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function plot_eNodeBs_and_UE_pos(handles,eNodeB_idx,sector_idx)

user_data = get(handles.figure1,'UserData');
LTE_config = user_data.LTE_config;
simulation_traces = user_data.simulation_traces;
eNodeBs = user_data.eNodeBs;
UEs =  user_data.UEs;

cla(handles.axes5);
hold(handles.axes5,'on');
xlim(handles.axes5,'auto')
ylim(handles.axes5,'auto')
text_shifting = 2.5;
text_interline = 2.5;
axes(handles.axes5);

% Plot eNodeB UEs (at the last TTI)
for u_=1:length(UEs)
    if (UEs(u_).attached_eNodeB.id==eNodeB_idx) && (UEs(u_).attached_sector==sector_idx)
        scatter(handles.axes5,UEs(u_).pos(1),UEs(u_).pos(2),'Marker','.','MarkerFaceColor','black','MarkerEdgeColor','black','SizeData',300);
    else
        scatter(handles.axes5,UEs(u_).pos(1),UEs(u_).pos(2),'Marker','.','MarkerFaceColor',[128 128 128]/256,'MarkerEdgeColor',[128 128 128]/256,'SizeData',300);
    end
end

% Plot eNodeBs
for b_=1:length(eNodeBs)
    % Plot a line that tells where the antennas are pointing
    vector_length = 100;
    origin = eNodeBs(b_).pos;
    for s_=1:length(eNodeBs(b_).sectors)
        angle = wrapTo360(-eNodeBs(b_).sectors(s_).azimuth+90);
        vector = vector_length*[ cosd(angle) sind(angle) ];
        destiny = vector + origin;

        plot(handles.axes5,[origin(1) destiny(1)],[origin(2) destiny(2)]);
    end
    % Plot the eNodeBs
    scatter(handles.axes5,eNodeBs(b_).pos(1),eNodeBs(b_).pos(2),'Marker','o','MarkerFaceColor','red','MarkerEdgeColor','black');
    text(eNodeBs(b_).pos(1)+15*text_shifting,eNodeBs(b_).pos(2)+15*text_interline,[num2str(eNodeBs(b_).id)]);
end

xlim(handles.axes5,xlim(handles.axes5).*1.1);
ylim(handles.axes5,ylim(handles.axes5)*1.1);

%grid(handles.axes5,'on');
box(handles.axes5,'on');
grid(handles.axes5,'on');


% --- Executes on selection change in listbox3.
function listbox3_Callback(hObject, eventdata, handles)
% hObject    handle to listbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listbox3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox3
eNodeB_idx = get(handles.listbox1,'Value');
sector_idx = get(handles.listbox2,'Value');
stream_idx = get(handles.listbox3,'Value');
TTI_num = floor(get(handles.slider1,'Value'));

start_TTI = str2double(get(handles.edit2,'String'));
end_TTI   = str2double(get(handles.edit3,'String'));
if isnan(start_TTI) || isnan(end_TTI)
	errordlg('You must enter a numeric value','Bad Input','modal')
	return
end

plot_RB_grid(handles,eNodeB_idx,sector_idx,TTI_num,stream_idx);
plot_assigned_RBs(handles,eNodeB_idx,sector_idx,start_TTI,end_TTI,stream_idx);
plot_eNodeB_throughput(handles,eNodeB_idx,sector_idx,stream_idx);
plot_eNodeBs_and_UE_pos(handles,eNodeB_idx,sector_idx);

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
