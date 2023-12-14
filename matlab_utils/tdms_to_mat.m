function out_file = tdms_to_mat(filename, save_dir, save_filename)
%function out_file = tdms_to_mat(filename, save_dir='.',
%                         save_filename={filename, but replace tdms with mat'})
%
% Converts a TDMS file to MAT format. The MAT fields will be the same as the
% TDMS fields, except with parentheses removed and whitespace replaced with
% underscores.
%MAT file will h
%
% Inputs:
% 
% - filename: path to the TDMS file
%
% - save_dir: directory in which to save the file. Defaults to the current dir.
%
% - save_filename: name of the MAT file. Defaults to be the same as the TDMS
%                  file, but .tdms is replaced with .mat.
%
    if nargin < 2
        save_dir = '.';
    end
    if nargin < 3
        filename_split = split(filename, '/');
        save_filename = strcat(replace(filename_split{end}, '.tdms', ''), '.mat');
    end
    
    addpath('load_tdms');
    addpath('load_tdms/tdmsSubfunctions');

    data = TDMS_readTDMSFile(filename);

    s = struct;
    for i=1:size(data.chanNames{1}, 2)
        name = regexprep(data.chanNames{1}{i}, '\s', '_'); % replace whitespace with underscores
        name = regexprep(name, '\(|\)', ''); % remove parentheses 
        s.(name) = data.data{data.chanIndices{1}(i)};
    end

    save(strcat(save_dir, '/', save_filename), '-struct', 's');