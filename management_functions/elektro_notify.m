function [] = elektro_notify(email, message, header)
%ELEKTRO_NOTIFY(email, message, header) sends an email to notify the user
%   ELEKTRO_NOTIFY(email, message, header)
%   
%   This is a convenience function that notifies the user about the status
%   of very long computations (e.g., ICA). Whenever reached in the script,
%   it sends an automated e-mail to the specified address with custom
%   content. For instance, you could use it to be informed after each 
%   subject's wavelet decomposition is done.
%
%   INPUT ARGUMENTS:
%     'email': string, the recipients email address
%     'message': string, the message's content; Alternatively, you can pass
%                a 'ME' struct, as produced by try...catch ME
%     'header': string, the title of your mail (default: "Elektro-Notify")
%
%   EXAMPLES:
%     try
%       mean(struct());
%     catch ME
%       ELEKTRO_NOTIFY('miss_test@lab.org', ME);
%     end
%   %===========================================
%     ELEKTRO_NOTIFY('mister_test@lab.org',...
%        sprintf('Subject %i done', isub), 'Wavelet status');
%
%   LIMITATIONS:
%     This function currently only works on Linux with a mail server
%     installed ('mail' command should work in terminal). Probably possible
%     on OS X as well. Silently ignored on Windows.
%     On OS X and Linux, the program tries to send a message and warns if
%     this does not succeed.
%
%   Wanja Moessing, moessing@wwu.de, Aug 18

%% defaults
if nargin < 1
    warning('No email address specified...');
    return
elseif ~(ischar(email))
    warning('email address needs to be a string');
    return
end

if nargin < 2
    message = 'Have a nice day and enjoy Elektro-Pipe!';
elseif ~(isa(message, 'MException') | ischar(message) | isa(message, 'string'))
    warning('message must be a MException (try... catch ME) or a string.')
    return
end

if nargin < 3
    header = 'Elektro-notify';
elseif ~(ischar(header))
    warning('header needs to be a string');
    return
end

%% check if message is a catch ME struct
if isa(message, 'MException')
    stackstr = '';
    for istack = 1:size(message.stack, 1)
        stack = message.stack(istack);
        stackstr = sprintf('%s\n\tfile: %s\n\tfunction: %s\n\tline: %i\n',...
            stackstr,stack.file, stack.name, stack.line);
    end
    message = ...
        sprintf(['A try..catch statement threw the following MExcpetion:',...
        '\nmessage: %s\nIdentifier: %s\nstack: \n%s'],...
        message.message, message.identifier, stackstr);
end    

unixworked = 1;
if isunix || ismac
    try
        stat = system(sprintf('echo "%s" | mail -s "%s" %s',...
            message, header, email));
        assert(stat==0, 'non-zero mail status');
		unixworked = 0;
    catch
        disp('Could not send E-Mail. ''mail'' in terminal not configured? Run apt install mailutils');
    end
end
if ispc || ~unixworked
    fprintf(['\n|||||||||||||||||||||||||||||||||||||||||||||||||||||\n',...
        'E-mail to %s with title %s could not be sent.\nContent:\n%s',...
        '\n|||||||||||||||||||||||||||||||||||||||||||||||||||||\n'],...
        email, header, message);
end

end