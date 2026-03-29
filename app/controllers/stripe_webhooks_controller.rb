class StripeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :ensure_authenticated

  def create
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, ENV["STRIPE_WEBHOOK_SECRET"]
      )
    rescue JSON::ParserError, Stripe::SignatureVerificationError
      head :bad_request
      return
    end

    case event.type
    when "checkout.session.completed"
      handle_checkout_completed(event.data.object)
    when "customer.subscription.updated"
      handle_subscription_updated(event.data.object)
    when "customer.subscription.deleted"
      handle_subscription_deleted(event.data.object)
    when "invoice.payment_failed"
      handle_payment_failed(event.data.object)
    end

    head :ok
  end

  private

  def handle_checkout_completed(session)
    org = Organization.find_by(id: session.metadata["organization_id"])
    return unless org

    was_free = org.needs_subscription?
    subscription = Stripe::Subscription.retrieve(session.subscription)

    period_end = subscription.try(:current_period_end) || subscription.try(:[], :current_period_end)
    org.update!(
      stripe_subscription_id: subscription.id,
      stripe_customer_id: session.customer,
      plan: session.metadata["plan"],
      subscription_status: subscription.status,
      current_period_end: period_end ? Time.at(period_end) : nil
    )

    # Send welcome email on first subscription
    if was_free && org.paid_plan?
      user = org.primary_admin || org.users.first
      WelcomeMailer.welcome(user).deliver_later if user
    end
  end

  def handle_subscription_updated(subscription)
    org = Organization.find_by(stripe_subscription_id: subscription.id)
    return unless org

    plan = plan_from_price(subscription.items.data.first.price.id)

    period_end = subscription.try(:current_period_end) || subscription.try(:[], :current_period_end)
    org.update!(
      plan: plan || org.plan,
      subscription_status: subscription.status,
      current_period_end: period_end ? Time.at(period_end) : nil
    )
  end

  def handle_subscription_deleted(subscription)
    org = Organization.find_by(stripe_subscription_id: subscription.id)
    return unless org

    org.update!(
      plan: "free",
      subscription_status: "canceled",
      stripe_subscription_id: nil
    )
  end

  def handle_payment_failed(invoice)
    org = Organization.find_by(stripe_customer_id: invoice.customer)
    return unless org

    org.update!(subscription_status: "past_due")
  end

  def plan_from_price(price_id)
    case price_id
    when ENV["STRIPE_STARTER_MONTHLY_PRICE_ID"], ENV["STRIPE_STARTER_ANNUAL_PRICE_ID"]
      "starter"
    when ENV["STRIPE_PRO_MONTHLY_PRICE_ID"], ENV["STRIPE_PRO_ANNUAL_PRICE_ID"]
      "pro"
    end
  end
end
