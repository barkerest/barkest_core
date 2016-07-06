class AccessGroupsController < ApplicationController
  before_action :validate_user

  before_action :set_access_group, only: [:show, :edit, :update, :destroy]

  # GET /access_groups
  def index
    @access_groups = AccessGroup.all.sorted
  end

  # GET /access_groups/1
  def show
  end

  # GET /access_groups/new
  def new
    @access_group = AccessGroup.new
  end

  # GET /access_groups/1/edit
  def edit
  end

  # POST /access_groups
  def create
    @access_group = AccessGroup.new(access_group_params)

    if @access_group.save
      redirect_to access_groups_url, notice: 'Access group was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /access_groups/1
  def update
    if @access_group.update(access_group_params)
      redirect_to access_groups_url, notice: 'Access group was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /access_groups/1
  def destroy
    @access_group.destroy
    redirect_to access_groups_url, notice: 'Access group was successfully destroyed.'
  end

  private

  def validate_user
    authorize! true
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_access_group
    @access_group = AccessGroup.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def access_group_params
    params.require(:access_group).permit(:name, :ldap_group_list)
  end
end
