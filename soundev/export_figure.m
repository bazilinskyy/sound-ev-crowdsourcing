% Matlab script by Pavlo Bazilinskyy
% questions/comments to <pavlo.bazilinskyy@gmail.com>

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Maximise and output figure in EPS format.
%%% Input:
% figure: gcf object.
% filename: name of file to be saved as.
% format: format of file to be saved.
% maximise: default argument to maxmise figure or not.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function export_figure(figure, filename, format, maximise)
    % way to pass default arguments in matlab...
    if nargin < 4
        maximise = true;
    end
    % maxmise if needed
    if maximise
        set(figure, 'Position', get(0, 'Screensize'));
    end
    % export to eps
    saveas(figure, filename, format)
end
