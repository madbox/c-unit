class ConfUnitsController < ApplicationController
  def index
    @conf_units = ConfUnit.all
    @roots = ConfUnit.roots
  end

  def update
    @conf_unit = ConfUnit.find(params[:id])
    if @conf_unit.update_attributes(params[:conf_unit])
      flash['notice'] = I18n.t('notice.updated')
      redirect_to :action => 'show', :id => @conf_unit.id
    else
      flash['error'] = I18n.t('errors.update_failed')
      render 'edit'
    end
  end

  def create
    @conf_unit = ConfUnit.new(params[:conf_unit])
    
    if @conf_unit.save
      flash['notice'] = I18n.t('notice.created')
      redirect_to :action => 'index'
    else
      flash['error'] = I18n.t('errors.creation_failed')
      render 'new'
    end
  end

  def new
    @parent_conf_unit = ConfUnit.find( params[:id] ) unless params[:id].blank?
    @conf_unit = ConfUnit.new( :parent => @parent_conf_unit )
  end

  def show
    @conf_unit = ConfUnit.find(params[:id])
    @children = @conf_unit.children

    @parent_broken = @conf_unit.ancestors.select{|a|a.broken}.size > 0
  end

  def edit
    @conf_unit = ConfUnit.find(params[:id])

  end

  def destroy
    @conf_unit = ConfUnit.find(params[:id])
    @conf_unit.destroy
    
    flash['notice'] = I18n.t('notice.deleted')
    redirect_to :action => 'index'
  end

  def status_message
    @text = ConfUnit.generate_status_message
  end

  def show_properties
    @conf_unit = ConfUnit.find(params[:id])
  end

  def edit_properties
    @conf_unit = ConfUnit.find(params[:id])
  end

  def update_properties
    @conf_unit = ConfUnit.find(params[:id])
   
    if @conf_unit.update_properties( params[:properties] )
      flash['notice'] = I18n.t('notice.updated')
      redirect_to show_conf_unit_properties_path
    else
      flash['error'] = I18n.t('errors.update_failed')
      render 'edit_properties'
    end
  end

  def view_conf_unit_kinds_config_file
    @config_text = File.read( CONF_UNIT_KINDS_CONFIG )
    @locale_text = File.read( File.join(RAILS_ROOT, 'config', 'locales', 'ru.yml') )
  end
end
