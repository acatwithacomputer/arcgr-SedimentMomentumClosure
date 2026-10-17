import sys
#sys.exit()

OpenDatabase("dumps.visit", 0)
opts = GetExportOptions("VTK")
opts['FileFormat']='XML Ascii'
#print(opts)

for i in range(TimeSliderGetNStates()):
    # Change time states
    SetTimeSliderState(i)
    #DrawPlots()

    # Export the database
    dbAtts = ExportDBAttributes()
    dbAtts.db_type = "VTK"
    dbAtts.filename = "file%04d" % i
    # Tuple of variables to export. "default" means the plotted variable.
    # Note that we're also exporting the vector expression "vec"
    dbAtts.variables = ("P", "U", "amr_mesh")
    ExportDatabase(dbAtts,opts)

sys.exit()