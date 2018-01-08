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
    puts "ORDER IS #{order}"
    puts "ADJUSTMENTS IS #{order.adjustments}"
    puts "COMPETING PROMOS IS #{order.adjustments.competing_promos}"
    puts "PROMO IS #{promo}"
    puts "PROMO TOTAL IS #{promo_total}"
    return promo_total unless promo
    order_total = order.item_total
    puts "ORDER TOTAL IS #{order_total}"
    if order_total == 0.0
    	0.0
    else
    	puts "PROMO AMOUNT IS #{(promo.amount * amount) / order_total}"
    	return ((promo.amount * amount) / order_total)
    end
  end
end
