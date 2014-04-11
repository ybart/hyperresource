require 'test_helper'

describe HyperResource::Adapter::JSON_API do
  before do
    @rsrc = HyperResource.new(adapter: HyperResource::Adapter::JSON_API)
    @rsrc.adapter.apply(JSON_API_BODY, @rsrc)
  end

  describe 'apply' do
    it "parse attributes" do
      @rsrc.baskets.last.id.must_equal '550e8400-e29b-41d4-a716-446655440000'
      @rsrc.baskets.last.name.must_equal 'Kitchen fruit basket'
      # TODO @rsrc.id.must_equal '550e8400-e29b-41d4-a716-446655440000'
      # TODO @rsrc.name.must_equal 'Kitchen fruit basket'
    end
    
    it 'parse links' do
      @rsrc.links.baskets.must_be_instance_of HyperResource::Link
    end

    it 'parse objects' do
      @rsrc.fruits.must_be_instance_of Array
      @rsrc.objects.fruits.must_be_instance_of Array
    end

    it 'follows linked objects' do
      assert @rsrc.baskets.first.fruits.first.tastes.last
    end

    it 'allows setting attributes' do
      @rsrc.objects.baskets.first.id = :foo
      @rsrc.objects.baskets.first.id.must_equal :foo
    end
  end
end
