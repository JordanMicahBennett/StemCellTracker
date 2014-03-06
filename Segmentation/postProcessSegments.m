function [postlabel, stats] = postProcessSegments(label, param)
%
% [postlabel, props] = postProcessSegments(label, param)
%
% input:
%    label    labeled image (assume labels 1-nlables, imrelabel)
%    param    parameter struct with entries
%             .volume.min        minimal volume to keep (0)
%             .volume.max        maximal volume to keep (Inf)
%             .intensity.min     minimal mean intensity to keep (-Inf)
%             .intensity.max     maximal mean intensity to keep (Inf)
%             .boundaries        clear objects on x,y boundaries (false)
%             .fillholes         fill holes in each z slice after processing segments (true)
%             .smooth            smooth -- todo e.g. using vtk denoising library/ java interface
% 
% output:
%    postlabel  post processed label
%    stats      calculated statistics
%
% note:
%    clearing of boundary objects here ignores touching z boundaries, use imclearborder for this
%    filling holes is done in each slice only, use imfill(..., 'holes') on full 3d image for this
%
% Seel also: regionprops, imrelabel, imclearborder, imfill

volume_min = getParameter(param, {'volume', 'min'}, 0);
volume_max = getParameter(param, {'volume', 'max'}, Inf);

intensity_min = getParameter(param, {'intensity', 'min'}, -Inf);
intensity_max = getParameter(param, {'intensity', 'max'}, Inf);

boundaries = getParameter(param, {'boundaries'}, false);

fillholes  = getParameter(param, {'fillholes'}, true);

postlabel = label;

% determine props to calculate
props = {};
if volume_min > 0 || volume_max < Inf
   props{end+1} = {'Area'};
end
if intensity_min > -Inf || intensity_max < Inf
   props{end+1} = {'PixelIdxList'};
end

if ~isempty(props)
   stats = regionprops(label, props{:});
end

if volume_min > 0 || volume_max < Inf
   idx = find([stats.Area] > volume_max);
   for i = idx
      postlabel(label == i) = 0;  
   end
   idx = find([stats.Area] < volume_min);
   for i = idx
      postlabel(label == i) = 0;  
   end
end

if intensity_min > -Inf || intensity_max < Inf
   for i = length(stats):-1:1
      mi{i} = mean(image(stats(i).PixelIdxList));
   end
   [stats.MeanIntensity] = mi{:};
   
   idx = find([stats.MeanIntensity] < intensity_min);
   for i = idx
      postlabel(label == i) = 0;  
   end
   idx = find([stats.MeanIntensity] > intensity_max);
   for i = idx
      postlabel(label == i) = 0;  
   end
end

% fill possible holes in each slice
if fillholes
   for s = 1:size(segth,3)
      postlabel(:,:,s) = imfill(postlabel(:,:,s), 'holes');
   end
end

% we dont want to clear objects that border in z
if boundaries
   if ndims(label) == 3
      pseg = zeros(size(postlabel) + [0 0 2]);
      pseg(:, :, 2:end-1) = postlabel;
      pseg = imclearborder(pseg);
      postlabel = pseg(:,:,2:end-1);
   else
      postlabel = imclearborder(postlabel);
   end
end

end


