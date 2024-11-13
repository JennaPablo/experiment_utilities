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