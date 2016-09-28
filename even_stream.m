function [x_line, y_line] = ...
    even_stream(xx, yy, uu, vv, d_sep, d_test, step_size) %#ok!
%
% Plot evenly-spaced streamlines with Jobar & Lefer algorithm (ref 1).
%
% Arguments:
%
%   xx, yy:
%
%   uu, vv: 
%
%   d_sep:
%
%   d_test:
%
%   step_size:
%
%   x_line, y_line: Vectors, x- and y-coordinates of streamline points,
%       individual lines are separated by NaNs
% 
% References: 
% [1] Jobard, B., & Lefer, W. (1997). Creating Evenly-Spaced Streamlines of
%   Arbitrary Density. In W. Lefer & M. Grave (Eds.), Visualization in
%   Scientific Computing �97: Proceedings of the Eurographics Workshop in
%   Boulogne-sur-Mer France, April 28--30, 1997 (pp. 43�55). inbook,
%   Vienna: Springer Vienna. http://doi.org/10.1007/978-3-7091-6876-9_5
% %

%% get initial streamline

% get seed point at random (populated) point
x_min = min(xx(:));
x_rng = range(xx(:)); 
y_min = min(yy(:));
y_rng = range(yy(:));
u0 = NaN;
v0 = NaN;
while isnan(u0) || isnan(v0)
    x0 = x_min+rand(1)*x_rng;
    y0 = y_min+rand(1)*y_rng;
    u0 = interp2(xx, yy, uu, x0, y0);
    v0 = interp2(xx, yy, vv, x0, y0);
end

% add first stream line
[x_line, y_line, ~] = get_streamline(xx, yy, uu, vv, x0, y0, step_size);

% create seed point candidate queue
x_queue = cell(0); 
y_queue = cell(0);
[x_queue{end+1}, y_queue{end+1}] = ...
    get_seed_candidates(x_line, y_line, d_sep);

%% main loop

d_sep_sq = d_sep*d_sep;
while ~isempty(x_queue)
    % pop seed candidates from queue
    x_seed = x_queue{1}; x_queue(1) = [];
    y_seed = y_queue{1}; y_queue(1) = [];    
    % check each candidate point in random order
    for ii = randperm(length(x_seed))
        dx = x_seed(ii) - x_line;
        dy = y_seed(ii) - y_line;
        d_min_sq = min(dx.*dx + dy.*dy);
        if d_min_sq >= d_sep_sq
            % create new streamline
            [x_line_new, y_line_new, seed_idx] = get_streamline(...
                xx, yy, uu, vv, x_seed(ii), y_seed(ii), step_size);
            if ~isempty(x_line_new) 
                
                % trim new streamline
%                 seed_idx = find(

                % add seed candidate points to queue
                [x_queue{end+1}, y_queue{end+1}] = ...
                    get_seed_candidates(x_line_new, y_line_new, d_sep); %#ok!
                
                % add trimmed streamline to list
                x_line = [x_line; NaN; x_line_new]; %#ok!
                y_line = [y_line; NaN; y_line_new]; %#ok!

            end
        end
    end

end

%% debug

plot(x_line, y_line, '-k');

keyboard

function [x_seed, y_seed] = get_seed_candidates(x_line, y_line, d_sep)
%
% Compute the location of stream line seed point candidates that lie at a
% distance d_sep along a normal vector at each point in x_line, y_line 
%
% Arguments:
%   x_line, y_line: Vectors, points along a streamline
%   d_sep: Scalar, desired spacing between streamlines
%   x_seed, y_seed: Vectors, canditate seed points

% get unit normal vectors at segment midpoints
xy = [x_line, y_line];
fprintf('%i\n', length(x_line));
tangent = diff(xy);
normal = [tangent(:,2), -tangent(:,1)];
normal = bsxfun(@rdivide, normal, sqrt(sum(normal.*normal, 2)));
midpoint = xy(1:end-1, :)+0.5*tangent;

% get candidates offset d_sep in positive and negative normal direction
seed = [midpoint+d_sep*normal; midpoint-d_sep*normal];
x_seed = seed(:,1);
y_seed = seed(:,2);

function [xs, ys, i0] = get_streamline(xx, yy, uu, vv, x0, y0, step_size)
%
% Compute streamline in both directions starting at x0, y0
%
% Arguments: 
%   See documentation for stream2 for input argument definitions
%   xs, ys : Vectors, stream line x- and y-coordinates, returns [] if
%       stream line has zero length
%   i0: Scalar, index of seed point in output streamline
% %

fwd = stream2(xx, yy, uu, vv, x0, y0, step_size);
xy_fwd = fwd{1};
has_fwd = size(xy_fwd,1) > 1;

rev = stream2(xx, yy, -uu, -vv, x0, y0, step_size);
xy_rev = rev{1};
has_rev = size(xy_rev,1) > 1;

if has_fwd && has_rev
    xs = [xy_rev(end:-1:2, 1); xy_fwd(:, 1)];
    ys = [xy_rev(end:-1:2, 2); xy_fwd(:, 2)];
    i0 = size(xy_rev,1);
elseif has_rev
    xs = xy_rev(:,1);
    ys = xy_rev(:,2);
    i0 = 1;
elseif has_fwd
    xs = xy_fwd(:,1);
    ys = xy_fwd(:,2);
    i0 = 1;
else
    xs = [];
    ys = [];
    i0 = [];
end

%<DEBUG>
if ~isempty(i0)
    % i0 = i0+1; % fails, which is good
    fprintf('x: %g\n', xs(i0)-x0);
    assert(abs(xs(i0)-x0) < 1e-15, 'seed index is incorrect');
    fprintf('y: %g\n', ys(i0)-y0);
    assert(abs(ys(i0)-y0) < 1e-15, 'seed index is incorrect');
end
%</DEBUG>