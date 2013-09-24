class DepartmentsController < ApplicationController
  include Drs::ControllerHelpers::EditableObjects 
  
  before_filter :authenticate_user!, only: [:new, :edit, :create, :update, :destroy ]
  #before_filter :can_read?, only: [:show]
  #before_filter :can_edit?, only: [:edit, :update, :destroy]
  #before_filter :can_edit_parent?, only: [:new, :create]

  rescue_from NoParentFoundError, with: :index_redirect
  rescue_from IdNotFoundError, with: :index_redirect_with_bad_id  

  def index
  end

  def show
    @set = Department.find(params[:id])
    render :template => 'shared/show'    
  end

  def new
  end

  def edit
  end

  def update
  end

  protected 

    def index_redirect
      flash[:error] = "Departments cannot be created without a parent" 
      redirect_to departments_path and return 
    end

    def index_redirect_with_bad_id 
      flash[:error] = "The id you specified does not seem to exist in Fedora." 
      redirect_to departments_path and return 
    end  

end