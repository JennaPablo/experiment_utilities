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