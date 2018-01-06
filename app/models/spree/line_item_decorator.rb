Spree::LineItem.class_eval do
  def tax_cloud_cache_key
    key = "Spree::LineItem #{id}: #{quantity}x<#{variant.cache_key}>@#{price}#{currency}promo_total<#{promo_total}>"
    if order.ship_address
      key << "shipped_to<#{order.ship_address.try(:cache_key)}>"
    elsif order.bill_address
      key << "billed_to<#{order.bill_address.try(:cache_key)}>"
    end
  end

  def promo_amount
    promo = order.promotion
    return promo_total unless promo
    order_total = order.item_total
    return 0.0 unless order_total != 0.0
    (promo.amount * amount) / order_total
  end

  def discounted_amount
    amount + promo_amount
  end
end
