function varargout = app(varargin)
% APP MATLAB code for app.fig
%      APP, by itself, creates a new APP or raises the existing
%      singleton*.
%
%      H = APP returns the handle to a new APP or the handle to
%      the existing singleton*.
%
%      APP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in APP.M with the given input arguments.
%
%      APP('Property','Value',...) creates a new APP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before app_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to app_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help app

% Last Modified by GUIDE v2.5 22-Apr-2015 17:52:11

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @app_OpeningFcn, ...
                   'gui_OutputFcn',  @app_OutputFcn, ...
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


% --- Executes just before app is made visible.
function app_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to app (see VARARGIN)

% Choose default command line output for app
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes app wait for user response (see UIRESUME)
% uiwait(handles.figure1);



% --- Outputs from this function are returned to the command line.
function varargout = app_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
appdata = get(0,'ApplicationData');

fns = fieldnames(appdata);
for ii = 1:numel(fns)
  rmappdata(0,fns{ii});
end
[FileName,PathName] = uigetfile('*.jpg','Select an image of a book shelf', '..\sample images');
image = imread(strcat(PathName,FileName));
setappdata(0,'image',image);
imshow(image, 'Parent', handles.axes1);
set(handles.showOriginal,'Enable','on');
set(handles.locateSpines,'Enable','on');
set(handles.recText,'Enable','off');
set(handles.findWordsWithMerge,'Enable','off');
set(handles.findWordsNoMerge,'Enable','off');
set(handles.spinesListbox,'Enable','off');
set(handles.showSpine,'Enable','off');
set(handles.showOriginalSpine,'Enable','off');
set(handles.segmentTextRemNoise,'Enable','off');
set(handles.segmentTextNoRemNoise,'Enable','off');



% --- Executes on button press in locateSpines.
function locateSpines_Callback(hObject, eventdata, handles)
% hObject    handle to locateSpines (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isappdata(0, 'spines_img')
    spines_arr = getappdata(0, 'spines_arr');
    imshow(getappdata(0, 'spines_img'), 'Parent', handles.axes1);
else
    image = getappdata(0,'image');
    [spines_image, spines_arr] = separateSpines(image);
    setappdata(0, 'spines_arr', spines_arr);
    setappdata(0, 'spines_img', spines_image);
    imshow(spines_image, 'Parent', handles.axes1);
end
numOfSpines = numel(spines_arr);
data = num2cell([1:numOfSpines]);
set(handles.spinesListbox,'String',data);
set(handles.spinesListbox,'Enable','on');
set(handles.showSpine,'Enable','on');


% --- Executes on button press in segmentTextNoNoise.
function segmentTextNoNoise_Callback(hObject, eventdata, handles)
% hObject    handle to segmentTextNoNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isappdata(0, 'seg_spines_img1')
    seg_spines_image = getappdata(0,'seg_spines_img1');
    imshow(seg_spines_image, 'Parent', handles.axes1);
    return;
end

if ~isappdata(0, 'spines_arr') 
    image = getappdata(0,'image');
    [~, spines_arr] = separateSpines(image);
else
    spines_arr = getappdata(0, 'spines_arr');
end

[seg_spines_image, seg_spines_arr] = segmentText(spines_arr, 0);
setappdata(0, 'seg_spines_img1', seg_spines_image);
setappdata(0, 'seg_spines_arr1', seg_spines_arr);
setappdata(0, 'seg_spines_img_last', seg_spines_image);
setappdata(0, 'seg_spines_arr_last', seg_spines_arr);
imshow(seg_spines_image, 'Parent', handles.axes1);


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in showOriginal.
function showOriginal_Callback(hObject, eventdata, handles)
% hObject    handle to showOriginal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
image = getappdata(0,'image');
imshow(image, 'Parent', handles.axes1);


% --- Executes on button press in findWords2.
function findWords2_Callback(hObject, eventdata, handles)
% hObject    handle to findWords2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isappdata(0, 'word_spines_img2')
    word_spines_img = getappdata(0,'word_spines_img2');
    imshow(word_spines_img, 'Parent', handles.axes1);
    return;
end

% If the spines weren't separated yet - do it now
if ~isappdata(0, 'spines_arr') 
    image = getappdata(0,'image');
    [spines_image, spines_arr] = separateSpines(image);
    setappdata(0, 'spines_arr', spines_arr);
    setappdata(0, 'spines_img', spines_image);
else
    spines_arr = getappdata(0, 'spines_arr');
end

% If the spines weren't segmented yet - do it now
if ~isappdata(0, 'seg_spines_arr_last')
    [seg_spines_image, seg_spines_arr] = segmentText(spines_arr,1);
    setappdata(0, 'seg_spines_img2', seg_spines_image);
    setappdata(0, 'seg_spines_arr2', seg_spines_arr);
    setappdata(0, 'seg_spines_img_last', seg_spines_image);
    setappdata(0, 'seg_spines_arr_last', seg_spines_arr);
else
    seg_spines_arr = getappdata(0,'seg_spines_arr_last');
end

[word_spines_image, word_spines_arr] = findWords(seg_spines_arr, 1);
imshow(word_spines_image, 'Parent', handles.axes1);
setappdata(0, 'word_spines_arr2', word_spines_arr);
setappdata(0, 'word_spines_img2', word_spines_image);
setappdata(0, 'word_spines_arr_last', word_spines_arr);
setappdata(0, 'word_spines_img_last', word_spines_image)

% --- Executes on button press in findWords1.
function findWords1_Callback(hObject, eventdata, handles)
% hObject    handle to findWords1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isappdata(0, 'word_spines_img1')
    word_spines_img = getappdata(0,'word_spines_img1');
    imshow(word_spines_img, 'Parent', handles.axes1);
    return;
end

% If the spines weren't separated yet - do it now
if ~isappdata(0, 'spines_arr') 
    image = getappdata(0,'image');
    [spines_image, spines_arr] = separateSpines(image);
    setappdata(0, 'spines_arr', spines_arr);
    setappdata(0, 'spines_img', spines_image);
else
    spines_arr = getappdata(0, 'spines_arr');
end

% If the spines weren't segmented yet - do it now
if ~isappdata(0, 'seg_spines_arr_last')
    [seg_spines_image, seg_spines_arr] = segmentText(spines_arr,1);
    setappdata(0, 'seg_spines_img2', seg_spines_image);
    setappdata(0, 'seg_spines_arr2', seg_spines_arr);
    setappdata(0, 'seg_spines_img_last', seg_spines_image);
    setappdata(0, 'seg_spines_arr_last', seg_spines_arr);
else
    seg_spines_arr = getappdata(0,'seg_spines_arr_last');
end

[word_spines_image, word_spines_arr] = findWords(seg_spines_arr, 0);
imshow(word_spines_image, 'Parent', handles.axes1);
setappdata(0, 'word_spines_arr1', word_spines_arr);
setappdata(0, 'word_spines_img1', word_spines_image);
setappdata(0, 'word_spines_arr_last', word_spines_arr);
setappdata(0, 'word_spines_img_last', word_spines_image);


% --- Executes on button press in segmentTextWithNoise.
function segmentTextWithNoise_Callback(hObject, eventdata, handles)
% hObject    handle to segmentTextWithNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isappdata(0, 'seg_spines_img2')
    seg_spines_image = getappdata(0,'seg_spines_img2');
    imshow(seg_spines_image, 'Parent', handles.axes1);
    return;
end

if ~isappdata(0, 'spines_arr') 
    image = getappdata(0,'image');
    [~, spines_arr] = separateSpines(image);
    setappdata(0, 'spines_arr', spines_arr);
    
else
    spines_arr = getappdata(0, 'spines_arr');
end

[seg_spines_image, seg_spines_arr] = segmentText(spines_arr, 1);
setappdata(0, 'seg_spines_img2', seg_spines_image);
setappdata(0, 'seg_spines_arr2', seg_spines_arr);
setappdata(0, 'seg_spines_img_last', seg_spines_image);
setappdata(0, 'seg_spines_arr_last', seg_spines_arr);
imshow(seg_spines_image, 'Parent', handles.axes1);


% --- Executes on button press in showOriginalSpine.
function showOriginalSpine_Callback(hObject, eventdata, handles)
% hObject    handle to showOriginalSpine (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
spine = getappdata(0, 'selected_spine');
spine = imrotate(spine, 90);
imshow(spine, 'Parent', handles.axes1);


% --- Executes on button press in findWordsNoMerge.
function findWordsNoMerge_Callback(hObject, eventdata, handles)
% hObject    handle to findWordsNoMerge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
seg_spine = getappdata(0, 'segmented_spine');
[w_spine, word_stat] = findWords(seg_spine, 0);
w_spine = imrotate(w_spine, 90);
imshow(w_spine, 'Parent', handles.axes1);
setappdata(0, 'word_stat', word_stat);
set(handles.recText,'Enable','on');

% --- Executes on button press in findWordsWithMerge.
function findWordsWithMerge_Callback(hObject, eventdata, handles)
% hObject    handle to findWordsWithMerge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
seg_spine = getappdata(0, 'segmented_spine');
[w_spine, word_stat] = findWords(seg_spine, 1);
w_spine = imrotate(w_spine, 90);
imshow(w_spine, 'Parent', handles.axes1);
setappdata(0, 'word_stat', word_stat);
set(handles.recText,'Enable','on');


% --- Executes on selection change in spinesListbox.
function spinesListbox_Callback(hObject, eventdata, handles)
% hObject    handle to spinesListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns spinesListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from spinesListbox


% --- Executes during object creation, after setting all properties.
function spinesListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to spinesListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in showSpine.
function showSpine_Callback(hObject, eventdata, handles)
% hObject    handle to showSpine (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
spines_arr = getappdata(0, 'spines_arr');
spine_index = get(handles.spinesListbox,'Value');
spine_list = get(handles.spinesListbox,'String');
selected_spine = str2double(spine_list(spine_index));
spine = spines_arr{selected_spine};
setappdata(0, 'selected_spine', spine);
spine = imrotate(spine, 90);
imshow(spine, 'Parent', handles.axes1);
set(handles.showOriginalSpine,'Enable','on');
set(handles.segmentTextRemNoise,'Enable','on');
set(handles.segmentTextNoRemNoise,'Enable','on');
set(handles.recText,'Enable','off');
set(handles.findWordsWithMerge,'Enable','off');
set(handles.findWordsNoMerge,'Enable','off');



% --- Executes on button press in segmentTextNoRemNoise.
function segmentTextNoRemNoise_Callback(hObject, eventdata, handles)
% hObject    handle to segmentTextNoRemNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
spine = getappdata(0, 'selected_spine');
seg_spine = segmentText(spine, 0);
setappdata(0, 'segmented_spine', seg_spine);
seg_spine = imrotate(seg_spine, 90);
imshow(seg_spine, 'Parent', handles.axes1);
set(handles.findWordsNoMerge,'Enable','on');
set(handles.findWordsWithMerge,'Enable','on');
set(handles.recText,'Enable','off');


% --- Executes on button press in segmentTextRemNoise.
function segmentTextRemNoise_Callback(hObject, eventdata, handles)
% hObject    handle to segmentTextRemNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
spine = getappdata(0, 'selected_spine');
seg_spine = segmentText(spine, 1);
setappdata(0, 'segmented_spine', seg_spine);
seg_spine = imrotate(seg_spine, 90);
imshow(seg_spine, 'Parent', handles.axes1);
set(handles.findWordsNoMerge,'Enable','on');
set(handles.findWordsWithMerge,'Enable','on');
set(handles.recText,'Enable','off');


% --- Executes on button press in recText.
function recText_Callback(hObject, eventdata, handles)
% hObject    handle to recText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
seg_spine = getappdata(0, 'segmented_spine');
word_stat = getappdata(0, 'word_stat');
text = recognizeText(seg_spine, word_stat);
set(handles.spineText, 'Visible', 'on');
set(handles.spineText, 'String', text);
