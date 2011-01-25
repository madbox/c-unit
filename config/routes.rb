ActionController::Routing::Routes.draw do |map|
  map.resources :conf_units
  map.add_child_conf_units 'conf_unit/:id/add_child', :controller => 'conf_units', :action => 'new'
  map.show_conf_unit_properties 'conf_unit/:id/show_properties', :controller => 'conf_units', :action => 'show_properties'
  map.edit_conf_unit_properties 'conf_unit/:id/edit_properties', :controller => 'conf_units', :action => 'edit_properties'
  map.update_conf_unit_properties 'conf_unit/:id/update_properties', :controller => 'conf_units', :action => 'update_properties'
  map.view_configs 'conf_unit/view_configs', :controller => 'conf_units', :action => 'view_conf_unit_kinds_config_file'

  map.status_message 'status_message', :controller => 'conf_units', :action => 'status_message'

  map.root :controller => "conf_units"

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
