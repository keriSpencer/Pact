module TenantIsolated
  extend ActiveSupport::Concern

  included do
    # Ensure all queries for tenant-scoped models include organization_id
    default_scope -> {
      if Current.organization
        where(organization_id: Current.organization.id)
      else
        all
      end
    }

    # Validate organization_id matches current tenant on save
    before_save :ensure_tenant_isolation, if: -> { Current.organization.present? }
  end

  private

  def ensure_tenant_isolation
    if organization_id.present? && Current.organization.present? && organization_id != Current.organization.id
      raise TenantIsolationError, "Cannot save record for organization #{organization_id} in tenant #{Current.organization.id}"
    end
  end
end

class TenantIsolationError < StandardError; end
