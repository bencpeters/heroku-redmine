# Redmine - project management software
# Copyright (C) 2006-2012  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class GroupsController < ApplicationController
  layout 'admin'

  before_filter :require_admin
  before_filter :find_group, :only => [:show, :edit, :update, :destroy, :add_users, :remove_user, :autocomplete_for_user, :edit_membership, :destroy_membership]

  helper :custom_fields

  def index
    @groups = Group.find(:all, :order => 'lastname')

    respond_to do |format|
      format.html
      format.xml  { render :xml => @groups }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.xml  { render :xml => @group }
    end
  end

  def new
    @group = Group.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @group }
    end
  end

  def create
    @group = Group.new
    @group.safe_attributes = params[:group]

    respond_to do |format|
      if @group.save
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to(params[:continue] ? new_group_path : groups_path)
        }
        format.xml  { render :xml => @group, :status => :created, :location => @group }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    @group.safe_attributes = params[:group]

    respond_to do |format|
      if @group.save
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_to(groups_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @group.destroy

    respond_to do |format|
      format.html { redirect_to(groups_url) }
      format.xml  { head :ok }
    end
  end

  def add_users
    users = User.find_all_by_id(params[:user_ids])
    @group.users << users if request.post?
    respond_to do |format|
      format.html { redirect_to :controller => 'groups', :action => 'edit', :id => @group, :tab => 'users' }
      format.js {
        render(:update) {|page|
          page.replace_html "tab-content-users", :partial => 'groups/users'
          users.each {|user| page.visual_effect(:highlight, "user-#{user.id}") }
        }
      }
    end
  end

  def remove_user
    @group.users.delete(User.find(params[:user_id])) if request.delete?
    respond_to do |format|
      format.html { redirect_to :controller => 'groups', :action => 'edit', :id => @group, :tab => 'users' }
      format.js { render(:update) {|page| page.replace_html "tab-content-users", :partial => 'groups/users'} }
    end
  end

  def autocomplete_for_user
    @users = User.active.not_in_group(@group).like(params[:q]).all(:limit => 100)
    render :layout => false
  end

  def edit_membership
    @membership = Member.edit_membership(params[:membership_id], params[:membership], @group)
    @membership.save if request.post?
    respond_to do |format|
      if @membership.valid?
        format.html { redirect_to :controller => 'groups', :action => 'edit', :id => @group, :tab => 'memberships' }
        format.js {
          render(:update) {|page|
            page.replace_html "tab-content-memberships", :partial => 'groups/memberships'
            page.visual_effect(:highlight, "member-#{@membership.id}")
          }
        }
      else
        format.js {
          render(:update) {|page|
            page.alert(l(:notice_failed_to_save_members, :errors => @membership.errors.full_messages.join(', ')))
          }
        }
      end
    end
  end

  def destroy_membership
    Member.find(params[:membership_id]).destroy if request.post?
    respond_to do |format|
      format.html { redirect_to :controller => 'groups', :action => 'edit', :id => @group, :tab => 'memberships' }
      format.js { render(:update) {|page| page.replace_html "tab-content-memberships", :partial => 'groups/memberships'} }
    end
  end

  private

  def find_group
    @group = Group.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
