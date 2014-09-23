classdef ImageSourceAligned < Alignment & ImageSource
   %
   % ImageSourceAligned class represents Image data composed of aligned images
   %
   % description: 
   %    it unifies the Alignenet and ImageSource classes
   %    explictly separated from ImageSourceTiled to allow for easy splitting of non-alignable components
   %    ImageSourceAligned classes then share the data (and possibly cached) source ImageSourceTiled
   %    the ids of the tiles contributing to this image are stored in the Alignemnt class as nodes
   %
   
   properties
      asize = [];     % full absolute image size of  aligned images
   end

   methods   
      function obj = ImageSourceAligned(varargin)  % basic constructor
         %
         % ImageSourceAligned()
         % ImageSourceAligned(...,fieldname, fieldvalue,...)
         %
         if nargin == 1 
            if isa(varargin{1}, 'ImageSourceAligned') %% copy constructor
               obj = copy(varargin{1});
            elseif isa(varargin{1}, 'ImageSourceTiled')
               obj = obj.fromImageSourceTiled(varargin{1});
            else
               error('%s: not valid arguments for constructor', class(obj));
            end
         else
            for i = 1:2:nargin % constructor from arguments
               if ~ischar(varargin{i})
                  error('%s: invalid constructor input, expects char at position %g',class(obj), i);
               end
               if isprop(obj, varargin{i})
                  obj.(varargin{i}) = varargin{i+1};
               else
                  warning('%s: unknown property name: %s ', class(obj), varargin{i})
               end
            end        
         end
      end
      
      function obj = fromImageSourceTiled(obj, ist)
         obj.isource = ist;
         ts = ist.tilesizes();
         obj.fromCell(ts);
         
         % initialize the image information from isource
         obj.iinfo = ist.isource.iinfo;
         
         obj.asize = [];  % [] = image not aligned
      end
       

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % base methods - redefinitions 
      %      

      function s = datasize(obj)
%          if isempty(obj.asize)
%             error('%s: datasize: images not aligned, cannot infer data size!', class(obj));
%          end
         s = obj.asize;
      end

      function s = rawsize(obj)
%          if isempty(obj.asize)
%             error('%s: datasize: images not aligned, cannot infer raw data size!', class(obj));
%          end
         if isempty(obj.rawformat)
            s = obj.asize;
         else
            per = impqlformat2permute(obj.dataformat, obj.rawformat);
            s = obj.asize;
            s = permute(s, per);
         end
      end

      function d = data(obj, varargin)
         if obj.icache % basic caching
            if ~isempty(obj.idata)
               d = obj.idata;
            else
               % stictch the data
               d = obj.getData(varargin{:});
               
               % cache it
               obj.idata = d;
            end
         else
            d = obj.stitch(varargin{:});
         end
      end
      
      function d = rawdata(obj, varargin)
         d = obj.data();
         d = obj.iinfo.data2raw(d);
      end
      
      
      function c = celldata(obj, varargin)
         % get all tiles used by alignment
         c = obj.isource.tiles(obj.nodes);
      end
      
      function cs = cellsize(obj, varargin)
         cs = length(obj.nodes);
      end

      function cf = cellformat(~, varargin)
         cf = 'u';
      end
      
      function d = getData(obj, varargin)  % obtain the image data
         %
         % d = getData(obj, varargin)
         %
         % description:
         %     obtain image data in the format given by obj.dataformat

         d = obj.stitch(varargin{:});
      end
      
      function d = getRawData(obj, varargin)
         %
         % d = getRawData(obj, varargin)
         %
         % description:
         %     obtain raw image data in the format given by obj.rawformat
         
         d = obj.iinfo.data2raw(obj.getData(varargin{:}));     % trivial here ->  to be implemented depending on ImageSource superclass
      end
      
      function obj = setData(obj, ~)  % set the image data
         error('%s: setData: canot set data!', class(obj));
      end


      function obj = clearCache(obj)
         obj.idata = [];
      end
      
      function obj = setCache(obj, c)
         obj.icache = c;
         obj.clearCache();
      end
      
      function clear(obj)
         obj.clearCache();
         obj.asize = [];
      end
      
      
 
      
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %%% alignment routines

      
      function comp = connectedComponents(obj, varargin)
         %
         % comp = connectedComponents(obj, varargin)
         %
         % descritpion:
         %   given quality factors of pairs returns cell array of Alignemnts with connected images
         %
         % input:
         %   param   parameter as in connectedAlignments
         %
         % See also: connectedAlignments
         
         comp = connectedAlignments(obj, varargin{:});   
      end
      
      
      function obj = align(obj, varargin)
         %
         % obj = align(obj, varargin)
         %
         % description:
         %    aligns images and sets new shifts
         %
         % See also: alignImages
         
         [~, prs] = alignImages(obj.isource, 'pairs', obj.pairs, varargin{:});
         
         obj.pairs = prs;
         [~, as] = obj.absoluteShiftsAndSize();
         obj.asize = as;
      end
        
  
      function sti = stitch(obj, varargin)
         %
         % st = stitch(obj, source, param)
         %
         % description
         %     stitches images using the alignment information and source
         
         st  = stitchImages(obj.isource.getTiles(obj.nodes), obj.imageShifts, varargin{:});
         
         obj.asize = size(st);
         if obj.icache  % cache this result
            obj.idata = st; 
         end
         
         if nargout > 0
            sti = st;
         end
      end

      
      
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % tiling 
      
      function img = tile(obj, id)
         img = obj.isource.getTile(id);
      end
      
      function imgs = tiles(obj, varargin)
         imgs = obj.isource.getTiles(varargin{:});
      end

      function tsi = tilesize(obj)
         tsi = obj.isource.tilesize;
      end
      
      function td = tiledim(obj)
         td = length(obj.tilesize);
      end
      
      function n = ntiles(obj)
         n = prod(obj.tilesize);
      end
      
      
      function ids = roi2tileids(obj, roi)
         %
         % ids = roi2tileids(obj, roi)
         %
         % description:
         %    identifies the ids of the tiles that contribute to the roi
         
         [ash, ~] = obj.absoluteShiftsAndSize();
         ids = roi2imageids(ash, obj.tilesizes, roi);
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % plotting
      
      function plotAlignedImages(obj)
         %
         % plotAlignedImages(obj)
         %
         % description:
         %    visualizes the alignment using plotAlignedImages
         %
         % See also: plot
         
         plotAlignedImages(obj.isource.tiles(obj.nodes), obj.imageShifts);
      end
      
      
      function plot(obj, varargin)
         %
         % plot(obj)
         %
         % description:
         %    plot the stitched image
         %
         % See also: plotAlignedImages
                  
         implot(obj.data(varargin{:}));
      end



      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % information / visulaization 
      function istr = infoString(obj)
         istr = infoString@ImageSource(obj, 'Aligned');
         istr = [istr, '\nsource: ', class(obj.isource)];
         istr = [istr, '\nnodes:  ', var2char(obj.nnodes)];
         istr = [istr, '\npairs:  ', var2char(obj.npairs)];
         
         if isempty(obj.asize)
            istr = [istr, '\naligned:', 'false'];
         else
            istr = [istr, '\naligned:', 'true'];
            %istr = [istr, '\nsize:   ', var2char(obj.datasize)];
         end
      end


      
   end
   
end