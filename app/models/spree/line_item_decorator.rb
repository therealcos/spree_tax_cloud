Spree::LineItem.class_eval do
  def tax_cloud_cache_key
    key = "Spree::LineItem #{id}: #{quantity}x<#{variant.cache_key}>@#{price}#{currency}promo_total<#{promo_total}>"
    if order.ship_address
      key << "shipped_to<#{order.ship_address.try(:cache_key)}>"
    elsif order.bill_address
      key << "billed_to<#{order.bill_address.try(:cache_key)}>"
    end
  end
end
