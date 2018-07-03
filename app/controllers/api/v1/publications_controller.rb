module API::V1
  class PublicationsController < APIController
    include Swagger::Blocks

    def index
      render json: API::V1::PublicationSerializer.new(Publication.limit(100))
    end

    def show
      @publication = Publication.find(params[:id])
      render json: API::V1::PublicationSerializer.new(@publication).serializable_hash
    end

    swagger_path '/v1/publications/{id}' do
      operation :get do
        key :summary, 'Find Publication by ID'
        key :description, 'Returns a single publication if the user has access'
        key :operationId, 'findPublicationById'
        key :tags, [
          'publication'
        ]
        parameter do
          key :name, :id
          key :in, :path
          key :description, 'ID of publication to fetch'
          key :required, true
          key :type, :integer
          key :format, :int64
        end
        response 200 do
          key :description, 'publication response'
          schema do
            key :'$ref', :Publication
          end
        end
        response 404 do
          key :description, 'not found'
          schema do
            key :'$ref', :Publication
            key :required, [:code, :message]
            property :code do
              key :type, :integer
              key :format, :int32
            end
            property :message do
              key :type, :string
            end
          end
        end
      end
    end

    swagger_path '/v1/publications' do
      operation :get do
        key :summary, 'All Publications'
        key :description, 'Returns all publications from the system that the user has access to'
        key :operationId, 'findPublications'
        key :produces, [
          'application/json',
          'text/html',
        ]
        key :tags, [
          'publications'
        ]
        response 200 do
          key :description, 'publication response'
          schema do
            key :type, :object
            items do
              key :'$ref', :Publication
            end
          end
        end
      end
    end
  end
end