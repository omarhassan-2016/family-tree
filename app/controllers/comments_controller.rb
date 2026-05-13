class CommentsController < ApplicationController
  def create
    @commentable = find_commentable
    @comment = @commentable.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to polymorphic_path(@commentable), notice: "Comment posted."
    else
      redirect_to polymorphic_path(@commentable), alert: "Failed to post comment."
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    
    # Only the author or an admin can delete a comment
    if @comment.user == current_user || current_user.admin?
      @comment.destroy
      redirect_back fallback_location: root_path, notice: "Comment deleted."
    else
      redirect_back fallback_location: root_path, alert: "You don't have permission to delete this comment."
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body)
  end

  def find_commentable
    if params[:person_id]
      Person.find(params[:person_id])
    end
  end
end
