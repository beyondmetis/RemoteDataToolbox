function artifacts = rdtListArtifacts(configuration, remotePath, varargin)
%% Query an Archiva Maven repository for artifacts under a remote path.
%
%    artifacts = rdtListArtifacts(configuration, remotePath, varargin)
%
% Returns a list of all artifacts under the given remotePath, from an
% Archiva Maven repository.  
%
% configuration.serverUrl must point to the Archiva server root.
% configuration.repositoryName must contain the name of a repository on the
% server.
%
% Parameter/Value Options
%
%   artifacts = rdtListArtifacts( ... 'artifactId', artifactId) 
% restricts search results to artifacts with exactly the given artifactId.
%
%   artifacts = rdtListArtifacts( ... 'version', version) 
% restricts search results to artifacts with exactly the given version.
%
%   artifacts = rdtListArtifacts( ... 'type', type) 
% restricts search results to artifacts with exactly the given type.
%
%   artifacts = rdtListArtifacts( ... 'pageSize', pageSize) 
% limits the number of results to the pageSize.  The default is 1000.
%
%   artifacts = rdtListArtifacts( ... 'sortField', sortField) 
% sort search results using the given field name.  The default is to sort
% by artifacts.artifactId.  If sortField is not an existing artifact field
% name, results are not sorted.
%
% See also rdtListRemotePaths, rdtSearchArtifacts, rdtArtifact
%
% Examples:
%  This function is called by the RdtClient listArtifacts command, which
%  also has some additional options
%
%   a = rdt.listArtifacts;
%   a = rdt.listArtifacts('type','mat')
%   a = rdt.listArtifacts('printID',true,'type','mat');
%
% Copyright (c) 2015 RemoteDataToolbox Team

parser = rdtInputParser();
parser.addRequired('configuration');
parser.addRequired('remotePath', @ischar);
parser.addParameter('artifactId', '', @ischar);
parser.addParameter('version', '', @ischar);
parser.addParameter('type', '', @ischar);
parser.addParameter('pageSize', 1000);
parser.addParameter('sortField', 'artifactId', @ischar);
parser.parse(configuration, remotePath, varargin{:});

configuration = rdtConfiguration(parser.Results.configuration);
remotePath = parser.Results.remotePath;
artifactId = parser.Results.artifactId;
version = parser.Results.version;
type = parser.Results.type;
pageSize = parser.Results.pageSize;
sortField = parser.Results.sortField;

artifacts = [];

%% Query the Archiva server.
resourcePath = '/restServices/archivaServices/searchService/searchArtifacts';

% hack: repeat repositoryName forces JSON array, not scalar string
searchRequest.repositories = {configuration.repositoryName, configuration.repositoryName};
searchRequest.groupId = rdtPathSlashesToDots(remotePath);
searchRequest.artifactId = artifactId;
searchRequest.version= version;
searchRequest.artifactId = artifactId;
searchRequest.classifier = type;
searchRequest.pageSize = pageSize;

response = rdtRequestWeb(configuration, resourcePath, 'requestBody', searchRequest);
if isempty(response)
    return;
end

nArtifacts = numel(response);
artifactCell = cell(1, nArtifacts);
for ii = 1:nArtifacts
    r = response{ii};
    r.remotePath = rdtPathDotsToSlashes(r.groupId);
    artifactCell{ii} = rdtArtifact(r);
end
artifacts = rdtSortStructArray([artifactCell{:}], sortField);
