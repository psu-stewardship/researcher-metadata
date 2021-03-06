module API::V1
  class GrantSerializer
    include FastJsonapi::ObjectSerializer
    attributes :title, :agency, :abstract, :amount_in_dollars

    attribute :start_date do |object|
      object.start_date.try(:iso8601)
    end

    attribute :end_date do |object|
      object.end_date.try(:iso8601)
    end

    attribute :identifier do |object|
      object.identifier.presence || object.wos_identifier.presence
    end
  end
end