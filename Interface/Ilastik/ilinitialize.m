function ilinitialize(varargin)
%
% ilinitialize()
%
% description:
%     set up the interface to ilasitk via the python interface
%
% input:
%    hintpath  (optional) path to ilastik

cpath = fileparts(mfilename('fullpath'));
ipath = ilpath(varargin{:});

if count(py.sys.path, ipath) == 0
    insert(py.sys.path,int32(0), ipath);
end

if count(py.sys.path, cpath) == 0
    insert(py.sys.path,int32(0), cpath);
end

% set environ ment variable

setenv('HDF5_DISABLE_VERSION_CHECK', '2')

% initialize the Ilastik classifer

% py.IlastikInterface.IlastikClassifier();



