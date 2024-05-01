function figTileLabel(varargin)
P=inputParser;
addParameter(P,'label','A':'Z',@(X)ischar(X)&isvector(X));
parse(P,varargin{:});

ax=findobj( get(gcf,'Children'), '-depth', 1, 'type', 'axes');
if length(ax)>length(P.Results.label)
    error('Number of subplot exceed length of input label char vector');
    return
else
    for iax=1:length(ax)
        try
            nexttile(iax);
        catch
            continue
        end
        set(gca,'Units',"pixels")
        Yout=get(gca,'OuterPosition'); 
        Yin=get(gca,'Position');
        offset=abs((Yout(1)-Yin(1)))-5; % This parameters was optimized
        set(gca,'Units',"normalized");
        abcLabel(P.Results.label(iax),offset);
    end
end
disp('...Add plot number label Done...')
end

%%
function c = abcLabel(varargin)

if isa(varargin{1}, 'char')
    axesHandle = gca;
else
    axesHandle = get(varargin{1}{1}, 'Parent');
end

if strcmp(get(get(axesHandle, 'Title'), 'String'), '')
    title(axesHandle, ' ');
end
if strcmp(get(get(axesHandle, 'YLabel'), 'String'), '')
    ylabel(axesHandle, ' ');
end
if strcmp(get(get(axesHandle, 'ZLabel'), 'String'), '')
    zlabel(axesHandle, ' ');
end

if isa(varargin{1}, 'char')
    label = varargin{1};
    if nargin >=2
        dx = varargin{2};
        if nargin >= 3
            dy = varargin{3};
        else
            dy = 0;
        end
    else
        dx = 3;
        dy = 3;
    end
    h = text('String', label, ...
        'HorizontalAlignment', 'left',...
        'VerticalAlignment', 'top', ...
        'FontUnits', 'pixels', ...
        'FontSize', 18, ...
        'FontWeight', 'normal', ...
        'FontName', 'Arial', ...
        'Units', 'normalized');
    el = addlistener(axesHandle, 'Position', 'PostSet', @(o, e) posChanged(o, e, h, dx, dy));
    c = {h, el};
else
    h = varargin{1}{1};
    delete(varargin{1}{2});
    if nargin >= 2
        if isa(varargin{2}, 'char')
            set(h, 'String', varargin{2});
            if nargin >=3
                dx = varargin{3};
                dy = varargin{4};
            else
                dx = 3;
                dy = 3;
            end
        else
            dx = varargin{2};
            dy = varargin{3};
        end
    else
        error('Needs more arguments');
    end
    el = addlistener(axesHandle, 'Position', 'PostSet', @(o, e) posChanged(o, e, h, dx, dy));
    c = {h, el};
end
posChanged(0, 0, h, dx, dy);
end

function posChanged(~, ~, h, dx, dy)
axh = get(h, 'Parent');
p = get(axh, 'Position');
o = get(axh, 'OuterPosition');
xp = (o(1)-p(1))/p(3);
yp = (o(2)-p(2)+o(4))/p(4);
set(h, 'Units', get(axh, 'Units'),'Position', [xp yp]);
set(h, 'Units', 'pixels');
p = get(h, 'Position');
set(h, 'Position', [p(1)+dx, p(2)+5-dy]);
set(h, 'Units', 'normalized');
end