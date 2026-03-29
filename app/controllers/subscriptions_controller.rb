class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!, only: [:checkout, :portal]

  def billing
    @organization = current_organization

    # Sync from Stripe when returning from checkout or portal
    if (params[:upgraded] || params[:synced]) && @organization.stripe_customer_id.present?
      sync_subscription_from_stripe
    end
  end

  def checkout
    plan = params[:plan]
    interval = params[:interval] || "monthly"

    price_id = stripe_price_id(plan, interval)
    unless price_id
      redirect_to billing_path, alert: "Invalid plan selected."
      return
    end

    customer = find_or_create_stripe_customer

    checkout_params = {
      customer: customer.id,
      mode: "subscription",
      line_items: [{ price: price_id, quantity: 1 }],
      success_url: billing_url + "?upgraded=1",
      cancel_url: billing_url,
      subscription_data: { trial_period_days: 14 },
      metadata: {
        organization_id: current_organization.id,
        plan: plan
      }
    }

    # Skip trial if org already had a subscription (returning customer)
    if current_organization.stripe_customer_id.present? && current_organization.current_period_end.present?
      checkout_params.delete(:subscription_data)
    end

    session = Stripe::Checkout::Session.create(checkout_params)

    redirect_to session.url, allow_other_host: true
  end

  def portal
    unless current_organization.stripe_customer_id
      redirect_to billing_path, alert: "No billing account found."
      return
    end

    session = Stripe::BillingPortal::Session.create(
      customer: current_organization.stripe_customer_id,
      return_url: billing_url + "?synced=1"
    )

    redirect_to session.url, allow_other_host: true
  end

  private

  def find_or_create_stripe_customer
    if current_organization.stripe_customer_id
      Stripe::Customer.retrieve(current_organization.stripe_customer_id)
    else
      customer = Stripe::Customer.create(
        email: current_user.email,
        name: current_organization.name,
        metadata: { organization_id: current_organization.id }
      )
      current_organization.update!(stripe_customer_id: customer.id)
      customer
    end
  end

  def sync_subscription_from_stripe
    subscriptions = Stripe::Subscription.list(customer: current_organization.stripe_customer_id, limit: 1)
    sub = subscriptions.data.first
    return unless sub

    plan = plan_from_stripe_price(sub.items.data.first.price.id)
    period_end = sub.try(:current_period_end) || sub.try(:[], :current_period_end)
    current_organization.update!(
      stripe_subscription_id: sub.id,
      plan: plan || "starter",
      subscription_status: sub.status,
      current_period_end: period_end ? Time.at(period_end) : nil
    )
    @organization.reload
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe sync failed: #{e.message}"
  end

  def plan_from_stripe_price(price_id)
    case price_id
    when ENV["STRIPE_STARTER_MONTHLY_PRICE_ID"], ENV["STRIPE_STARTER_ANNUAL_PRICE_ID"]
      "starter"
    when ENV["STRIPE_PRO_MONTHLY_PRICE_ID"], ENV["STRIPE_PRO_ANNUAL_PRICE_ID"]
      "pro"
    end
  end

  def stripe_price_id(plan, interval)
    {
      "starter" => {
        "monthly" => ENV["STRIPE_STARTER_MONTHLY_PRICE_ID"],
        "annual" => ENV["STRIPE_STARTER_ANNUAL_PRICE_ID"]
      },
      "pro" => {
        "monthly" => ENV["STRIPE_PRO_MONTHLY_PRICE_ID"],
        "annual" => ENV["STRIPE_PRO_ANNUAL_PRICE_ID"]
      }
    }.dig(plan, interval)
  end
end
