%%%%% Concatenating months of data %%%%%

%%% Created to easily be able to combine two datasets into one .mat file
% Maia H. July 2026


% Notes to myself:
% I want this to be a function that I can easily call by just putting in
% two datasets into the call line. The function should be able to read in
% the .mat files, determine what type of data they are, and concatenate
% them in time accordingly. So .mat files with ruskin structures will be
% different than .mat files with tables vs. SWIFT files, etc.

% The function call should have the inputs be the .mat files I am
% interested in, so the number of varargin will vary. When naming the final
% data product, the function should ask the user what months they want to
% concatenate/are represented in the data for the sake of the file name.
% The user should then input the month names into the command line and the
% function will take that input and make it part of the file name. 