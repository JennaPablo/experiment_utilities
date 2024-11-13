%{
    Challenge Experiment Code - 1 Lilac Chaser
    Written by Jenna Pablo
    Code buddy: Lena Kemmelmeier + a lil bit of ChatGPT (for Gaussian!)
%}

clear; clc; close all;

try
%% GUI
    prompt = {'Time (in seconds):', 'Refresh rate (Hz):'};
    response = inputdlg(prompt);
    task_duration = str2double(response{1});
    refresh_rate = str2double(response{2});

%% Prepare environment
    commandwindow; %puts focus to command window for key presses
    ListenChar(2); %suppress the key presses
    HideCursor;
%% Determine quit key
    quit_key = KbName('q');
%% Time parameters
    %task_duration = 15; %in seconds how long do you want it to run for

    %adjust for refresh rate:
    ifi = 1/refresh_rate; %mac promotion=120 hz
    refresh_adjustment = ifi *.1; %adjusted to closest output time

    %deadline = when experiment will stop playing
    deadline = task_duration - refresh_adjustment;
%% Open a screen
    %screen settings
    win_prefs.color = [128,128,128]; %mid gray
    Screen('Preference', 'SkipSyncTests', 1);
    win_prefs.screens = Screen('Screens');
    win_prefs.screen_number=max(win_prefs.screens);
    win_prefs.screen_rect = [];
    %open the window - refer to window with win_prefs.win from now on
    win_prefs.win=Screen('OpenWindow', win_prefs.screen_number, ...
        win_prefs.color, win_prefs.screen_rect);
    %get screen coordinates
    [screen_x,screen_y] = Screen('WindowSize',win_prefs.win);
    win_prefs.center_x = screen_x/2;
    win_prefs.center_y = screen_y/2;
    %% Fixation parameters
    fix_prefs.color = [0, 0, 0]; %black
    fix_prefs.size = 20; %cross size (length of dashes)
    fix_prefs.line_width = 5; %cross thickness
    %% Specify blob parameters
    blob.n_blobs = 12; %number of blobs present
    blob.disappear_time = .25; %each blob disappears .25s
    %{
    Playing with disappear times: 
     1s = weak, but still works..ish
    .45 = still sort of works, harder for me
    .25 = illusion still works
    .05 = illusion strengthened! happens a lot faster for me
    .01 = too fast, doesn't work
    %}
    blob.color = [255, 0, 255]; %purple, color of blobs
    % calculate blob positions in circle - help from Mark's circlePos function
    blob.positions = circle_pos(blob.n_blobs, screen_x / 4);

    %{
        The subsequent code for generating a gaussian blob was written with
        the help of Chat GPT (only in this cell of code). Unfortunately, the 
        explanations Chat GPT give for each part of the code is very confusing 
        (e.g., chat says blob.stdev controls the blur of the gaussian, but it 
        just changes how big the blob shows up)... Lena and I have attempted to
        pull apart each line to figure this out, but still do not fully 
        comprehend the gaussian code. 
    %}
    blob.stdev = 30; %stdev of gaussian (controls the size of blob)
    blob.size = 2 * round(3 * blob.stdev) + 1; %size of Gaussian matrix (3 SDs from mean)

    %generate Gaussian matrix for blob
    [x, y] = meshgrid(-blob.size / 2 : blob.size / 2, -blob.size / 2 : blob.size / 2);
    gaussian_blob = 0.8 * exp(-(x.^2 + y.^2) / (2 * blob.stdev^2));
    gaussian_blob = min(gaussian_blob, 1); %cap values at 1 to avoid oversaturation

    %create RGB blob matrix with Gaussian applied as an alpha layer
    rgba_blob = repmat(reshape(win_prefs.color, 1, 1, 3), blob.size + 1, blob.size + 1);
    rgba_blob(:,:,1) = uint8(blob.color(1) * gaussian_blob + double(win_prefs.color(1) * (1 - gaussian_blob)));
    rgba_blob(:,:,2) = uint8(blob.color(2) * gaussian_blob + double(win_prefs.color(2) * (1 - gaussian_blob)));
    rgba_blob(:,:,3) = uint8(blob.color(3) * gaussian_blob + double(win_prefs.color(3) * (1 - gaussian_blob)));

    %make gaussian blob
    blob.texture = Screen('MakeTexture', win_prefs.win, rgba_blob);
    %end of chat gpt help with gaussian
    %% While loop for displaying blobs
    %class psuedocode was huge help! 
    first_flip = Screen('Flip', win_prefs.win); % first flip = time 0, start

    %check for quit key
    check_quit_key(quit_key);

    blob.removed = 1; %will increment to keep removing one blob at a time

    %while the time is less than start time + trial duration
    while GetSecs() < (first_flip + deadline)
        %check for quit key
        check_quit_key(quit_key);

        %create fixation cross
        create_fixation_cross(win_prefs,fix_prefs);

        %for loop to draw all blobs except the current i_blob
        for i_blob = 1:blob.n_blobs
            %check for quit key
            check_quit_key(quit_key);

            %skip drawing if i_blob = the one to be removed
            if i_blob == blob.removed
                continue;
            end

            %current blob position centered on screen
            blob_x = win_prefs.center_x + blob.positions(i_blob, 1);
            blob_y = win_prefs.center_y + blob.positions(i_blob, 2);
            %calculate destination rectangle for blob to show
            dest_rect = CenterRectOnPoint([0, 0, blob.size, blob.size], blob_x, blob_y);

            %draw blob
            Screen('DrawTexture', win_prefs.win, blob.texture, [], dest_rect);
        end

        %flip! shows all blobs - i_blob
        Screen('Flip', win_prefs.win);

        %check for quit key
        check_quit_key(quit_key);

        %wait blob.disappear_time before doing next i_blob to remove
        WaitSecs(blob.disappear_time);

        %increment blob.removed by 1 but not exceeding 12
        blob.removed = mod(blob.removed, blob.n_blobs) + 1;
    end

    sca; %close screen
    ListenChar(0); %allow key presses back
    ShowCursor; %bring back cursor

catch ME
    sca;%close the screen
    ListenChar(0); %allow key presses back
    ShowCursor; %bring back cursor

    %display the error
    error(ME.message);
end


%% Helper functions
%Functions are ran locally to submit one script only

function create_fixation_cross(win_prefs,fix_prefs)
%
% Usage: create_fixation_cross(win_prefs,fix_prefs)
%
% Inputs: 
% win_prefs: needs to at least include window pointer, x center,
% and y center of the screen
% fix_prefs: needs at least fixation color, size, and line width
%
% Results in a cross fixation 
%
% Written by J. Pablo 
% 10/29/24
%

%default values for fixation
if nargin < 2 || isempty(fix_prefs)
    fix_prefs.color = [0,0,0]; %black
    fix_prefs.line_width = 5; 
    fix_prefs.size = 25;
end

%draw the horizontal line
Screen('DrawLine', win_prefs.win, fix_prefs.color, ...
    win_prefs.center_x - fix_prefs.size, win_prefs.center_y, ...
    win_prefs.center_x + fix_prefs.size, win_prefs.center_y, fix_prefs.line_width);

%draw the vertical line
Screen('DrawLine', win_prefs.win, fix_prefs.color, ...
    win_prefs.center_x, win_prefs.center_y - fix_prefs.size, ...
    win_prefs.center_x, win_prefs.center_y + fix_prefs.size, fix_prefs.line_width);

end

function circle_points = circle_pos(n_positions, radius)
% 
% Usage: circle_points = circle_pos(n_positions, radius)
% 
% Computes `n_positions` points along a circle at radius `radius`
% Originally written by MDL 2024.10.22 - Altered by J. Pablo 
%

angle_diff = 2 * pi / n_positions;
theta = 0:angle_diff:(2*pi-angle_diff);
[x, y] = pol2cart(theta, radius);

circle_points = [x;y]';
end

function check_quit_key(quit_key)
%
% Usage: check_quit_key(quit_ley)
% 
% Inputs:
% quit_key: KbName('whichever key using to quit')
%
% Results in an error message 'User manually quit.'
%
% Written by J. Pablo
% 10/30/24
%

%default quit key = q
if nargin < 1 || isempty(quit_key)
    quit_key = KbName('q');
end

[key_down, ~, key_code] = KbCheck;
if key_down==1 && key_code(quit_key) == 1
    error("User manually quit.")
end
end