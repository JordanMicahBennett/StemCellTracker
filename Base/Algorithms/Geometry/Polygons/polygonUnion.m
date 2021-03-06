function [pol, varargout] = polygonUnion(pol, poladd, varargin) 
%
% pol = polygonUnion(pol, polclip) 
%
% description: 
%     calculates union between polygons
% 
% input:
%     pol     polygon as cell of oriented paths, each path is 2xn array of coords
%     poladd  polygon to add 
%     param   parameter struct with entries as in polygonExecute
%
% output
%     pol     clipped polygon 
%

if nargout> 1
   [pol, varargout{1}] = polygonExecute(pol, poladd, varargin{:}, 'operator', 'Union');
else
   pol = polygonExecute(pol, poladd, varargin{:}, 'operator', 'Union');
end

end






