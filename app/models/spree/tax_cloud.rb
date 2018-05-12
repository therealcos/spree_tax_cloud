module Spree
  class TaxCloud

    def self.update_config
      ::TaxCloud.configure do |config|
        config.api_login_id = Spree::Config.taxcloud_api_login_id
        config.api_key = Spree::Config.taxcloud_api_key
        config.usps_username = Spree::Config.taxcloud_usps_user_id
      end
    end

    def self.transaction_from_item(item)
      stock_location = item.try(:stock_location) || item.try(:variant).try(:stock_locations).select{|sl| sl.supplier_id == item.variant.suppliers.first.id}.try(:first)
      raise Spree.t(:ensure_one_valid_stock_location) unless stock_location

      order = item.order

      transaction = ::TaxCloud::Transaction.new(
        customer_id: order.user_id || order.email,
        order_id: order.number,
        cart_id: order.number,
        origin: address_from_spree_address(stock_location),
        destination: address_from_spree_address(order.ship_address || order.bill_address)
      )

      index = -1 # array is zero-indexed
      # Prepare line_items for lookup
      order.line_items.each { |line_item| transaction.cart_items << cart_item_from_item(line_item, index += 1) if line_item.product.taxable }
      # Prepare shipments for lookup
      order.shipments.each { |shipment| transaction.cart_items << cart_item_from_item(shipment, index += 1) }
      transaction
    end

    # Note that this method can take either a Spree::StockLocation (which has address
    # attributes directly on it) or a Spree::Address object
    def self.address_from_spree_address(address)
      ::TaxCloud::Address.new(
        address1: address.address1,
        address2: address.address2,
        city:     address.city,
        state:    address.try(:state).try(:abbr),
        zip5:     address.zipcode.try(:[], 0...5)
      )
    end

    def self.cart_item_from_item(item, index)
      case item
      when Spree::LineItem
        order_promo = item.order.adjustments.competing_promos.eligible.reorder("amount ASC, created_at DESC, id DESC").first
        order_promo_amount = order_promo ? (order_promo.amount / item.order.quantity) : 0
        puts "order_promo.amount is #{order_promo.amount}" if order_promo
        puts "item.order.quantity is #{item.order.quantity}" if order_promo
        puts "order_promo_amount is #{order_promo_amount}" if order_promo
        ::TaxCloud::CartItem.new(
          index:    index,
          item_id:  item.try(:variant).try(:sku).present? ? item.try(:variant).try(:sku) : "LineItem #{item.id}",
          tic:      (item.product.tax_cloud_tic || Spree::Config.taxcloud_default_product_tic),
          price:    item.quantity == 0 ? item.price : (item.promo_total / item.quantity) + order_promo_amount + item.price,
          quantity: item.quantity
        )
      when Spree::Shipment
        ::TaxCloud::CartItem.new(
          index:    index,
          item_id:  "Shipment #{item.number}",
          tic:      Spree::Config.taxcloud_shipping_tic,
          price:    item.cost,
          quantity: 1
        )
      else
        raise Spree.t(:cart_item_cannot_be_made)
      end
    end
  end
end
