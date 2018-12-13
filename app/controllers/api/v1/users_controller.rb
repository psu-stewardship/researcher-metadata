module API::V1
  class UsersController < APIController
    include Swagger::Blocks
    include ActionController::MimeResponds

    def presentations
      user = User.find_by(webaccess_id: params[:webaccess_id])
      if user
        @presentations = API::V1::UserQuery.new(user).presentations(params)
        respond_to do |format|
          format.html
          format.json { render json: API::V1::PresentationSerializer.new(@presentations) }
        end
      else
        render json: { :message => "User not found", :code => 404 }, status: 404
      end
    end

    def contracts
      user = User.find_by(webaccess_id: params[:webaccess_id])
      if user
        @contracts = API::V1::UserQuery.new(user).contracts(params)
        respond_to do |format|
          format.html
          format.json { render json: API::V1::ContractSerializer.new(@contracts) }
        end
      else
        render json: { :message => "User not found", :code => 404 }, status: 404
      end
    end

    def news_feed_items
      user = User.find_by(webaccess_id: params[:webaccess_id])
      if user
        @news_feed_items = API::V1::UserQuery.new(user).news_feed_items(params)
        respond_to do |format|
          format.html
          format.json { render json: API::V1::NewsFeedItemSerializer.new(@news_feed_items) }
        end
      else
        render json: { :message => "User not found", :code => 404 }, status: 404
      end
    end

    def performances
      user = User.find_by(webaccess_id: params[:webaccess_id])
      if user
        @performances = API::V1::UserQuery.new(user).performances(params)
        respond_to do |format|
          format.html
          format.json { render json: API::V1::PerformanceSerializer.new(@performances) }
        end
      else
        render json: { :message => "User not found", :code => 404 }, status: 404
      end
    end

    def etds
      @user = User.find_by(webaccess_id: params[:webaccess_id])
      if @user
        @etds = API::V1::UserQuery.new(@user).etds(params)
        respond_to do |format|
          format.html
          format.json { render json: API::V1::ETDSerializer.new(@etds) }
        end
      else
        render json: { :message => "User not found", :code => 404 }, status: 404
      end
    end

    def publications
      user = User.find_by(webaccess_id: params[:webaccess_id])
      if user
        @pubs = API::V1::UserQuery.new(user).publications(params)
        respond_to do |format|
          format.html
          format.json { render json: API::V1::PublicationSerializer.new(@pubs) }
        end
      else
        render json: { :message => "User not found", :code => 404 }, status: 404
      end
    end

    def organization_memberships
      user = User.find_by(webaccess_id: params[:webaccess_id])
      if user
        @memberships = user.user_organization_memberships
        respond_to do |format|
          format.html
          format.json { render json: API::V1::OrganizationMembershipSerializer.new(@memberships) }
        end
      else
        render json: { :message => "User not found", :code => 404 }, status: 404
      end
    end

    def profile
      @user = User.find_by(webaccess_id: params[:webaccess_id])
      uq = API::V1::UserQuery.new(@user)
      if @user
        @pubs = uq.publications({order_first_by: 'publication_date_desc'})
        @grants = uq.contracts.where(status: 'Awarded', contract_type: 'Grant').order(award_start_on: :desc)
        @presentations = uq.presentations({})
        @news_feed_items = uq.news_feed_items({}).order(published_on: :desc)
        @committee_memberships = @user.committee_memberships
        @performances = @user.performances.order('case when start_on is null then 1 else 0 end, start_on desc')
      else
        render json: { :message => "User not found", :code => 404 }, status: 404
      end
    end

    def users_publications
      data = {}
      User.includes(:publications).where(webaccess_id: params[:_json]).each do |user|
        pubs = API::V1::UserQuery.new(user).publications(params)
        data[user.webaccess_id] = API::V1::PublicationSerializer.new(pubs).serializable_hash
      end
      render json: data
    end

    swagger_path '/v1/users/{webaccess_id}/organization_memberships' do
      operation :get do
        key :summary, "Retrieve the user's organization memberships"
        key :description, 'Returns organization memberships for a user'
        key :operationId, 'findUserOrganizationMemberships'
        key :produces, [
          'application/json'
        ]
        key :tags, [
          'user'
        ]
        parameter do
          key :name, :webaccess_id
          key :in, :path
          key :description, 'Webaccess ID of user to retrieve organization memberships'
          key :required, true
          key :type, :string
        end
        response 200 do
          key :description, 'user organization memberships response'
          schema do
            key :required, [:data]
            property :data do
              key :type, :array
              items do
                key :type, :object
                key :required, [:id, :type, :attributes]
                property :id do
                  key :type, :string
                  key :example, '123'
                  key :description, 'The ID of the object'
                end
                property :type do
                  key :type, :string
                  key :example, 'organization_membership'
                  key :description, 'The type of the object'
                end
                property :attributes do
                  key :type, :object
                  key :required, [:organization_name]
                  property :organization_name do
                    key :type, :string
                    key :example, 'Biology'
                    key :description, 'The name of the organization to which the user belongs'
                  end
                  property :organization_type do
                    key :type, [:string, :null]
                    key :example, 'Department'
                    key :description, 'The type of the organization'
                  end
                  property :position_title do
                    key :type, [:string, :null]
                    key :example, 'Associate Professor of Biology'
                    key :description, "The user's role or title within the organization"
                  end
                  property :position_started_on do
                    key :type, [:string, :null]
                    key :example, '2010-09-01'
                    key :description, 'The date on which the user joined the organization in this role'
                  end
                  property :position_ended_on do
                    key :type, [:string, :null]
                    key :example, '2012-05-30'
                    key :description, 'The date on which the user left the organization in this role'
                  end
                end
              end
            end
          end
        end
        # response 401 do
        #   key :description, 'unauthorized'
        #   schema do
        #     key :'$ref', :ErrorModelV1
        #   end
        # end
        response 404 do
          key :description, 'not found'
          schema do
            key :'$ref', :ErrorModelV1
          end
        end
        security do
          key :api_key, []
        end
      end
    end

    swagger_path '/v1/users/{webaccess_id}/news_feed_items' do
      operation :get do
        key :summary, "Retrieve a user's news feed items"
        key :description, 'Returns a news feed items for a user'
        key :operationId, 'findUserNewsFeedItems'
        key :produces, [
          'application/json',
          'text/html'
        ]
        key :tags, [
          'user'
        ]
        parameter do
          key :name, :webaccess_id
          key :in, :path
          key :description, 'Webaccess ID of user to retrieve news feed items'
          key :required, true
          key :type, :string
        end
         response 200 do
          key :description, 'user news_feed_items response'
          schema do
            key :required, [:data]
            property :data do
              key :type, :array
              items do
                key :type, :object
                key :required, [:id, :type, :attributes]
                property :id do
                  key :type, :string
                  key :example, '123'
                  key :description, 'The ID of the object'
                end
                property :type do
                  key :type, :string
                  key :example, 'news_feed_item'
                  key :description, 'The type of the object'
                end
                property :attributes do
                  key :type, :object
                  key :required, [:title, :url, :description, :published_on]
                  property :title do
                    key :type, :string
                    key :example, 'News Story'
                    key :description, 'The title of the news feed item'
                  end
                  property :url do
                    key :type, :string
                    key :example, 'https://news.psu.edu/example'
                    key :description, 'The URL where the full news story content can be found'
                  end
                  property :description do
                    key :type, :string
                    key :example, 'A news story about a Penn State researcher'
                    key :description, 'A brief description of the news story content'
                  end
                  property :published_on do
                    key :type, :string
                    key :example, '2018-12-05'
                    key :description, 'The date on which the news story was published'
                  end
                end
              end
            end
          end
         end
        # response 401 do
        #   key :description, 'unauthorized'
        #   schema do
        #     key :'$ref', :ErrorModelV1
        #   end
        # end
        response 404 do
          key :description, 'not found'
          schema do
            key :'$ref', :ErrorModelV1
          end
        end
        security do
          key :api_key, []
        end
      end
    end

    swagger_path '/v1/users/{webaccess_id}/presentations' do
      operation :get do
        key :summary, "Retrieve a user's presentations"
        key :description, 'Returns presentations for a user'
        key :operationId, 'findUserPresentations'
        key :produces, [
          'application/json',
          'text/html'
        ]
        key :tags, [
          'user'
        ]
        parameter do
          key :name, :webaccess_id
          key :in, :path
          key :description, 'Webaccess ID of user to retrieve presentations'
          key :required, true
          key :type, :string
        end

        response 200 do
          key :description, 'user presentations response'
          schema do
            key :required, [:data]
            property :data do
              key :type, :array
              items do
                key :type, :object
                key :required, [:id, :type, :attributes]
                property :id do
                  key :type, :string
                  key :example, '123'
                  key :description, 'The ID of the object'
                end
                property :type do
                  key :type, :string
                  key :example, 'presentation'
                  key :description, 'The type of the object'
                end
                property :attributes do
                  key :type, :object
                  key :required, [:activity_insight_identifier]
                  property :title do
                    key :type, [:string, :null]
                    key :example, 'A Public Presentation'
                    key :description, 'The title of the presentation'
                  end
                  property :activity_insight_identifier do
                    key :type, :string
                    key :example, '1234567890'
                    key :description, "The unique identifier for the presentation's corresponding record in the Activity Insight database"
                  end
                  property :name do
                    key :type, [:string, :null]
                    key :example, 'A Public Presentation'
                    key :description, 'The name of the presentation'
                  end
                  property :organization do
                    key :type, [:string, :null]
                    key :example, 'The Pennsylvania State University'
                    key :description, 'The name of the organization associated with the presentation'
                  end
                  property :location do
                    key :type, [:string, :null]
                    key :example, 'University Park, PA'
                    key :description, 'The name of the location where the presentation took place'
                  end
                  property :started_on do
                    key :type, [:string, :null]
                    key :example, '2018-12-04'
                    key :description, 'The date on which the presentation started'
                  end
                  property :ended_on do
                    key :type, [:string, :null]
                    key :example, '2018-12-05'
                    key :description, 'The date on which the presentation ended'
                  end
                  property :presentation_type do
                    key :type, [:string, :null]
                    key :example, 'Presentations'
                    key :description, 'The type of the presentation'
                  end
                  property :classification do
                    key :type, [:string, :null]
                    key :example, 'Basic or Discovery Scholarship'
                    key :description, 'The classification of the presentation'
                  end
                  property :meet_type do
                    key :type, [:string, :null]
                    key :example, 'Academic'
                    key :description, 'The meet type of the presentation'
                  end
                  property :attendance do
                    key :type, [:integer, :null]
                    key :example, 200
                    key :description, 'The number of people who attended the presentation'
                  end
                  property :refereed do
                    key :type, [:string, :null]
                    key :example, 'Yes'
                    key :description, 'Whether or not the presentation was refereed'
                  end
                  property :abstract do
                    key :type, [:string, :null]
                    key :example, 'A presentation about Penn State academic research'
                    key :description, 'A summary of the presentation content'
                  end
                  property :comment do
                    key :type, [:string, :null]
                    key :example, 'The goal of this presentation was to broaden public awareness of a research topic.'
                    key :description, 'Miscellaneous comments and notes about the presentation'
                  end
                  property :scope do
                    key :type, [:string, :null]
                    key :example, 'International'
                    key :description, 'The scope of the audience for the presentation'
                  end
                end
              end
            end
          end
        end
        # response 401 do
        #   key :description, 'unauthorized'
        #   schema do
        #     key :'$ref', :ErrorModelV1
        #   end
        # end
        response 404 do
          key :description, 'not found'
          schema do
            key :'$ref', :ErrorModelV1
          end
        end
        security do
          key :api_key, []
        end
      end
    end

    swagger_path '/v1/users/{webaccess_id}/contracts' do
      operation :get do
        key :summary, "Retrieve a user's contracts"
        key :description, 'Returns a contracts for a user'
        key :operationId, 'findUserContracts'
        key :produces, [
          'application/json',
          'text/html'
        ]
        key :tags, [
          'user'
        ]
        parameter do
          key :name, :webaccess_id
          key :in, :path
          key :description, 'Webaccess ID of user to retrieve contracts'
          key :required, true
          key :type, :string
        end

        response 200 do
          key :description, 'user contracts response'
          schema do
            key :required, [:data]
            property :data do
              key :type, :array
              items do
                key :type, :object
                key :required, [:id, :type, :attributes]
                property :id do
                  key :type, :string
                  key :example, '123'
                  key :description, 'The ID of the object'
                end
                property :type do
                  key :type, :string
                  key :example, 'contract'
                  key :description, 'The type of the object'
                end
                property :attributes do
                  key :type, :object
                  key :required, [:title, :sponsor, :status, :amount, :ospkey]
                  property :title do
                    key :type, :string
                    key :example, 'A Research Project Proposal'
                    key :description, 'The title of the contract'
                  end
                  property :contract_type do
                    key :type, [:string, :null]
                    key :example, 'Grant'
                    key :description, 'The type of the contract'
                  end
                  property :sponsor do
                    key :type, :string
                    key :example, 'National Science Foundation'
                    key :description, 'The name of the organization sponsoring the contract'
                  end
                  property :status do
                    key :type, :string
                    key :example, 'Awarded'
                    key :description, 'The status of the contract'
                  end
                  property :amount do
                    key :type, :integer
                    key :example, 50000
                    key :description, 'The monetary amount of the contract in U.S. dollars'
                  end
                  property :ospkey do
                    key :type, :string
                    key :example, 123456
                    key :description, 'The OSP key of the contract'
                  end
                  property :award_start_on do
                    key :type, [:string, :null]
                    key :example, '2017-12-05'
                    key :description, 'The date on which the contract award starts'
                  end
                  property :award_end_on do
                    key :type, [:string, :null]
                    key :example, '2019-12-05'
                    key :description, 'The date on which the contract award ends'
                  end
                end
              end
            end
          end
        end
        # response 401 do
        #   key :description, 'unauthorized'
        #   schema do
        #     key :'$ref', :ErrorModelV1
        #   end
        # end
        response 404 do
          key :description, 'not found'
          schema do
            key :'$ref', :ErrorModelV1
          end
        end
        security do
          key :api_key, []
        end
      end
    end

    swagger_path '/v1/users/{webaccess_id}/performances' do
      operation :get do
        key :summary, "Retrieve a user's performances"
        key :description, 'Returns performances for a user'
        key :operationId, 'findPerformances'
        key :produces, [
          'application/json',
          'text/html'
        ]
        key :tags, [
          'user'
        ]
        parameter do
          key :name, :webaccess_id
          key :in, :path
          key :description, 'Webaccess ID of user to retrieve performancess'
          key :required, true
          key :type, :string
        end
         response 200 do
          key :description, 'user performances response'
          schema do
            key :required, [:data]
            property :data do
              key :type, :array
              items do
                key :type, :object
                key :required, [:id, :type, :attributes]
                property :id do
                  key :type, :string
                  key :example, '123'
                  key :description, 'The ID of the object'
                end
                property :type do
                  key :type, :string
                  key :example, 'performance'
                  key :description, 'The type of the object'
                end
                property :attributes do
                  key :type, :object
                  key :required, [:title, :activity_insight_id]
                  property :title do
                    key :type, :string
                    key :example, 'Example Performance'
                    key :description, 'The title of the performance'
                  end
                  property :activity_insight_id do
                    key :type, :integer
                    key :example, '1234567890'
                    key :description, "The unique identifier for the performances's corresponding record in the Activity Insight database"
                  end
                  property :performance_type do
                    key :type, [:string, :null]
                    key :example, 'Film - Documentary'
                    key :description, 'The type of performance'
                  end
                  property :sponsor do
                    key :type, [:string, :null]
                    key :example, 'Penn State'
                    key :description, 'The the organization that is sponsoring this performance'
                  end
                  property :description do
                    key :type, [:string, :null]
                    key :example, 'This is a unique performance, performed for specific reasons'
                    key :description, 'Any further detail describing the performance'
                  end
                  property :group_name do
                    key :type, [:string, :null]
                    key :example, 'Penn State Performers'
                    key :description, 'The name of the performing group'
                  end
                  property :location do
                    key :type, [:string, :null]
                    key :example, 'State College, PA'
                    key :description, 'Country, State, City, theatre, etc. that the performance took place'
                  end
                  property :delivery_type do
                    key :type, [:string, :null]
                    key :example, 'Competition'
                    key :description, 'Audition, commission, competition, or invitation'
                  end
                  property :scope do
                    key :type, [:string, :null]
                    key :example, 'Local'
                    key :description, 'International, national, regional, state, local'
                  end
                  property :start_on do
                    key :type, [:string, :null]
                    key :example, '12-01-2015'
                    key :description, 'The date that the performance started on'
                  end
                  property :end_on do
                    key :type, [:string, :null]
                    key :example, '12-31-2015'
                    key :description, 'The date that the performance ended on'
                  end
                  property :user_performances do
                    key :type, :array
                    items do
                      key :type, :object
                      property :first_name do
                        key :type, [:string, :null]
                        key :example, 'Billy'
                        key :description, 'The first name of a contributor'
                      end
                      property :last_name do
                        key :type, [:string, :null]
                        key :example, 'Bob'
                        key :description, 'The last name of a contributor'
                      end
                      property :contribution do
                        key :type, [:string, :null]
                        key :example, 'Performer'
                        key :description, 'The contributors role/contribution to the performance'
                      end
                      property :student_level do
                        key :type, [:string, :null]
                        key :example, 'Graduate'
                        key :description, 'Undergraduate or graduate'
                      end
                      property :role_other do
                        key :type, [:string, :null]
                        key :example, 'Director'
                        key :description, 'Role not listed in "contribution" drop-down'
                      end
                    end
                  end
                  property :performance_screenings do
                    key :type, :array
                    items do
                      key :type, :object
                      property :name do
                        key :type, [:string, :null]
                        key :example, 'Film Festival'
                        key :description, 'Name of the venue for the screening'
                      end
                      property :location do
                        key :type, [:string, :null]
                        key :example, 'State College, PA'
                        key :description, 'Country, State, City, that the screening took place'
                      end
                      property :screening_type do
                        key :type, [:string, :null]
                        key :example, 'DVD Distribution'
                        key :description, 'Type of screening/exhibition'
                      end
                    end
                  end
                end
              end
            end
          end
         end
        # response 401 do
        #   key :description, 'unauthorized'
        #   schema do
        #     key :'$ref', :ErrorModelV1
        #   end
        # end
        response 404 do
          key :description, 'not found'
          schema do
            key :'$ref', :ErrorModelV1
          end
        end
        security do
          key :api_key, []
        end
      end
    end

    swagger_path '/v1/users/{webaccess_id}/etds' do
      operation :get do
        key :summary, "Retrieve a user's student advising history"
        key :description, 'Returns ETDs for which the user served on the committee'
        key :operationId, 'findUserETDs'
        key :produces, [
          'application/json',
          'text/html'
        ]
        key :tags, [
          'user'
        ]
        parameter do
          key :name, :webaccess_id
          key :in, :path
          key :description, 'Webaccess ID of user to retrieve ETDs'
          key :required, true
          key :type, :string
        end

        response 200 do
          key :description, 'user ETDs response'
          schema do
            key :required, [:data]
            property :data do
              key :type, :array
              items do
                key :type, :object
                key :required, [:id, :type, :attributes]
                property :id do
                  key :type, :string
                  key :example, '123'
                  key :description, 'The ID of the object'
                end
                property :type do
                  key :type, :string
                  key :example, 'etd'
                  key :description, 'The type of the object'
                end
                property :attributes do
                  key :type, :object
                  key :required, [:title, :year, :author_last_name, :author_first_name]
                  property :title do
                    key :type, :string
                    key :example, 'A PhD Thesis'
                    key :description, 'The title of the ETD'
                  end
                  property :year do
                    key :type, :integer
                    key :example, '2010'
                    key :description, 'The year in which the ETD was completed'
                  end
                  property :author_last_name do
                    key :type, :string
                    key :example, 'Author'
                    key :description, "The last name of the ETD's author"
                  end
                  property :author_first_name do
                    key :type, :string
                    key :example, 'Susan'
                    key :description, "The first name of the ETD's author"
                  end
                  property :author_middle_name do
                    key :type, [:string, :null]
                    key :example, 'Example'
                    key :description, "The first name of the ETD's author"
                  end
                end
              end
            end
          end
        end
        # response 401 do
        #   key :description, 'unauthorized'
        #   schema do
        #     key :'$ref', :ErrorModelV1
        #   end
        # end
        response 404 do
          key :description, 'not found'
          schema do
            key :'$ref', :ErrorModelV1
          end
        end
        security do
          key :api_key, []
        end
      end
    end

    swagger_path '/v1/users/{webaccess_id}/publications' do
      operation :get do
        key :summary, "Retrieve a user's publications"
        key :description, 'Returns a publications for a user'
        key :operationId, 'findUserPublications'
        key :produces, [
          'application/json',
          'text/html'
        ]
        key :tags, [
          'user'
        ]
        parameter do
          key :name, :webaccess_id
          key :in, :path
          key :description, 'Webaccess ID of user to retrieve publications'
          key :required, true
          key :type, :string
        end
        parameter do
          key :name, :start_year
          key :in, :query
          key :description, 'Beginning of publication year range'
          key :required, false
          key :type, :integer
          key :format, :int32
        end
        parameter do
          key :name, :end_year
          key :in, :query
          key :description, 'End of publication year range'
          key :required, false
          key :type, :integer
          key :format, :int32
        end
        parameter do
          key :name, :order_first_by
          key :in, :query
          key :description, 'Orders publications returned'
          key :required, false
          key :type, :string
          key :enum, [
            :citation_count_desc,
            :publication_date_asc,
            :publication_date_desc,
            :title_asc
          ]
        end
        parameter do
          key :name, :order_second_by
          key :in, :query
          key :description, 'Orders publications returned'
          key :required, false
          key :type, :string
          key :enum, [
            :citation_count_desc,
            :publication_date_asc,
            :publication_date_desc,
            :title_asc
          ]
        end
        parameter do
          key :name, :limit
          key :in, :query
          key :description, 'Max number publications to return for the user'
          key :required, false
          key :type, :integer
          key :format, :int32
        end
        response 200 do
          key :description, 'user publications response'
          schema do
            key :required, [:data]
            property :data do
              key :type, :array
              items do
                key :'$ref', :PublicationV1
              end
            end
          end
        end
        # response 401 do
        #   key :description, 'unauthorized'
        #   schema do
        #     key :'$ref', :ErrorModelV1
        #   end
        # end
        response 404 do
          key :description, 'not found'
          schema do
            key :'$ref', :ErrorModelV1
          end
        end
        security do
          key :api_key, []
        end
      end
    end

    swagger_path '/v1/users/{webaccess_id}/profile' do
      operation :get do
        key :summary, "Retrieve a user's profile"
        key :description, "Returns a plain HTML representation of a user's profile information"
        key :operationId, 'findUserProfile'
        key :produces, ['text/html']
        key :tags, ['user']

        parameter do
          key :name, :webaccess_id
          key :in, :path
          key :description, 'Webaccess ID of user to retrieve HTML profile'
          key :required, true
          key :type, :string
        end

        response 200 do
          key :description, 'user profile response'
        end

        response 404 do
          key :description, 'not found'
          schema do
            key :'$ref', :ErrorModelV1
          end
        end
      end
    end

    swagger_path '/v1/users/publications' do
      operation :post do
        key :summary, "Retrieve publications for a group of users"
        key :description, 'Returns publications for a group of users'
        key :operationId, 'findUsersPublications'
        key :tags, [
          'user'
        ]
        parameter do
          key :name, :start_year
          key :in, :query
          key :description, 'Beginning of publication year range'
          key :required, false
          key :type, :integer
          key :format, :int32
        end
        parameter do
          key :name, :end_year
          key :in, :query
          key :description, 'End of publication year range'
          key :required, false
          key :type, :integer
          key :format, :int32
        end
        parameter do
          key :name, :order_first_by
          key :in, :query
          key :description, 'Orders publications returned'
          key :required, false
          key :type, :string
          key :enum, [
            :citation_count_desc,
            :publication_date_asc,
            :publication_date_desc,
            :title_asc
          ]
        end
        parameter do
          key :name, :order_second_by
          key :in, :query
          key :description, 'Orders publications returned'
          key :required, false
          key :type, :string
          key :enum, [
            :citation_count_desc,
            :publication_date_asc,
            :publication_date_desc,
            :title_asc
          ]
        end
        parameter do
          key :name, :limit
          key :in, :query
          key :description, 'Max number publications to return for each user'
          key :required, false
          key :type, :integer
          key :format, :int32
        end
        parameter do
          key :in, 'body'
          key :description, 'Webaccess IDs of users to retrieve publications'
          key :required, true
          key :name, :webaccess_ids
          schema do
            key :type, :array
            items do
              key :type, :string
            end
          end
        end
        response 200 do
          key :description, 'OK'
        end
        # response 401 do
        #   key :description, 'unauthorized'
        #   schema do
        #     key :'$ref', :ErrorModelV1
        #   end
        # end
        security do
          key :api_key, []
        end
      end
    end
  end
end
