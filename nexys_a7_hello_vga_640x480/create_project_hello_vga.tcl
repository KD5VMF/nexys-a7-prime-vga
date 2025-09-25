# Vivado TCL to create the project and add sources/constraints
# File: create_project_hello_vga.tcl
# Usage (from Vivado Tcl Console):
#   cd <path-to-unzipped-folder>
#   source create_project_hello_vga.tcl

set proj_name "nexys_a7_hello_vga"
set proj_dir  [pwd]/build

create_project $proj_name $proj_dir -part xc7a100tcsg324-1 -force

# Add sources
add_files -norecurse [pwd]/top_hello_vga.v
set_property top top_hello_vga [current_fileset]

# Add constraints
add_files -fileset constrs_1 -norecurse [pwd]/Nexys-A7-100T-HELLO-VGA.xdc

# Save project
save_project_as $proj_name $proj_dir -force

puts "Project created at: $proj_dir"
