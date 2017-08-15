class SitesController < ApplicationController
  before_action :set_site, only: [:edit, :show, :destroy, :update]
  load_and_authorize_resource
  respond_to :html, :json

  def index
    current_user.organization.countries.each do |a|
      @sites << a.sites
      if params[:search]
        @sites = Site.search(params[:search]).order("created_at DESC")
      else
        @sites << a.sites.order('created_at DESC')
      end
    end
    @sites = @sites.page(params[:page]).per(20)
  end

  def show
    @volunteers = User.with_role :volunteer, @site
    @contributors = User.with_role :contributor, @site
  end

  def new
    if current_user.has_role? :superadmin
      @countries = Country.all
    else
      @countries = current_user.organization.countries
    end

    @site = Site.new
  end

  def edit
    if current_user.has_role? :superadmin
      @countries = Country.all
    else
      @countries = current_user.organization.countries
    end
  end

  def create
    @site = Site.new(site_params)

    respond_with(@site) do |format|
      if @site.save
        flash[:notice] = "Site successfully created."
        format.html { redirect_to @site }
      else
        flash[:error] = "Sorry, failed to create site due to errors."
        if current_user.has_role? :superadmin
          @countries = Country.all
        else
          @countries = current_user.organization.countries
        end
        format.html { render 'new' }
      end
    end
  end

  def update
    respond_with(@site) do |format|
      if @site.update(site_params)
        flash[:notice] = "Site successfully updated."
        format.html { redirect_to @site }
      else
        flash[:error] = "Sorry, failed to update site due to errors."
        format.html { render 'edit' }
      end
    end
  end

  def destroy
    @site.destroy

    flash[:notice] = "Site has been deleted."
    redirect_to sites_path
  end


  #####CUSTOM METHODS#####

  #Called from the Sites Show: app/assets/javascripts/components/sites/show.js.jsx.coffee
  # It receives the :username, :site_id, and :act(action) and adds/removes the user as
  # a volunteer/contributor of the given site. It returns the volunteer/contributor list.
  def add_role
    @user = User.where(username: params[:username]).first
    @site = Site.find(params[:site_id])
    action = params[:act]

    if(action == 'volunteer')
      respond_to do |format|
        if @user.add_role :volunteer, @site
          format.json { render json: (User.with_role :volunteer, @site), status: :ok }
          flash[:notice] = "Volunteer successfully added."
          format.html { redirect_to @site }
        else
          format.json { render json: @user.errors, status: :unprocessable_entity }
          flash[:notice] = "Unable to add volunteer."
          format.html { redirect_to @site }
        end
      end
    elsif(action == 'contributor')
      respond_to do |format|
        if @user.add_role :contributor, @site
          format.json { render json: (User.with_role :contributor, @site), status: :ok }
          flash[:notice] = "Contributor successfully added."
          format.html { redirect_to @site }
        else
          format.json { render json: @user.errors, status: :unprocessable_entity}
          flash[:notice] = "Unable to add contributor."
          format.html { redirect_to @site }
        end
      end
    end
  end

  def remove_role
    if params[:user_id].present?
      @user = User.find(params[:user_id])
    elsif params[:username].present?
      @user = User.find_by_username(params[:username])
    end

    @site = Site.find(params[:site_id])
    action = params[:act]

    if(action == 'volunteer')
      respond_to do |format|
        if @user.has_role? :volunteer, @site
          if @user.remove_role :volunteer, @site
            format.json { render json: (User.with_role :volunteer, @site), status: :ok }
            flash[:notice] = "Volunteer successfully deleted."
            format.html { redirect_to @site }
          else
            format.json { render json: @user.errors, status: :unprocessable_entity }
            flash[:notice] = "Unable to delete volunteer."
            format.html { redirect_to @site }
          end
        else
          format.json { render json: @user.errors, status: :unprocessable_entity }
          flash[:notice] = "User not a volunteer for this site."
          format.html { redirect_to @site }
        end
      end
    elsif(action == 'contributor')
      respond_to do |format|
        if @user.has_role? :contributor, @site
          if @user.remove_role :contributor, @site
            format.json { render json: (User.with_role :contributor, @site), status: :ok }
            flash[:notice] = "Contributor successfully added."
            format.html { redirect_to @site }
          else
            format.json { render json: @user.errors, status: :unprocessable_entity}
            flash[:notice] = "Unable to delete contributor."
            format.html { redirect_to @site }
          end
        else
          format.json { render json: @user.errors, status: :unprocessable_entity }
          flash[:notice] = "User not a contributor for this site."
          format.html { redirect_to @site }
        end
      end
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_site
    @site = Site.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def site_params
    params.require(:site).permit(:name, :country_id)
  end
end
