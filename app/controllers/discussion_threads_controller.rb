##########################################################################
# Copyright 2009 Applied Research in Patacriticism and the University of Virginia
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################

class DiscussionThreadsController < ApplicationController
  layout 'collex_tabs'
  before_filter :init_view_options

   # Number of search results to display by default
   MIN_ITEMS_PER_PAGE = 10
   MAX_ITEMS_PER_PAGE = 30

    private
  def init_view_options
    @use_tabs = true
    @use_signin= true
    @site_section = :discuss
    @uses_yui = true
    return true
  end
  public

  def start_discussion
    if !is_logged_in?
      flash[:error] = 'You must be signed in to start a discussion.'
      redirect_to :action => :index
    end
  end
  
  def post_comment_to_new_thread
    if !is_logged_in?
      flash[:error] = 'You must be signed in to start a discussion.'
    else
      topic_id = params[:topic_id]
      title = params[:title]
      comment = params[:comment]
      user = User.find_by_username(session[:user][:username])
      
      thread = DiscussionThread.create(:discussion_topic_id => topic_id, :title => title)
      DiscussionComment.create(:discussion_thread_id => thread.id, :user_id => user.id, :position => 1, :comment_type => 'comment', :comment => comment)
    end

    redirect_to :action => :index
  end
  
  def post_comment_to_existing_thread
    thread_id = params[:thread_id]
    if !is_logged_in?
      flash[:error] = 'You must be signed in to post a comment.'
    else
      comment = params[:new_comment]
      user = User.find_by_username(session[:user][:username])
      thread = DiscussionThread.find(thread_id)
      DiscussionComment.create(:discussion_thread_id => thread_id, :user_id => user.id, :position => thread.discussion_comments.length, :comment_type => 'comment', :comment => comment)
    end

    redirect_to :action => :view_thread, :thread => thread_id
  end
  
  def post_object_to_new_thread
    if !is_logged_in?
      flash[:error] = 'You must be signed in to start a discussion.'
    else
      topic_id = params[:topic_id]
      thread = DiscussionThread.create(:discussion_topic_id => topic_id, :title => "")
      post_object(thread, params)
    end

    redirect_to :action => :index
  end
  
  def post_object_to_existing_thread
    if !is_logged_in?
      flash[:error] = 'You must be signed in to post an object.'
    else
      thread_id = params[:thread_id]
      thread = DiscussionThread.find(thread_id)
      post_object(thread, params)
    end

    redirect_to :action => :view_thread, :thread => thread_id
  end
  
  private
  def post_object(thread, params)
    disc_type = params[:disc_type]
    nines_object = params[:nines_object]
    inet_thumbnail = params[:inet_thumbnail]
    inet_url = params[:inet_url]
    inet_description = params[:inet_description]
    nines_exhibit = params[:nines_exhibit]
    user = User.find_by_username(session[:user][:username])
    
    if ExhibitIllustration.get_illustration_type_nines_obj() == disc_type
      cr = CachedResource.find_by_uri(nines_object)
      DiscussionComment.create(:discussion_thread_id => thread.id, :user_id => user.id, :position => 1, 
        :comment_type => 'nines_object', :cached_resource_id => cr.id)
    elsif ExhibitIllustration.get_exhibit_type_text() == disc_type
      exhibit = Exhibit.find_by_title(nines_exhibit)
      DiscussionComment.create(:discussion_thread_id => thread.id, :user_id => user.id, :position => 1, 
        :comment_type => 'nines_exhibit', :exhibit_id => exhibit.id)
    elsif ExhibitIllustration.get_illustration_type_image() == disc_type
      DiscussionComment.create(:discussion_thread_id => thread.id, :user_id => user.id, :position => 1, 
        :comment_type => 'inet_object', :link_url => inet_url, :image_url => inet_thumbnail, :comment => inet_description)
    end
  end
  public
  
  def view_thread
    thread_id = params[:thread]
    @thread = DiscussionThread.find(thread_id)
    @page = 1
    @num_pages = 2
  end
  
  def delete_comment
    discussion_comment = DiscussionComment.find(params[:comment])
    thread_id = discussion_comment.discussion_thread_id
    
    if !is_logged_in?
      flash[:error] = 'You must be signed in to delete a comment.'
    else
      user = User.find_by_username(session[:user][:username])
      if !is_admin? && user.id != discussion_comment.id
        flash[:error] = 'You must own the comment to delete it.'
      else
        ok_to_delete = true
        redirect_to_index = false
        if discussion_comment.position == 1 # the first comment is privileged and will delete the thread
          if discussion_comment.discussion_thread.discussion_comments.length == 1 # only delete the first comment if there are no follow up comments
            discussion_comment.discussion_thread.destroy
            redirect_to_index = true
          else
            ok_to_delete = false
          end
        end
      end
      discussion_comment.destroy if ok_to_delete
    end
    
    if redirect_to_index
      redirect_to :action => :index
    else
      redirect_to :action => :view_thread, :thread => thread_id
    end
  end
  
  def report_comment
    if !is_logged_in?
      flash[:error] = 'You must be signed in to delete a comment.'
    else
      user = User.find_by_username(session[:user][:username])
      comment_id = params["comment_id"]
      comment = DiscussionComment.find(comment_id)
      comment.reported = 1
      comment.reporter_id = user.id
      comment.save
      # TODO-PER: actually send email at this point
      redirect_to :action => :view_thread, :thread => comment.discussion_thread_id
    end
  end
  
  def rss
     thread_id = params[:thread]
     thread = DiscussionThread.find(thread_id)
     
     #@items = [ { :title => 'first', :description => 'this is the first'}, { :title => 'second', :description => 'another entry' } ]
     render :partial => 'rss', :locals => { :thread => thread }
  end
  
   def result_count
     session[:items_per_page] ||= MIN_ITEMS_PER_PAGE
     requested_items_per_page = params['search'] ? params['search']['result_count'].to_i : session[:items_per_page] 
     session[:items_per_page] = (requested_items_per_page <= MAX_ITEMS_PER_PAGE) ? requested_items_per_page : MAX_ITEMS_PER_PAGE
     redirect_to :action => 'view_thread'
   end
  
## GET /discussion_threads
#  # GET /discussion_threads.xml
#  def index
#    @discussion_threads = DiscussionThread.find(:all)
#
#    respond_to do |format|
#      format.html # index.html.erb
#      format.xml  { render :xml => @discussion_threads }
#    end
#  end
#
#  # GET /discussion_threads/1
#  # GET /discussion_threads/1.xml
#  def show
#    @discussion_thread = DiscussionThread.find(params[:id])
#
#    respond_to do |format|
#      format.html # show.html.erb
#      format.xml  { render :xml => @discussion_thread }
#    end
#  end
#
#  # GET /discussion_threads/new
#  # GET /discussion_threads/new.xml
#  def new
#    @discussion_thread = DiscussionThread.new
#
#    respond_to do |format|
#      format.html # new.html.erb
#      format.xml  { render :xml => @discussion_thread }
#    end
#  end
#
#  # GET /discussion_threads/1/edit
#  def edit
#    @discussion_thread = DiscussionThread.find(params[:id])
#  end
#
#  # POST /discussion_threads
#  # POST /discussion_threads.xml
#  def create
#    @discussion_thread = DiscussionThread.new(params[:discussion_thread])
#
#    respond_to do |format|
#      if @discussion_thread.save
#        flash[:notice] = 'DiscussionThread was successfully created.'
#        format.html { redirect_to(@discussion_thread) }
#        format.xml  { render :xml => @discussion_thread, :status => :created, :location => @discussion_thread }
#      else
#        format.html { render :action => "new" }
#        format.xml  { render :xml => @discussion_thread.errors, :status => :unprocessable_entity }
#      end
#    end
#  end
#
#  # PUT /discussion_threads/1
#  # PUT /discussion_threads/1.xml
#  def update
#    @discussion_thread = DiscussionThread.find(params[:id])
#
#    respond_to do |format|
#      if @discussion_thread.update_attributes(params[:discussion_thread])
#        flash[:notice] = 'DiscussionThread was successfully updated.'
#        format.html { redirect_to(@discussion_thread) }
#        format.xml  { head :ok }
#      else
#        format.html { render :action => "edit" }
#        format.xml  { render :xml => @discussion_thread.errors, :status => :unprocessable_entity }
#      end
#    end
#  end
#
#  # DELETE /discussion_threads/1
#  # DELETE /discussion_threads/1.xml
#  def destroy
#    @discussion_thread = DiscussionThread.find(params[:id])
#    @discussion_thread.destroy
#
#    respond_to do |format|
#      format.html { redirect_to(discussion_threads_url) }
#      format.xml  { head :ok }
#    end
#  end
end
