% This script generates the pin mapping info for the microzed from
% microzed_pinout.xlsx and microzed_mapping.csv.  See README.md.

% The pins table is modified in place to generate the output, overwriting
% the Kicad symbol info with data from the mapping file.
orig_pins = readtable('microzed_pinout.xlsx');
pins = orig_pins;

mapping = table2struct(readtable('microzed_mapping.csv'));

% We are going to create Name column in the output which has the Kicad
% signal name.  Tables don't deal so good with adding columns on the fly,
% so we create this now, initialized to the MicroZed name.
pins.Name = pins.MicroZed_Name;

% Reorder columns to put columns actually used by Kipart first.  We keep
% around the other columns for documentation.
reorder = {'Pin'
           'Unit'
           'Name'
           'Side'
           'Type'
           'Zynq_Pad'
           'MicroZed_Name'
           'Zynq_Name'
           'VCCO_Bank'
           'Notes'};
pins = pins(:, reorder);

% Pins in the 'unused' unit are PL pins available for mapping.
pl_mask = strcmp(pins.Unit, 'unused');

% Used to map from MicroZed Name to the pins record.  uu_names is the
% MicroZed_Name for each record in pins, with the non PL IO pins set to
% 'not_pl'.
global pl_names;
pl_names = pins.MicroZed_Name;
pl_names(~pl_mask) = repmat({'not_pl'}, sum(~pl_mask), 1);

% This keeps track of which PL pins have been used.
global used_mask;
used_mask = false(size(pl_mask));

% For pins that are mapped, what row in the mapping defined them.  Used in
% sort order to preserve the input order for mapped pins.
map_order = zeros(size(pins, 1), 1);

for (ix = 1:length(mapping))
  map1 = mapping(ix);
  sense = map1.Sense;
  if (strcmp(sense, 'DIFF'))
    senses = {'P', '+'
              'N', '-'};
    for (jx = 1:2)
      ix1 = lookup(map1, senses{jx, 1});
      pins.Unit{ix1} = map1.Unit;
      pins.Name{ix1} = [map1.Name senses{jx, 2}];
      pins.Side{ix1} = map1.Side;
      pins.Type{ix1} = map1.Type;
      map_order(ix1) = ix;
    end
  else 
    if (strcmp(sense, 'SE'))
      prefix = [];
    elseif (strcmp(sense, 'SE_P'))
      prefix = 'P';
    elseif (strcmp(sense, 'SE_N'))
      prefix = 'N';
    else
      error('Unknown Sense %s for %s mapping.', sense, map1.Name);
    end
    ix1 = lookup(map1, prefix);
    pins.Unit{ix1} = map1.Unit;
    pins.Name{ix1} = map1.Name;
    pins.Side{ix1} = map1.Side;
    pins.Type{ix1} = map1.Type;
    map_order(ix1) = ix;
  end
end

% Sort the output for pleasing/useful results.  This ordering affects the
% generated symbols in important ways.  The unit label A, B, etc. is set by
% the order in which units are defined.  The order of pins within unit is also
% set here.  The order of non-PL and unused pins is not so important as long
% as it doesn't change, but it seems more useful to sort by unit, then name.
%
% Properties we want: non-PL pins and unused pins come first, the order of
% used PL pins is defined by the mapping file.  Putting non-PL and unused
% first insures that the unit ordering does not change when we add unit.  New
% units should be added to the end of the mapping file so as not to shift the
% association between units.
% ### unit ordering doesn't work right yet.  kipart reverses the unit
% ordering relative to the map file, maybe???  I don't understand how it
% gets the unit ordering.  So maybe we should fix kipart, or reverse the
% units without reversing the pins?
sortkey = cell(size(pins, 1), 4);
for (ix = 1:size(pins, 1))
  sortkey{ix, 1} = sprintf('%d', used_mask(ix));
  sortkey{ix, 2} = pins.Unit{ix};
  sortkey{ix, 3} = sprintf('%03d', map_order(ix));
  sortkey{ix, 4} = pins.Name{ix};  
end
[sorted_keys,ixs] = sortrows(sortkey, {'descend', 'descend', 'ascend', 'ascend'});
pins = pins(ixs, :);

% This seems kind of stupid, but we need to prepend the kipart header to
% the output, so we write to a temp file, read it, append in matlab, and
% write again.  Matlab does not seem to have a standard cross platform file
% utility which can concatenate files.
tempfile = [tempname '.csv'];
writetable(pins(:, 1:5), tempfile);
rows = fileread(tempfile);
delete(tempfile);
header = fileread('kipart_microzed_header.csv');
ofile = 'kipart_microzed.csv';
fid = fopen(ofile, 'w');
if (fid < 0)
  error('Failed to open %s for writing, maybe open in Excel?', ofile);
end
fprintf(fid, '%s', [header rows]);
fclose(fid);

% This table is documentation, with all the annotation data from the input
% microzed_pinout.xlsx, but also parallel to the output
% kipart_microzed.csv, with the defined pin names and symbol units.
writetable(pins, 'kipart_microzed_annotated.csv');


% non-nested local function
% 
% Return the row index in pins of the pin that is specified by the map
% entry struct map1.  Suffix is any P or N suffix for the desired pin.
function [index] = lookup (map1, suffix, pl_names, used_mask)
  global pl_names used_mask;
  mz_name = sprintf('JX%d_%s_%d', map1.JX, map1.Pairing, map1.Line);
  if (~isempty(suffix))
    mz_name = [mz_name '_' suffix];
  end
  index = find(strcmp(mz_name, pl_names));
  if (isempty(index))
    error('Couldn''t find pin %s, maybe not PL IO?', mz_name);
  end
  if (used_mask(index))
    error('Pin %s is already used.', mz_name);
  end
  used_mask(index) = true;
end
