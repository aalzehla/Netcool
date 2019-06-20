#NCO_VIEW3
#
# Netcool/OMNIbus View File 8.1.0 
#

view_name = 'Default';
view_editable = true;
columns = {
{ Node, 'Node', 15, centre, left }
{ AlertGroup, 'Alert Group', 18, centre, left }
{ Summary, 'Summary', 60, centre, left }
{ LastOccurrence, 'Last Occurrence', 15, centre, centre }
{ Tally, 'Count', 6, centre, centre }
{ Type, 'Type', 12, centre, left }
{ ExpireTime, 'ExpireTime', 10, centre, centre }
{ Agent, 'Agent', 25, centre, left }
{ Manager, 'Manager', 25, centre, left }
num_fixed = 1;
}
sorting = {
{ Severity, desc }
{ LastOccurrence, desc }
{ Node, asc }
{ AlertGroup, asc }
{ AlertKey, asc }
{ Summary, asc }
}
# End of file
