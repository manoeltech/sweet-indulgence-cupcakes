class NotificationsController < ApplicationController
  require_login

  def index
    @notifications = current_user.notifications.recent_first.limit(50).to_a
    current_user.notifications.unread.update_all(read: true)
  end
end
