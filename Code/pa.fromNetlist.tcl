
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name Final_Project -dir "H:/Final_Project/planAhead_run_3" -part xc3s500efg320-4
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "H:/Final_Project/Final_top.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {H:/Final_Project} }
set_property target_constrs_file "Final_top.ucf" [current_fileset -constrset]
add_files [list {Final_top.ucf}] -fileset [get_property constrset [current_run]]
link_design
