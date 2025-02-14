%% Step 2 - Assemble a pangenome database
% Generate a database of all genes (including sequences and headers) for
% all strains to be included in the Pangenome. Genes are annotated with KO
% id's. A matrix of presence/absence for KO's is included for all strains.
% A database of metadata is also included 'orgDatabase'.

% (About 15 minutes runtime for 649 strains)

%% Directories and filenames
FileNames = struct;
FileNames.orgDatabase = 'data/genomes/orgDatabase_20200805.csv';
FileNames.FastaDir = 'data/genomes/IMG_Dump/aa/';
FileNames.FastaDirList = 'data/genomes/KAAS/Merged_fileList.csv';
FileNames.KAAS_DB = 'data/genomes/KAAS/Merged_aa.ko.csv'; 
FileNames.Destination.L1 = strcat('data/assemblies/Assembly_L1_',datestr(date,'yyyymmdd'),'.mat');
FileNames.Destination.L2 = strcat('data/assemblies/Assembly_L2_',datestr(date,'yyyymmdd'),'.mat');

%% OPTIONS
SaveMe = 1; % enter 1 to save to Pro_Assembly (L1 and L2)

%% Import orgDatabase
orgDatabase = readtable(FileNames.orgDatabase,'Delimiter',',','ReadVariableNames',true);
nStr = numel(orgDatabase.StrainName);

%% Import KAAS results

KAAS = readtable(FileNames.KAAS_DB,'Delimiter',',','ReadVariableNames',false);

% unique KO's in the PanGEM
uniqueKO = unique(KAAS.Var2);
uniqueKO(1) = [];
nKOs = numel(uniqueKO);

%% Import KAAS Results file order 
% and reorder orgDB to match KAAS results

FastaDirList = readtable(FileNames.FastaDirList,'Delimiter',',','ReadVariableNames',false);
for a = 1:numel(FastaDirList.Var1)
    currentFile_no = str2double(strrep(FastaDirList.Var1{a},'.genes.faa',''));
    orgDB_idx(a) = find(currentFile_no==orgDatabase.FileID);
end


%% Import fastas for each strain

% Preallocate assembly structure
Pro_Assembly = struct;

% Loop through each strain, retrieving and parsing fastas, and assign to
% structure
for a = 1:nStr
    
    % get strain ID
    strName = orgDatabase.StrainName{a};
    
    % load fasta
    fastaFileName = strcat(FileNames.FastaDir,mat2str(orgDatabase.FileID(a)),'.genes.faa');
    fasta = fastaread(fastaFileName);
    
    % count CDS in fasta
    nGenes = size(fasta,1);
    Pro_Assembly.Strains.(strName).nGenes = nGenes;
    
    % retrieve the header from fasta, and the GeneID from each header
    % string (need to loop through)
    fasta_Header = {fasta.Header};
    for b = 1:nGenes
        space_idx = regexp(fasta_Header{b},' ');
        space_idx2 = space_idx(1);
        fasta_ID{b} = fasta_Header{b}(1:space_idx2-1);
    end
    
    % retrieve indices of matching GeneID's in the KAAS results
    [junk, fasta_idx, KAAS_idx] = intersect(fasta_ID,KAAS.Var1);
    
    % assign GeneID, Header and Sequence from fasta, assign KO from KAAS
    Pro_Assembly.Strains.(strName).Header = fasta_Header(fasta_idx);
    Pro_Assembly.Strains.(strName).GeneID = fasta_ID(fasta_idx);
    Pro_Assembly.Strains.(strName).Sequence = {fasta(fasta_idx).Sequence};
    Pro_Assembly.Strains.(strName).KO = KAAS.Var2(KAAS_idx);
    
    % Clean up
    clear fasta_ID space_idx space_idx2 fasta_idx KAAS_idx

end

%% Matrix of presence/absence for each KO

% preallocate matrix
PAMat = zeros(nKOs,nStr);
for a = 1:nStr
    strName = orgDatabase.StrainName{a};
    strKO = Pro_Assembly.Strains.(strName).KO;
    for b = 1:nKOs
        PAMat(b,a) = ismember(uniqueKO{b},strKO);
    end
end

%% Add metadata
Pro_Assembly.uniqueKO = uniqueKO;
Pro_Assembly.orgDatabase = orgDatabase;
Pro_Assembly.FileNames = FileNames;
Pro_Assembly.DateCreated = datestr(date);
Pro_Assembly.PresenceAbsenceMatrix = PAMat;

%% Save L1 structure (careful... pretty giant)
Pro_Assembly_L1 = Pro_Assembly;
if SaveMe
    save(FileNames.Destination.L1,'Pro_Assembly_L1');
end

%% L2 - Remove annotations for each gene for each strain (reduce size)
% The PAMat will do most of what we need down the road and speed things up
% in the process.

Pro_Assembly_L2 = rmfield(Pro_Assembly,'Strains');

if SaveMe
    save(FileNames.Destination.L2,'Pro_Assembly_L2');
end
