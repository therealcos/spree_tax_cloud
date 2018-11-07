Spree::CheckoutController.class_eval do
  rescue_from SpreeTaxCloud::Error do |exception|
    flash[:error] = exception.message
    redirect_to checkout_state_path(:address)
  end

  rescue_from TaxCloud::Errors::ApiError do |exception|
  	puts "TaxCloud Error: #{exception.message}"
    flash[:error] = Spree.t(:address_verification_failed)
    redirect_to checkout_state_path(:address)
  end
end
