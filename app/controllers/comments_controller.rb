class CommentsController < ApplicationController
  before_action :set_post, only: [:show, :new, :create]
  before_action :authenticate_user! # or however you handle authentication

  def new
    @comment = @post.comments.build
  end

  def create
    @comment = @post.comments.build(comment_params)
    @comment.author = current_user

    if @comment.save
      # Update the post's comments counter
      @post.increment!(:comments_counter)

      if request.xhr?
        render json: { success: true, message: 'Comment created successfully' }
      else
        redirect_to user_post_path(@post.author, @post), notice: 'Comment created successfully'
      end
    else
      if request.xhr?
        render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
      else
        render :new
      end
    end
  end

    def destroy
    @user = User.find_by(id: params[:user_id])
    @post = @user.posts.find_by(id: params[:post_id])
    @comment = @post.comments.find_by(id: params[:comment_id])
    return render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false if @comment.nil?

    redirect_to user_post_path(@user, params[:post_id])
    if @comment.destroy
      flash[:notice] = 'Comment deleted successfully'
    else
      flash[:alert] = ['Comment not deleted']
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def comment_params
    params.require(:comment).permit(:text)
  end
end