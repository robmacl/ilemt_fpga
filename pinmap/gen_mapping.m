% This script generates the pin mapping info for the microzed from
% microzed_pinout.xlsx and microzed_mapping.csv.  See README.md.

% The pins table is modified in place to generate the output, overwriting
% the Kicad symbol info with data from the mapping file.
orig_pins = readtable('microzed_pinout.xlsx');
pins = orig_pins;

% The variable part of the mapping
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
map_order = map_order(ixs);

% Matlab does not seem to have a standard cross platform file utility which
% can concatenate files.  This seems kind of stupid, but we need to prepend
% the kipart header to the output, so we write to a temp file, read it, append
% in matlab, and write again.
tempfile = [tempname '.csv'];
writetable(pins(:, 1:5), tempfile);
rows = fileread(tempfile);
delete(tempfile);
header = fileread('kipart_microzed_header.csv');
ofile = 'kipart_microzed.csv';
fid = fopen(ofile, 'w');
if (fid < 0)
  error('Failed to open %s for writing, maybe it''s open in Excel?', ofile);
end
fprintf(fid, '%s', [header rows]);
fclose(fid);

% This table is documentation, with all the annotation data from the input
% microzed_pinout.xlsx, but also parallel to the output
% kipart_microzed.csv, with the defined pin names and symbol units.
writetable(pins, 'kipart_microzed_annotated.csv');

% Vivado pin mapping via CSV file.  We only generate output for the pins which
% are mapped (microzed_mapping.csv).  All the info comes from there except the
% Zynq_Pad.  We use the "Single Port Diff Pair" CSV format so that we have
% just one line per pair, and can stay parallel to mapping.
% 
% The IO standard is fixed for each type (diff and SE).  We could put
% signalling info into the mapping file, but at the moment this would be
% gratuitous generality.
%{
Zynq_Pad (from microzed_pinout) => Pin Number
Unit => Interface
Name => Signal Name
Type => Direction

Standard fixed values for these:
  Either 2.5V slow CMOS or LVDS (w/ term on inputs)

DiffPair Type
DiffPair Signal
IO Standard
Drive
Slew Rate
DIFF_TERM
%}

viv_names = {
    'Pin Number'
    'Interface'		
    'Signal Name'
    'Direction'
    'DiffPair Type'
    'DiffPair Signal'
    'IO Standard'
    'Drive (mA)'
    'Slew Rate'
    'DIFF_TERM'
};

vivado_mapping = cell2table(repmat({''}, length(mapping), length(viv_names)));
vivado_mapping.Properties.VariableNames = viv_names;

pin_verilog = 'pin_defs_verilog.v';
ofile = fopen(pin_verilog, 'w');
if (ofile < 0)
  error('Failed to open %s for writing', pin_verlog);
end

obuf_format = 'OBUFDS OBUFDS_%s (.O(%s), .OB(%s), .I(%s));\n';
ibuf_format = 'IBUFDS IBUFDS_%s (.O(%s), .I(%s), .IB(%s));\n';

for (ix = 1:length(mapping))
  pin_ix = find(map_order == ix, 1, 'first');
  vivado_mapping{ix, 'Pin Number'} = {string(pins{pin_ix, 'Zynq_Pad'})};
  vivado_mapping{ix, 'Interface'} = {mapping(ix).Unit};
  dir1 = mapping(ix).Type;
  if (strcmp(dir1, 'in'))
    dir1 = 'IN';
  elseif (strcmp(dir1, 'out'))
    dir1 = 'OUT';
  else
    error('Line %d, unknown direction: %s', ...
          ix+1, dir1);
  end
  vivado_mapping{ix, 'Direction'} = {dir1};
  
  sense1 = mapping(ix).Sense;
  if (strcmp(sense1, 'DIFF'))
    name = mapping(ix).Name;
    p_name = [name '_P'];
    n_name = [name '_N'];
    vivado_mapping{ix, 'Signal Name'} = {p_name};
    vivado_mapping{ix, 'DiffPair Signal'} = {n_name};
    vivado_mapping{ix, 'IO Standard'} = {'LVDS_25'};
    vivado_mapping{ix, 'DiffPair Type'} = {'P'};
    fprintf(ofile, 'wire %s;\n', name);
    if (strcmp(dir1, 'IN'))
      vivado_mapping{ix, 'DIFF_TERM'} = {'TRUE'};
      fprintf(ofile, ibuf_format, name, name, p_name, n_name);
    else
      vivado_mapping{ix, 'DIFF_TERM'} = {'FALSE'};
      fprintf(ofile, obuf_format, name, p_name, n_name, name);
    end
    
  else
    vivado_mapping{ix, 'Signal Name'} = {mapping(ix).Name};
    vivado_mapping{ix, 'IO Standard'} = {'LVCMOS25'};
    vivado_mapping{ix, 'Drive (mA)'} = {'4'};
    vivado_mapping{ix, 'Slew Rate'} = {'SLOW'};
  end
end

writetable(vivado_mapping, 'vivado_pin_defs.csv');
fclose(ofile);


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
