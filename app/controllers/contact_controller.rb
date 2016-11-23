class ContactController < ApplicationController

  def index
    @msg = BarkestCore::ContactMessage.new
  end

  def create
    @msg = get_message
    if @msg.valid? && verify_recaptcha_challenge(@msg)
      @msg.remote_ip = request.remote_ip
      @msg.send_message
      flash[:success] = 'Your message has been sent.'
      redirect_to root_url
    else
      render 'index'
    end
  end

  private

  def get_message
    BarkestCore::ContactMessage.new(params.require(:barkest_core_contact_message).permit(:your_name, :your_email, :related_to, :subject, :body))
  end

end
