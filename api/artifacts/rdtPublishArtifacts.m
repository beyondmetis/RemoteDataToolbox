function artifacts = rdtPublishArtifacts(configuration, folder, remotePath, varargin)
%% Publish multiple artifacts to a remote repository path.
%
% artifacts = rdtPublishArtifacts(configuration, folder, remotePath)
% publishes each of the files in the given folder as an artifact to a 
% remote respository.  configuration.repositoryUrl must point to the
% repository root.
%
% The artifactId of each artifact will be the same as the file base name.
% The type of each artifact will be the same as the file extension.
%
% artifact = rdtPublishArtifacts(... 'version', version) uses the
% given version for all published artifacts instead of the default '1'.
%
% artifact = rdtPublishArtifacts(... 'type', type) restricts publication to
% only files that have the same file extension as the given type.
%
% Returns a struct array of metadata about the published artifacts, or []
% if the publication failed.
%
% See also rdtArtifact rdtPublishArtifact
%
% artifacts = rdtPublishArtifacts(configuration, folder, remotePath, varargin)
%
% Copyright (c) 2015 RemoteDataToolbox Team

parser = rdtInputParser();
parser.addRequired('configuration');
parser.addRequired('folder', @ischar);
parser.addRequired('remotePath', @ischar);
parser.addParameter('version', '1', @ischar);
parser.addParameter('type', '', @ischar);
parser.parse(configuration, folder, remotePath, varargin{:});
configuration = rdtConfiguration(parser.Results.configuration);
folder = parser.Results.folder;
remotePath = parser.Results.remotePath;
version = parser.Results.version;
type = parser.Results.type;

artifacts = [];

%% Choose artifacts to publish.
folderListing = dir(folder);
nFiles = numel(folderListing);
isChosen = false(1, nFiles);
for ii = 1:nFiles
    listing = folderListing(ii);
    
    if listing.isdir
        continue;
    end
    
    [filePath, fileBase, fileExt] = fileparts(listing.name);
    fileType = fileExt(fileExt ~= '.');
    
    isChosen(ii) = '.' ~= fileBase(1) ...
        && ~strcmpi('.ASV', fileExt) ...
        && '~' ~= fileExt(end) ...
        && (isempty(type) || strcmp(type, fileType));
end

%% Publish each artifact.
% TODO: optimize the multiple-artifact publish by including all artifacts
% in a single invocation of Gradle.  This should remove significant
% overhead from Gradle startup and network "chattiness".  We just have to
% figure out a good way to pass multiple artifacts to publish.gradle.

chosenListing = folderListing(isChosen);
nArtifacts = numel(chosenListing);
artifactCell = cell(1, nArtifacts);
for ii = 1:nArtifacts
    file = fullfile(folder, chosenListing(ii).name);
    [filePath, artifactId] = fileparts(file);
    artifactCell{ii} = rdtPublishArtifact(configuration, ...
        file, ...
        remotePath, ...
        'artifactId', artifactId, ...
        'version', version);
end

artifacts = [artifactCell{:}];