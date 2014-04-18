require 'minitest/autorun'
require 'minitest/pride'
require 'mocha/setup'

require 'hyper_resource'

HAL_BODY = {
  'attr1' => 'val1',
  'attr2' => 'val2',
  '_links' => {
    'curies' => [
      { 'name' => 'foo', 
        'templated' => true, 
        'href' => 'http://example.com/api/rels/{rel}' }
    ],
    'self' => {'href' => '/obj1/'},
    'foo:foobars' => [
      { 'name' => 'foobar',
        'templated' => true,
        'href' => 'http://example.com/foobars/{foobar}'
      }
    ]
  },
  '_embedded' => {
    'obj1s' => [
      { 'attr3' => 'val3',
        'attr4' => 'val4',
        '_links' => {
          'self' => {'href' => '/obj1/1'},
          'next' => {'href' => '/obj1/2'}
        }
      },
      { 'attr3' => 'val5',
        'attr4' => 'val6',
        '_links' => {
          'self' => {'href' => '/obj1/2'},
          'previous' => {'href' => '/obj1/1'}
        }
      }
    ]
  }
}

JSON_API_BODY = {
  "baskets" => [{
    "id" => "550e8400-e29b-41d4-a716-446655440000",
    "name" => "Kitchen fruit basket",
    "status" => "half-full",
    "links" => {
      "fruits" => [5, 6, 7]
    }
  }],
  "links" => {
    "baskets" => { "href" => "/baskets" },
    "baskets.consumers" => { "href" => "/baskets/{baskets.id}/consumers" },
    "baskets.refills" => "/baskets/{baskets.id}/refills",
  },
  "linked" => {
    "fruits" => [
      { 
        "id" => 5, "name" => "Banana", 
        "kind" => "Musaceae", "season" => "all year",
        "links" => { "tastes" => [1, 2, 3] }
      },
      { 
        "id" => 6, "name" => "Apple",
        "kind" => "Rosaceae", "season" => "winter & spring",
        "links" => { "tastes" => [2] }
      },
      {
        "id" => 7, "name" => "Orange", 
         "kind" => "Citrus", "season" => "winter",
        "links" => { "tastes" => [2] }
      },
    ],
    "tastes" => [
      { "id" => 1, "name" => "soft" },
      { "id" => 2, "name" => "sweet" },
      { "id" => 3, "name" => "melting" }
    ]
  },
  "meta" => { "client-ids" => true }
}

