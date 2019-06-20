#NCO_VIEW3
#
# Netcool/OMNIbus View File V7.3.1
#

view_name = 'Predictions';
view_editable = true;
columns = {
{ Node, 'Node', 15, centre, left }
{ TrendDirection, 'TrendDirection', 11, centre, centre }
{ Summary, 'Summary', 30, centre, left }
{ FirstOccurrence, 'First Occurrence', 15, centre, centre }
{ LastOccurrence, 'Last Occurrence', 18, centre, centre }
{ Tally, 'Count', 6, centre, centre }
{ PredictionTime, 'PredictionTime', 19, centre, centre }
num_fixed = 0;
}
sorting = {
{ Severity, desc }
{ LastOccurrence, asc }
{ PredictionTime, asc }
}
# End of file
