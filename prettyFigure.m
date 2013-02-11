function prettyFigure(inarg, style, varargin)
% PRETTYFIGURE -- Making readable, aesthetically pleasing figures of
% images.
%
% The goal of writing this function is to display nice figures for a given
% set of images with big titles, etc.
% 
% This function offers the user the opportunity to display figures with
% grid-style imaging, a major title, saving (and cropping) the figure to
% various file types, and more.
%
% All odd number arguments in varargin should be strings specified by the
% functions set of usuable switches
%
%
% 1. Switches
%-----------------------------------
%   To use this function, there must be several switches that are active,
%   which relate to the fact that we need at LEAST the images and the style
%   for how to show them. The major title, subplot title(s), etc. are
%   unncessary.
% 
%   1a. Necessary Switches
%-----------------------------------
%   'Images', im{} -- Images followed by their respective images in a cell
%   array, preferrably (n x 1), but resizing will be taken care of
% 
%   'Style', [row col] or 'grid' -- Images will be laid out in either a
%   (row x col) format, or in a grid (default) form.
%
%   1b. Extra Switches
%-----------------------------------
%   'MajorTitle', title -- Specifies the title that will hang over all the
%   subplots in the figure
%
%   'SubTitle', subtitles{} -- Cell array of strings specifying what you
%   want the subtitles to be
%
%   'Split', nsplit, -- Split the figure into multiple figures based on the
%   input size. Best used when using a predefined size.

% All pre-defined switches
known_switches  = {'MajorTitle', 'SubTitle', 'Split', 'FigName', ...
                   'Position', 'Crop', 'Save'};
known_positions = {'v2', 'h2', 'q', 'f'};

% Flags
mt_isOn         = 0;    % MajorTitle      -- Default:off
st_isOn         = 0;    % SubTitle        -- Default:off
split_isOn      = 0;    % Defined Split   -- Default:off
fname_isOn      = 0;    % Figure Name     -- Default:off
grid_isOn       = 1;    % Use auto-grid   -- Default:on
position_isOn   = 0;    % Figure Position -- Default:off
crop_isOn       = 1;    % Crop figure     -- Default:off
save_isOn       = 0;    % Save figure     -- Default:off

% Fields
nsplits = 1; % Just one figure by default.
ss_x = 0;
ss_y = 0;

% Entry handling
if mod(nargin,2) ~= 0   % Balanced switches
    error(numSwitchError, strcat('The number of switches hasn''t been', ...
        ' input correctly. Please verify and try again'));
end

if ~iscell(inarg)       % Check if first argument is a cell array
    error(inArgError, strcat('Error with inarg. Please make sure the input', ...
        ' files/handles to plot are in a cell array.'));
end

inarg_length = length(inarg); %Now that inarg is validated, calc length.

if ~isempty(style) && ~ischar(style) && isnumeric(style)   % If style a defined size..
    grid_isOn = 0;% Disable the grid
    ss_x = style(1);
    ss_y = style(2);
    
    if size(style) ~= 2 % ...but not (x,y)...
        error(styleSizeError,strcat('Size should be a 1x2 or 2x1 matrix of x', ... 
           ' and y values.'));
    end%end if
    
    if ss_x > ss_y      % Transpose if needed.
        style = style';
    end%end if
elseif isempty(style) || strcmpi(style, 'grid')
    ss_x = ceil(sqrt(length(inarg)));
    ss_y = ceil(length(inarg) / ss_x);
end%end if

% Parse switches
if ~isempty(varargin)
    for i = 1:2:length(varargin)        % Check the switches.
        %if ~switchExists(varargin{i})  % If a switch doesn't exist, return error.
        if ~strcmpi(varargin{i}, cat(1,known_switches', known_positions'))
            error(switchNotExist, strcat('The switch "', varargin{i}, '" is', ...
                ' not a recognized switch.'));
        else                            % Otherwise, properly set it
            switch varargin{i}          % Turn on the specifed switches
                case 'MajorTitle'
                    mt_isOn     = 1;    
                    majorTitle  = varargin{i+1};
                case 'SubTitle'
                    st_isOn     = 1;
                    subTitles   = varargin{i+1};
                case 'FigName'
                    fname_isOn  = 1;
                    figName     = varargin{i+1};
                case 'Split'
                    split_isOn  = 1;
                    if isinteger(varargin{i})
                        nsplits = varargin{i+1};
                    elseif ~strcmpi(varargin{i}, 'auto')
                        error(splitAutoError, strcat('Figure splitting ',...
                            'should be an integer or ''auto'''));
                    end%end if
                case 'Position'
                    position_isOn = 1;
                    if ischar(varargin{i+1}) && ...
                            find(strcmpi(varargin{i+1}, known_positions))
                        win_pos = resolvePosition(varargin{i+1});
                    else
                        error(['Position ' varargin{i+1}  'isn''t valid.']);
                    end%end if
                case 'Crop'
                    crop_isOn = 1;
                case 'Save'
                    save_isOn = 1;
                    save_fig_name = varargin{i+1};
                otherwise % Debugging
                    warning('Error parsing switch.');
            end %end switch
        end% end inner if
    end% end for
end% end outer if

% Set up auto-splitting
if ~split_isOn && ~ischar(style) % If split wasn't set and using defined style...
    if inarg_length < nsplits % If the user wanted too many splits, error.
        warning(splitTooLarge, strcat('You''ve entered too many splits.', ...
            ' It will be automatically reduced to ', inarg_length));
    end%end inner if
    
    nsplits = ceil(inarg_length./(ss_x * ss_y));
end%end outer if
% end pre-processing, parsing, and error handling

%---Begin Plotting---

% Reshape the matrices to be appropriate
if inarg_length > 1
    inarg = reshape(inarg, inarg_length, 1);
end
if st_isOn %if we wanted subtitles, reshape to a column vector
   subTitles = reshape(subTitles, length(subTitles), 1); 
end

% Create the figure
start   = 1;;
fin     = inarg_length;
save_count = 1; 
pos_count = 1; %Starting position (if enabled)

for nsp = 1:nsplits %for each figure split...
    if ~fname_isOn % if we want to name the window, name it.
        figName = ['PrettyFigure: Window ',' ', int2str(nsp)];
    end%end if
   
    if position_isOn
        if pos_count > length(win_pos)
            pos_count = 1;
        end
        pos_vector = win_pos{pos_count, 1};
        figure('Units', 'pixels','Name', figName, 'Position', pos_vector);
        %movegui(fig, q_pos{pos_count});
    else
        % Full screen figure
        screen_size = get(0, 'ScreenSize');
        figure('Name', figName, 'Position', [0 0 screen_size(3) screen_size(4)]);
    end%end if

    spcount = 1;
    for i = start:fin
       if i > (nsp * ss_x * ss_y) %for splitting
           start = i;
           break;
       end%end if
       subplot(ss_x, ss_y, spcount);
       imshow(inarg{i});
       if st_isOn && ~isempty(subTitles)% If subplot titles are enabled, show them.
           if ~isempty(subTitles{i,1}) % and if the subtitle exists...
                title(subTitles{i,1});
           end%end if
       end%end if
       spcount = spcount + 1;
    end%end for
    
    if mt_isOn %If we want a major title, put it there on each figure
        mtit(majorTitle, 'FontWeight','bold');
    end%end if
    
    if save_isOn
        set(gcf, 'PaperPositionMode','auto');
        if length(win_pos) == 1
            outfilename = [save_fig_name];
        else
            outfilename = [save_fig_name, '_window_', int2str(save_count)];
        end
        print('-djpeg', '-r300', outfilename);
        save_count = save_count + 1;
        if crop_isOn
            crop([outfilename, '.jpg']);
        end
    end
    
    pos_count = pos_count + 1;
    
end %end for

return; %Exit function

end % from prettyFigure()
% ---------- End of main function ---------------------------------

%----------------------------------------------------------------------------
function win = resolvePosition(pos_type)
%RESOLVEPOSITION - Determines the position to place figures when 
%                  plotting them. 
%
%   This is usefull when you want to make a comparison between sets of 
%   data or images.
%
%   The function will change the position of the figure when
%   showing the figures and the values returned from here are the pixel
%   coordinates of the locations of the figures.
%
%   There are 3 known positions: 
%
%       v2 - Vertically split in half
%     
%            -----------------------------
%            |             |             |
%            |             |             |
%            |      1      |       2     |
%            |             |             |
%            |             |             |
%            -----------------------------
%     
%       h2 - Horizontally split in half
%     
%            -----------------------------
%            |                           |
%            |             1             |
%            |                           |
%            |---------------------------|
%            |                           |
%            |             2             |
%            |                           |
%            -----------------------------
%       q  - Split in quarterized regions
%     
%            -----------------------------
%            |             |             |
%            |      1      |      2      |
%            |             |             |
%            |---------------------------|
%            |             |             |
%            |      3      |      4      |
%            |             |             |
%            -----------------------------
%
%  Input    -- pos_type -- Must be one of the 3 known positions
%
%  Output   -- win      -- Pixel locations for placing the frames.

    set(0,'Units','pixels')
    res = get(0, 'MonitorPositions');
    res = res(1,:); %Display on the first monitor.. for now...

    mac_adj = 0;    % Mac Adjustment
    f_adj = 0;      % Final Adjustment

    % Find the total usable space
    % Using this to prevent memory leak
    fields = struct(java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getMaximumWindowBounds());
    f_adj = res(4)-fields.height;
    
    % If the user is on a Mac..
    if(ismac)
        mac_adj = 22;           % 22 Pixels for top bar
        f_adj = f_adj+mac_adj;  % Final adjustment for usable space
    end %end if

    win = cell(2,1); % Pre-allocating for the first 2 options

    switch pos_type
%<<<<<<< .mine
        case {'v2', 'V2'} % Vertical halves
            win{1,1} = [res(1) res(2) res(3)/2 res(4)];     % Left side
            win{2,1} = [res(3)/2 res(1) res(3)/2 res(4)];   % Right side
        case {'h2', 'H2'} % Horizontal halves
            win{1,1} = [res(1) res(4)/2 res(3) res(4)/2];   % Top
            win{2,1} = [res(1) res(2) res(3) res(4)/2];     % Bottom
        case {'q', 'Q'}   % Quarters
            win{1,1} = [res(1)  (res(4))/2+f_adj (res(3))/2 (res(4))/2-f_adj]; % Northeast
            win{2,1} = [res(3)/2 (res(4))/2+f_adj (res(3))/2 (res(4))/2-f_adj];% Northwest
            win{3,1} = [res(1)   res(2)+mac_adj  (res(3))/2 (res(4))/2-f_adj]; % Southeast
            win{4,1} = [res(3)/2 res(2)+mac_adj  (res(3))/2 (res(4))/2-f_adj]; % Southwest
        case {'f', 'F'}   % Full-Screen
            win{1,1} = [res(1) res(2)+f_adj res(3) res(4)-f_adj-100];    
%{
=======
        case {'v2', 'V2'} %Vertical halves
            win{1,1} = [res(1) res(2) res(3)/2 res(4)];   
            win{2,1} = [res(3)/2 res(1) res(3)/2 res(4)];   
        case {'h2', 'H2'} %Horizontal halves
            win{1,1} = [res(1) res(4)/2 res(3) res(4)/2];   % Left Center -> Right Bottom
            win{2,1} = [res(1) res(2) res(3) res(4)/2];   % Top Left -> Right Center
        case {'q', 'Q'}   %Quarters
            win{1,1} = [res(1)  (res(4))/2+f_adj (res(3))/2 (res(4))/2-f_adj]; % Top Left    -> Mid Center
            win{2,1} = [res(3)/2 (res(4))/2+f_adj (res(3))/2 (res(4))/2-f_adj]; % Top Center  -> Right Center
            win{3,1} = [res(1)   res(2)+adj  (res(3))/2 (res(4))/2-f_adj]; % Left Center -> Mid Bottom
            win{4,1} = [res(3)/2 res(2)+adj  (res(3))/2 (res(4))/2-f_adj]; % Mid Center  -> Right Bottom
        case {'f', 'F'}   %Full-Screen
            win{1,1} = [res(1) res(2) res(3) res(4)]; 
            win{2,1} = [res(1) res(2) res(3) res(4)]; 
>>>>>>> .r41
            %}
        otherwise
            error([pos_type ' ' 'is not a valid position.']);  
    end% end switch
end%end resolvePosition()
