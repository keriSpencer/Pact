require "test_helper"

class SignatureTemplateTest < ActiveSupport::TestCase
  test "valid with required attributes" do
    template = build(:signature_template)
    assert template.valid?
  end

  test "requires name" do
    template = build(:signature_template, name: nil)
    assert_not template.valid?
    assert_includes template.errors[:name], "can't be blank"
  end

  test "name must be unique per document" do
    template1 = create(:signature_template)
    template2 = build(:signature_template, name: template1.name, document: template1.document)
    assert_not template2.valid?
  end

  test "allows same name on different documents" do
    template1 = create(:signature_template, name: "Standard")
    other_doc = create(:document)
    template2 = build(:signature_template, name: "Standard", document: other_doc)
    assert template2.valid?
  end

  test "increment_usage! updates use_count and last_used_at" do
    template = create(:signature_template)
    assert_equal 0, template.use_count
    assert_nil template.last_used_at

    template.increment_usage!
    template.reload

    assert_equal 1, template.use_count
    assert_not_nil template.last_used_at
  end

  test "fields_as_json returns template fields as array of hashes" do
    template = create(:signature_template, :with_fields)
    json = template.fields_as_json

    assert_equal 2, json.length
    assert_equal "signature", json[0][:field_type]
    assert_equal "date", json[1][:field_type]
    assert json[0].key?(:page_number)
    assert json[0].key?(:x_percent)
    assert json[0].key?(:y_percent)
  end

  test "destroying template destroys fields" do
    template = create(:signature_template, :with_fields)
    assert_equal 2, template.template_fields.count

    assert_difference "SignatureTemplateField.count", -2 do
      template.destroy
    end
  end
end
