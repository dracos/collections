require "test_helper"

describe ListSet do
  include RummagerHelpers

  describe "for a curated subtopic" do
    setup do
      @group_data = [
        {
          "name" => "Paying HMRC",
          "contents" => [
           '/pay-paye-tax',
           '/pay-psa',
           '/pay-paye-penalty',
          ]
        },
        {
          "name" => "Annual PAYE and payroll tasks",
          "contents" => [
           '/payroll-annual-reporting',
           '/get-paye-forms-p45-p60',
           '/employee-tax-codes',
          ]
        },
      ]

      rummager_has_documents_for_subtopic(
        "business-tax/paye",
        [
          "employee-tax-codes",
          "get-paye-forms-p45-p60",
          "pay-paye-penalty",
          "pay-paye-tax",
          "pay-psa",
          "payroll-annual-reporting",
        ],
        page_size: RummagerSearch::PAGE_SIZE_TO_GET_EVERYTHING
      )

      @list_set = ListSet.new("specialist_sector", "business-tax/paye", @group_data)
    end

    it "returns the groups in the curated order" do
      assert_equal ["Paying HMRC", "Annual PAYE and payroll tasks"], @list_set.map(&:title)
    end

    it "provides the title and base_path for group items" do
      groups = @list_set.to_a

      assert_equal "Employee tax codes", groups[1].contents.to_a[2].title
      assert_equal "/pay-psa", groups[0].contents.to_a[1].base_path
    end

    it "skips items no longer tagged to this subtopic" do
      @group_data[0]["contents"] << "/pay-bear-tax"

      groups = @list_set.to_a
      assert_equal 3, groups[0].contents.size
      refute groups[0]["contents"].map(&:base_path).include?("/pay-bear-tax")
    end

    it "omits groups with no active items in them" do
      @group_data << {
        "name" => "Group with untagged items",
        "contents" => [
          "/pay-bear-tax",
        ],
      }
      @group_data << {
        "name" => "Empty group",
        "contents" => [],
      }

      assert_equal 2, @list_set.count
      list_titles = @list_set.map(&:title)
      refute list_titles.include?("Group with untagged items")
      refute list_titles.include?("Empty group")
    end
  end

  describe "for a non-curated topic" do
    setup do
      rummager_has_documents_for_subtopic(
        "business-tax/paye",
        [
          "get-paye-forms-p45-p60",
          "pay-paye-penalty",
          "pay-paye-tax",
          "pay-psa",
          "employee-tax-codes",
          "payroll-annual-reporting",
        ],
        page_size: RummagerSearch::PAGE_SIZE_TO_GET_EVERYTHING
      )
      @list_set = ListSet.new("specialist_sector", "business-tax/paye", [])
    end

    it "constructs a single A-Z group" do
      assert_equal 1, @list_set.to_a.size
      assert_equal "A to Z", @list_set.first.title
    end

    it "includes content tagged to the topic in alphabetical order" do
      expected_titles = [
        "Employee tax codes",
        "Get paye forms p45 p60",
        "Pay paye penalty",
        "Pay paye tax",
        "Pay psa",
        "Payroll annual reporting"
      ]
      assert_equal expected_titles, @list_set.first.contents.map(&:title)
    end

    it "includes the base_path for all items" do
      assert_equal "/pay-paye-tax", @list_set.first.contents.to_a[3].base_path
    end

    it "handles nil data the same as empty array" do
      @list_set = ListSet.new("specialist_sector", "business-tax/paye", nil)
      assert_equal 1, @list_set.to_a.size
      assert_equal "A to Z", @list_set.first.title
    end
  end

  describe "fetching content tagged to this tag" do
    setup do
      @subtopic_slug = 'business-tax/paye'
      rummager_has_documents_for_subtopic(@subtopic_slug, [
        'pay-paye-penalty',
        'pay-paye-tax',
        'pay-psa',
        'employee-tax-codes',
        'payroll-annual-reporting',
      ], page_size: RummagerSearch::PAGE_SIZE_TO_GET_EVERYTHING)
    end

    it "returns the content for the tag" do
      expected_titles = [
        'Pay paye penalty',
        'Pay paye tax',
        'Pay psa',
        'Employee tax codes',
        'Payroll annual reporting',
      ]

      assert_equal expected_titles.sort, ListSet.new("specialist_sector", @subtopic_slug).first.contents.map(&:title).sort
    end

    it "provides the title, base_path for each document" do
      documents = ListSet.new("specialist_sector", @subtopic_slug).first.contents

      assert_equal "/pay-paye-tax", documents[2].base_path
      assert_equal "Pay paye tax", documents[2].title
    end
  end

  describe "handling missing fields in the search results" do
    it "handles documents that don't contain the public_timestamp field" do
      result = rummager_document_for_slug('pay-psa')
      result.delete("public_timestamp")

      Services.rummager.stubs(:unified_search).with(
        has_entries(filter_specialist_sectors: ['business-tax/paye'])
      ).returns({
        "results" => [result],
        "start" => 0,
        "total" => 1,
      })

      documents = ListSet.new("specialist_sector", "business-tax/paye").first.contents

      assert_equal 1, documents.to_a.size
      assert_equal 'Pay psa', documents.first.title
      assert_nil documents.first.public_updated_at
    end
  end

  describe "filtering uncurated lists" do
    before do
      @list_set = ListSet.new("section", "browse/abroad/living-abroad")
    end

    it "shouldn't display a document if its format is excluded" do
      rummager_has_documents_for_browse_page(
        'browse/abroad/living-abroad',
        ['baz'],
        ListSet::BROWSE_FORMATS_TO_EXCLUDE.to_a.last,
        page_size: RummagerSearch::PAGE_SIZE_TO_GET_EVERYTHING
      )

      assert_equal 0, @list_set.first.contents.length
    end

    it "should display a document if its format isn't excluded" do
      rummager_has_documents_for_browse_page(
        'browse/abroad/living-abroad',
        ['baz'],
        'some-format-not-excluded',
        page_size: RummagerSearch::PAGE_SIZE_TO_GET_EVERYTHING
      )

      results = @list_set.first.contents
      assert_equal 1, results.length
      assert_equal 'Baz', results.first.title
    end
  end
end
