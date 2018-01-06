Spree::LineItem.class_eval do
  def tax_cloud_cache_key
    key = "Spree::LineItem #{id}: #{quantity}x<#{variant.cache_key}>@#{price}#{currency}promo_amount<#{promo_total}>"
    if order.ship_address
      key << "shipped_to<#{order.ship_address.try(:cache_key)}>"
    elsif order.bill_address
      key << "billed_to<#{order.bill_address.try(:cache_key)}>"
    end
  end

  def promo_amount
    promo = order.adjustments.competing_promos.eligible.reorder("amount ASC, created_at DESC, id DESC").first
    return promo_total unless promo
    order_total = order.item_total
    return 0.0 unless order_total != 0.0
    (promo.amount * amount) / order_total
  end
end
